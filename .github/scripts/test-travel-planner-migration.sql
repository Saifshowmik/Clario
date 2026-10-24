-- Disposable PostgreSQL integration test for private travel drafts.
begin;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
insert into public.travel_trips(user_id,title,origin,destination,travel_style,group_size,budget_amount)
values(auth.uid(),'CI privacy trip','Dhaka','Sylhet','duo',2,5000);
do $test$
begin
 if (select count(*) from public.travel_trips where title='CI privacy trip') <> 1 then
   raise exception 'Owner cannot read own travel trip';
 end if;
end
$test$;
reset role;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local role authenticated;
do $test$
begin
 if (select count(*) from public.travel_trips where title='CI privacy trip') <> 0 then
   raise exception 'Another user can read a private travel trip';
 end if;
end
$test$;
delete from public.travel_trips where title='CI privacy trip';
reset role;
rollback;
