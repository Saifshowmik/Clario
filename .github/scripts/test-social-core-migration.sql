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
end $$;
