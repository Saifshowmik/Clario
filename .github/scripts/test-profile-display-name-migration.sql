-- Profile display-name migration integration checks.
\set ON_ERROR_STOP on
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
set role authenticated;
update public.profiles set display_name='Clario Test Member' where id='10000000-0000-4000-8000-000000000001';
do $$
begin
  if not exists(select 1 from public.profiles where id='10000000-0000-4000-8000-000000000001' and display_name='Clario Test Member') then
    raise exception 'Display name could not be saved';
  end if;
  begin
    update public.profiles set display_name=repeat('x',81) where id='10000000-0000-4000-8000-000000000001';
    raise exception 'Oversized display name unexpectedly succeeded';
  exception when others then
    if sqlerrm='Oversized display name unexpectedly succeeded' then raise; end if;
    if position('Display name must be 80 characters or fewer' in sqlerrm)=0 then raise; end if;
  end;
end $$;
reset role;
