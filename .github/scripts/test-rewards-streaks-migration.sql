-- Disposable PostgreSQL integration tests for referrals, paid rewards, streaks, and entitlements.
begin;
-- Create a code for user 3, then apply it to user 1 before payment.
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local role authenticated;
select public.clario_ensure_referral_code() as ref_code \gset
reset role;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
select public.clario_apply_referral(:'ref_code');
reset role;
-- A qualifying paid payment must change the referral state and award only policy-configured rewards.
insert into public.payments(user_id,plan,period,method,trx_id,status)
values('10000000-0000-4000-8000-000000000001','pro','weekly','bkash','CI-REFERRAL-0001','pending');
update public.payments set status='approved',reason='CI verified payment' where trx_id='CI-REFERRAL-0001';
do $test$
begin
 if not exists(select 1 from public.referrals where referred_id='10000000-0000-4000-8000-000000000001' and status='qualified') then
  raise exception 'Paid payment did not qualify referral';
 end if;
 if exists(select 1 from public.reward_ledger where source_payment_id=(select id from public.payments where trx_id='CI-REFERRAL-0001')) then
  raise exception 'Default-zero reward policy unexpectedly issued reward';
 end if;
end
$test$;
-- Five saved decisions on the Dhaka calendar day must qualify today.
insert into public.decisions(user_id,best,score,created_at)
select '10000000-0000-4000-8000-000000000001','CI streak decision',1,
       ((now() at time zone 'Asia/Dhaka')::date::timestamp + interval '12 hours') at time zone 'Asia/Dhaka'
from generate_series(1,5);
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
select public.clario_refresh_streak() as streak \gset
reset role;
do $test$
begin
 if not exists(select 1 from public.streak_daily where user_id='10000000-0000-4000-8000-000000000001' and local_day=(now() at time zone 'Asia/Dhaka')::date and qualifies and completed_decisions>=5) then
  raise exception 'Five decisions did not qualify the streak day';
 end if;
 if public.clario_effective_plan('10000000-0000-4000-8000-000000000001') <> 'free' then
  raise exception 'User plan changed without a valid earned entitlement';
 end if;
end
$test$;
rollback;
