-- Integration test for the Deep Think migration using a disposable PostgreSQL database.
\set ON_ERROR_STOP on
begin;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
select public.submit_deep_think_case(
  'Should I accept the new role?',
  'Current job is stable',
  'Career growth',
  'Accept or decline',
  'Family commitments',
  'Relocation risk',
  'CI integration test'
) as case_id \gset
reset role;
do $$
begin
  if not exists (
    select 1 from public.deep_think_cases
    where id = :'case_id'::uuid
      and user_id = '10000000-0000-4000-8000-000000000001'
      and status = 'submitted'
  ) then
    raise exception 'Submission did not create an owned submitted case';
  end if;
  if not exists (
    select 1 from public.deep_think_case_events
    where case_id = :'case_id'::uuid and event_type = 'submitted'
  ) then
    raise exception 'Submission audit event missing';
  end if;
end $$;
rollback;
