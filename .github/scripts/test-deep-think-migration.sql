-- Integration test for the Deep Think migration using a disposable PostgreSQL database.
\set ON_ERROR_STOP on
begin;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
select public.submit_deep_think_case(
  'Should I accept the new role?',
  'Current job is stable',
  'Career growth',
  'Accept or decline',
  'Family commitments',
  'Relocation risk',
  'CI integration test'
);
reset role;
do $$
declare v_case_id uuid;
begin
  select id into v_case_id from public.deep_think_cases
  where title = 'Should I accept the new role?'
    and user_id = '10000000-0000-4000-8000-000000000001'
  order by created_at desc limit 1;
  if v_case_id is null then
    raise exception 'Submission did not create an owned case';
  end if;
  if not exists (select 1 from public.deep_think_cases where id=v_case_id and status='submitted') then
    raise exception 'New case must start in submitted status';
  end if;
  if not exists (select 1 from public.deep_think_case_events where case_id=v_case_id and event_type='submitted') then
    raise exception 'Submission audit event missing';
  end if;
end $$;
rollback;
