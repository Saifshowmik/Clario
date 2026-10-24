-- Server-verified streak qualification in Bangladesh local time.
-- A qualifying day requires >=5 saved decisions; logins do not count.
create table if not exists public.streak_daily (
 user_id uuid not null references public.profiles(id) on delete cascade,
 local_day date not null,
 completed_decisions integer not null default 0 check(completed_decisions>=0),
 qualifies boolean not null default false,
 checked_at timestamptz not null default now(),
 primary key(user_id,local_day)
);
create table if not exists public.streak_milestones (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 milestone_days integer not null check(milestone_days=60 or (milestone_days>=365 and milestone_days%365=0)),
 achieved_on date not null,
 reward_code text not null check(reward_code in ('pro_7_days','extra_premium_1_day')),
 created_at timestamptz not null default now(),
 unique(user_id,milestone_days)
);
alter table public.streak_daily enable row level security;
alter table public.streak_milestones enable row level security;
drop policy if exists streak_daily_read_own on public.streak_daily;
create policy streak_daily_read_own on public.streak_daily for select to authenticated using(user_id=auth.uid());
drop policy if exists streak_milestones_read_own on public.streak_milestones;
create policy streak_milestones_read_own on public.streak_milestones for select to authenticated using(user_id=auth.uid());
revoke all on public.streak_daily,public.streak_milestones from anon,authenticated;
grant select on public.streak_daily,public.streak_milestones to authenticated;

create or replace function public.clario_refresh_streak()
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
 v_uid uuid:=auth.uid();
 v_today date:=(now() at time zone 'Asia/Dhaka')::date;
 v_day date;
 v_count integer;
 v_qualifies boolean;
 v_current integer:=0;
 v_best integer:=0;
 v_cursor date;
 v_last date;
 v_created integer:=0;
begin
 if v_uid is null then raise exception 'Sign-in required'; end if;
 -- Backfill only dates with five or more saved decisions, using Dhaka calendar days.
 for v_day in
   select distinct (d.created_at at time zone 'Asia/Dhaka')::date
   from public.decisions d
   where d.user_id=v_uid and d.created_at < ((v_today+1)::timestamp at time zone 'Asia/Dhaka')
   order by 1
 loop
   select count(*) into v_count from public.decisions d
   where d.user_id=v_uid and (d.created_at at time zone 'Asia/Dhaka')::date=v_day;
   v_qualifies:=v_count>=5;
   insert into public.streak_daily(user_id,local_day,completed_decisions,qualifies)
   values(v_uid,v_day,v_count,v_qualifies)
   on conflict(user_id,local_day) do update
    set completed_decisions=excluded.completed_decisions,qualifies=excluded.qualifies,checked_at=now();
 end loop;
 -- Current streak is consecutive qualified days ending today or yesterday, with missed days resetting it.
 select max(local_day) into v_last from public.streak_daily where user_id=v_uid and qualifies and local_day<=v_today;
 if v_last is not null and v_last>=v_today-1 then
   v_cursor:=v_last;
   while exists(select 1 from public.streak_daily where user_id=v_uid and local_day=v_cursor and qualifies) loop
     v_current:=v_current+1;
     v_cursor:=v_cursor-1;
   end loop;
 end if;
 -- Record only exact milestone crossings, once per account and milestone.
 if v_current=60 then
   insert into public.streak_milestones(user_id,milestone_days,achieved_on,reward_code)
   values(v_uid,60,v_today,'pro_7_days') on conflict do nothing;
 elsif v_current>=365 and v_current%365=0 then
   insert into public.streak_milestones(user_id,milestone_days,achieved_on,reward_code)
   values(v_uid,v_current,v_today,'extra_premium_1_day') on conflict do nothing;
 end if;
 select coalesce(max(run_len),0) into v_best from (
   select count(*) run_len from (
    select local_day,local_day-(row_number() over(order by local_day))::integer grp
    from public.streak_daily where user_id=v_uid and qualifies
   ) q group by grp
 ) runs;
 return jsonb_build_object('today',v_today,'qualifying_today',exists(select 1 from public.streak_daily where user_id=v_uid and local_day=v_today and qualifies),'today_decisions',coalesce((select completed_decisions from public.streak_daily where user_id=v_uid and local_day=v_today),0),'current_streak',v_current,'best_streak',v_best,'next_milestone',case when v_current<60 then 60 when v_current<365 then 365 else ((v_current/365)+1)*365 end);
end; $$;
revoke all on function public.clario_refresh_streak() from public;
grant execute on function public.clario_refresh_streak() to authenticated;
comment on table public.streak_milestones is 'Idempotent earned streak reward records. Subscription entitlement delivery must be integrated before treating rewards as active plan access.';
