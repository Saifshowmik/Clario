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
