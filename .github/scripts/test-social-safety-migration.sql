\set ON_ERROR_STOP on
do $$
begin
  if to_regclass('public.social_mutes') is null or to_regclass('public.social_reports') is null then
    raise exception 'Social safety tables missing';
  end if;
  if not (select relrowsecurity from pg_class where oid='public.social_reports'::regclass) then
    raise exception 'RLS is not enabled for social reports';
  end if;
  if not exists(select 1 from pg_policies where policyname='social_reports_insert_own') then
    raise exception 'Report ownership policy missing';
  end if;
  if not exists(select 1 from pg_proc where proname='block_social_member') then
    raise exception 'Block RPC missing';
  end if;
  if not exists(select 1 from pg_proc where proname='mute_social_member') then
    raise exception 'Mute RPC missing';
  end if;
  if not exists(select 1 from pg_proc where proname='resolve_social_username') then
    raise exception 'Private-safe username resolution RPC missing';
  end if;
  if has_table_privilege('authenticated','public.social_reports','UPDATE') then
    raise exception 'Clients must not be able to update moderation reports';
  end if;
end $$;

-- Exercise block, mute, and report actions with authenticated identities.
update public.profiles set username='safety_owner', profile_visibility='public'
where id='10000000-0000-4000-8000-000000000002';
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
set role authenticated;
select public.block_social_member('safety_owner');
reset role;
do $$
begin
  if not exists(select 1 from public.social_blocks
    where blocker_id='10000000-0000-4000-8000-000000000001'
      and blocked_id='10000000-0000-4000-8000-000000000002') then
    raise exception 'Block RPC did not create the expected block';
  end if;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
set role authenticated;
select public.mute_social_member('safety_owner');
insert into public.social_reports(reporter_id,reported_user_id,reason,details)
values ('10000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000002','spam','CI safety test');
reset role;
do $$
begin
  if not exists(select 1 from public.social_mutes
    where muter_id='10000000-0000-4000-8000-000000000003'
      and muted_id='10000000-0000-4000-8000-000000000002') then
    raise exception 'Mute RPC did not create the expected mute';
  end if;
  if not exists(select 1 from public.social_reports
    where reporter_id='10000000-0000-4000-8000-000000000003'
      and reported_user_id='10000000-0000-4000-8000-000000000002'
      and reason='spam') then
    raise exception 'Report insertion did not persist';
  end if;
end $$;
