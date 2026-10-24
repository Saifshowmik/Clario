-- Validate profile fields, username normalization, and self-service privilege protection.
\set ON_ERROR_STOP on
begin;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
update public.profiles
set username = 'Saif_Test', bio = 'Profile test', interests = array['tech','travel'],
    profile_visibility = 'private'
where id = auth.uid();
reset role;
do $$
begin
  if not exists (select 1 from public.profiles where id='10000000-0000-4000-8000-000000000001'
      and username='saif_test' and bio='Profile test' and cardinality(interests)=2) then
    raise exception 'Profile fields did not persist or username was not normalized';
  end if;
end $$;
-- A normal authenticated user must not grant themselves owner privileges.
set local role authenticated;
do $$
begin
  begin
    update public.profiles set role='owner'
    where id='10000000-0000-4000-8000-000000000001';
    raise exception 'Self-promotion to owner unexpectedly succeeded';
  exception when others then
    if sqlerrm = 'Self-promotion to owner unexpectedly succeeded' then raise; end if;
    if position('Role and plan changes' in sqlerrm) = 0 then raise; end if;
  end;
  begin
    update public.profiles set plan='extra_premium'
    where id='10000000-0000-4000-8000-000000000001';
    raise exception 'Self-upgrade to paid plan unexpectedly succeeded';
  exception when others then
    if sqlerrm = 'Self-upgrade to paid plan unexpectedly succeeded' then raise; end if;
    if position('Role and plan changes' in sqlerrm) = 0 then raise; end if;
  end;
end $$;
reset role;
rollback;
