\set ON_ERROR_STOP on
do $$
declare
  required_table text;
  required_policy text;
begin
  foreach required_table in array array['social_follows','social_blocks','social_posts','social_comments','social_reactions','social_stories'] loop
    if to_regclass('public.' || required_table) is null then
      raise exception 'Missing social table: %', required_table;
    end if;
    if not (select relrowsecurity from pg_class where oid=to_regclass('public.' || required_table)) then
      raise exception 'RLS is not enabled on %', required_table;
    end if;
  end loop;
  foreach required_policy in array array['social_posts_read_audience','social_follows_request_own','social_blocks_insert_own','social_stories_read_active_audience','profiles_social_read'] loop
    if not exists(select 1 from pg_policies where policyname=required_policy) then
      raise exception 'Missing social security policy: %', required_policy;
    end if;
  end loop;
  if not exists(select 1 from pg_trigger where tgname='clario_guard_follow_identity' and not tgisinternal) then
    raise exception 'Follow identity guard trigger missing';
  end if;
  if not exists(select 1 from pg_proc where proname='request_social_follow') then
    raise exception 'Secure follow request RPC missing';
  end if;
end $$;

-- Exercise the security-definer RPC for a private target without exposing their profile row.
update public.profiles set username='requester_01', profile_visibility='private'
where id='10000000-0000-4000-8000-000000000001';
update public.profiles set username='private_target', profile_visibility='private'
where id='10000000-0000-4000-8000-000000000003';
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
set role authenticated;
select public.request_social_follow('private_target');
reset role;
do $$
begin
  if not exists(select 1 from public.social_follows
    where requester_id='10000000-0000-4000-8000-000000000001'
      and target_id='10000000-0000-4000-8000-000000000003' and status='pending') then
    raise exception 'Private-profile follow request was not created';
  end if;
end $$;

-- A block in either direction must stop a follow request.
insert into public.social_blocks(blocker_id,blocked_id)
values ('10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000003');
do $$
begin
  perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
  begin
    perform public.request_social_follow('private_target');
    raise exception 'Blocked follow request unexpectedly succeeded';
  exception when others then
    if sqlerrm = 'Blocked follow request unexpectedly succeeded' then raise; end if;
    if sqlerrm = 'Follow request unavailable' then null; else raise; end if;
  end;
end $$;
