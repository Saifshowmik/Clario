\set ON_ERROR_STOP on
begin;
-- Adult user creates one saved and one temporary session.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
select public.clario_mind_save_session('18_plus','en','saved','anxious',array['calm'],'test saved session') as saved_id \gset
select public.clario_mind_save_session('18_plus','bn','temporary','okay',array['reflect'],'temporary session') as temporary_id \gset
-- A minor must be rejected by the server even if the client is bypassed.
do $$ begin
  begin
    perform public.clario_mind_save_session('16_17','en','saved','low',array[]::text[],'minor test');
    raise exception 'Minor session unexpectedly accepted';
  exception when others then
    if sqlerrm = 'Minor session unexpectedly accepted' then raise; end if;
    if position('minors are disabled' in sqlerrm)=0 then raise; end if;
  end;
end $$;
-- Saved history should only contain the saved record, never temporary records.
select count(*) as saved_count from public.clario_mind_list_sessions() \gset
\if :saved_count != 1
  \echo 'Expected exactly one saved session'
  \quit 1
\endif
reset role;
-- Verify temporary record has expiry and saved record does not.
do $$ begin
 if not exists(select 1 from public.mind_sessions where id=:'saved_id'::uuid and expires_at is null) then
   raise exception 'Saved session expiry must be null';
 end if;
 if not exists(select 1 from public.mind_sessions where id=:'temporary_id'::uuid and expires_at>now()) then
   raise exception 'Temporary session must expire in the future';
 end if;
end $$;
-- Other user cannot list the first user's saved history.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local role authenticated;
select count(*) as other_count from public.clario_mind_list_sessions() \gset
\if :other_count != 0
  \echo 'Other user can see saved history'
  \quit 1
\endif
rollback;
