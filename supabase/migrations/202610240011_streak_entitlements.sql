-- Temporary plan entitlements for earned streak rewards.
-- Grants expire automatically; the effective plan is the highest active tier, so a reward never downgrades paid access.
create table if not exists public.plan_entitlement_grants (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 plan text not null check(plan in ('pro','premium','extra_premium')),
 starts_at timestamptz not null default now(),
 expires_at timestamptz not null,
 source text not null check(source in ('streak_60','streak_365')),
 source_milestone_id uuid not null unique references public.streak_milestones(id) on delete cascade,
 created_at timestamptz not null default now(),
 check(expires_at>starts_at)
);
alter table public.plan_entitlement_grants enable row level security;
drop policy if exists plan_entitlement_read_own on public.plan_entitlement_grants;
create policy plan_entitlement_read_own on public.plan_entitlement_grants for select to authenticated using(user_id=auth.uid());
revoke all on public.plan_entitlement_grants from anon,authenticated;
grant select on public.plan_entitlement_grants to authenticated;

create or replace function public.clario_effective_plan(p_user uuid default auth.uid())
returns text language plpgsql stable security definer set search_path=public,pg_temp as $$
declare v_base text; v_grant text;
begin
 if auth.uid() is null or (p_user<>auth.uid() and not public.is_owner()) then raise exception 'Not authorized'; end if;
 select case when role='owner' then 'extra_premium' else plan end into v_base from public.profiles where id=p_user;
 if v_base is null then raise exception 'Profile not found'; end if;
 select plan into v_grant from public.plan_entitlement_grants
 where user_id=p_user and starts_at<=now() and expires_at>now()
 order by case plan when 'extra_premium' then 3 when 'premium' then 2 when 'pro' then 1 else 0 end desc,expires_at desc limit 1;
 if coalesce(case v_base when 'extra_premium' then 3 when 'premium' then 2 when 'pro' then 1 else 0 end,0)
    >= coalesce(case v_grant when 'extra_premium' then 3 when 'premium' then 2 when 'pro' then 1 else 0 end,0)
 then return v_base; end if;
 return v_grant;
end; $$;
revoke all on function public.clario_effective_plan(uuid) from public;
grant execute on function public.clario_effective_plan(uuid) to authenticated;

create or replace function public.clario_deliver_streak_rewards()
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_m public.streak_milestones%rowtype; v_count integer:=0; v_plan text; v_days integer;
begin
 if v_uid is null then raise exception 'Sign-in required'; end if;
 -- Refresh first so rewards are based on server-counted completed decisions.
 perform public.clario_refresh_streak();
 for v_m in select * from public.streak_milestones where user_id=v_uid order by created_at loop
   if v_m.reward_code='pro_7_days' then v_plan:='pro';v_days:=7;
   elsif v_m.reward_code='extra_premium_1_day' then v_plan:='extra_premium';v_days:=1;
   else continue;
   end if;
   insert into public.plan_entitlement_grants(user_id,plan,starts_at,expires_at,source,source_milestone_id)
   values(v_uid,v_plan,now(),now()+make_interval(days=>v_days),
     case when v_m.milestone_days=60 then 'streak_60' else 'streak_365' end,v_m.id)
   on conflict(source_milestone_id) do nothing;
   if found then v_count:=v_count+1; end if;
 end loop;
 return v_count;
end; $$;
revoke all on function public.clario_deliver_streak_rewards() from public;
grant execute on function public.clario_deliver_streak_rewards() to authenticated;

-- Enforce temporary entitlements at the server-side decision limit, never trusting client plan labels.
create or replace function public.save_decision(p_best text,p_score int) returns void
language plpgsql security definer set search_path=public,pg_temp as $$
declare v_plan text;v_lim int;v_n int;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 v_plan:=public.clario_effective_plan(auth.uid());
 v_lim:=case v_plan when 'free' then 5 when 'pro' then 15 when 'premium' then 25 else 2147483647 end;
 insert into public.usage(user_id,day,n) values(auth.uid(),(now() at time zone 'Asia/Dhaka')::date,0) on conflict do nothing;
 update public.usage set n=n+1 where user_id=auth.uid() and day=(now() at time zone 'Asia/Dhaka')::date and n<v_lim returning n into v_n;
 if v_n is null then raise exception 'daily limit reached'; end if;
 insert into public.decisions(user_id,best,score) values(auth.uid(),left(p_best,120),p_score);
end; $$;
revoke all on function public.save_decision(text,int) from public;
grant execute on function public.save_decision(text,int) to authenticated;
