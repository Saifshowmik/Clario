\set ON_ERROR_STOP on
begin;
-- Adult user creates one saved session.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
select public.clario_mind_save_session('18_plus','en','saved','anxious',array['calm'],'test saved session') as saved_id \gset
-- Minors and temporary database persistence must be rejected server-side.
do $test$
begin
  begin
    perform public.clario_mind_save_session('16_17','en','saved','low',array[]::text[],'minor test');
    raise exception 'Minor session unexpectedly accepted';
  exception when others then
    if sqlerrm = 'Minor session unexpectedly accepted' then raise; end if;
    if position('minors are disabled' in sqlerrm)=0 then raise; end if;
  end;
  begin
    perform public.clario_mind_save_session('18_plus','en','temporary','okay',array[]::text[],'temporary test');
    raise exception 'Temporary session unexpectedly stored';
  exception when others then
    if sqlerrm = 'Temporary session unexpectedly stored' then raise; end if;
    if position('client-only' in sqlerrm)=0 then raise; end if;
  end;
end
$test$;
-- Saved history should contain exactly the user's saved session.
select (count(*) = 1) as saved_ok from public.clario_mind_list_sessions() \gset
\if :saved_ok
\else
  \echo 'Expected exactly one saved session'
  \quit 1
\endif
-- Saved sessions have no expiry; temporary reflections are never persisted.
do $test$
begin
 if not exists(select 1 from public.mind_sessions where user_id='10000000-0000-4000-8000-000000000001' and note='test saved session' and expires_at is null) then
   raise exception 'Saved session expiry must be null';
 end if;
 if exists(select 1 from public.mind_sessions where user_id='10000000-0000-4000-8000-000000000001' and note='temporary test') then
   raise exception 'Temporary reflection must not be persisted';
 end if;
end
$test$;
-- A different authenticated user cannot delete the owner's session.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local role authenticated;
delete from public.mind_sessions where note='test saved session';
reset role;
do $test$
begin
 if not exists(select 1 from public.mind_sessions where user_id='10000000-0000-4000-8000-000000000001' and note='test saved session') then
   raise exception 'Other user deleted a session belonging to another user';
 end if;
end
$test$;
-- User can delete their own saved session.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
delete from public.mind_sessions where note='test saved session';
reset role;
do $test$
begin
 if exists(select 1 from public.mind_sessions where user_id='10000000-0000-4000-8000-000000000001' and note='test saved session') then
   raise exception 'User could not delete own saved session';
 end if;
end
$test$;
-- Other user cannot list the first user's saved history.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local role authenticated;
select (count(*) = 0) as other_ok from public.clario_mind_list_sessions() \gset
\if :other_ok
\else
  \echo 'Other user can see saved history'
  \quit 1
\endif
rollback;
