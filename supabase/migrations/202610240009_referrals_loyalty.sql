-- Referral qualification and loyalty ledger.
-- Referral rewards and points are policy-configurable; zero values mean no financial/point award until the owner sets a policy.
create table if not exists public.reward_policy (
  id boolean primary key default true check (id=true),
  referral_credit_amount numeric(12,2) not null default 0 check (referral_credit_amount>=0),
  loyalty_points_per_paid_payment integer not null default 0 check (loyalty_points_per_paid_payment>=0),
  credit_currency text not null default 'BDT' check (credit_currency in ('BDT','USD','EUR','INR','GBP')),
  updated_at timestamptz not null default now()
);
insert into public.reward_policy(id) values(true) on conflict(id) do nothing;
alter table public.reward_policy enable row level security;
drop policy if exists reward_policy_read on public.reward_policy;
create policy reward_policy_read on public.reward_policy for select to authenticated using (true);
revoke insert,update,delete on public.reward_policy from anon,authenticated;
grant select on public.reward_policy to authenticated;

create table if not exists public.referral_codes (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  code text not null unique check (code ~ '^[A-Z0-9]{8,12}$'),
  created_at timestamptz not null default now()
);
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles(id) on delete cascade,
  referred_id uuid not null unique references public.profiles(id) on delete cascade,
  referral_code text not null references public.referral_codes(code),
  status text not null default 'pending' check(status in ('pending','qualified','rewarded','rejected')),
  qualifying_payment_id uuid unique references public.payments(id) on delete set null,
  qualified_at timestamptz,
  created_at timestamptz not null default now(),
  check(referrer_id<>referred_id)
);
create table if not exists public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check(kind in ('referral_credit','loyalty_points')),
  amount numeric(12,2) not null default 0 check(amount>=0),
  points integer not null default 0 check(points>=0),
  currency text not null default 'BDT' check(currency in ('BDT','USD','EUR','INR','GBP')),
  source_payment_id uuid references public.payments(id) on delete set null,
  source_referral_id uuid references public.referrals(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(user_id,kind,source_payment_id),
  unique(user_id,kind,source_referral_id)
);
alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;
alter table public.reward_ledger enable row level security;
drop policy if exists referral_codes_read on public.referral_codes;
create policy referral_codes_read on public.referral_codes for select to authenticated using(user_id=auth.uid());
drop policy if exists referrals_read on public.referrals;
create policy referrals_read on public.referrals for select to authenticated using(referrer_id=auth.uid() or referred_id=auth.uid());
drop policy if exists reward_ledger_read on public.reward_ledger;
create policy reward_ledger_read on public.reward_ledger for select to authenticated using(user_id=auth.uid());
revoke all on public.referral_codes,public.referrals,public.reward_ledger from anon;
revoke insert,update,delete on public.referral_codes,public.referrals,public.reward_ledger from anon,authenticated;
grant select on public.referral_codes,public.referrals,public.reward_ledger to authenticated;

create or replace function public.clario_ensure_referral_code()
returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare v_code text; v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'Sign-in required'; end if;
 select code into v_code from public.referral_codes where user_id=v_uid;
 if v_code is not null then return v_code; end if;
 loop
   v_code:=upper(substr(encode(gen_random_bytes(8),'hex'),1,10));
   begin insert into public.referral_codes(user_id,code) values(v_uid,v_code); exit;
   exception when unique_violation then null; end;
 end loop;
 return v_code;
end; $$;
revoke all on function public.clario_ensure_referral_code() from public;
grant execute on function public.clario_ensure_referral_code() to authenticated;

create or replace function public.clario_apply_referral(p_code text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_referrer uuid;
begin
 if v_uid is null then raise exception 'Sign-in required'; end if;
 if exists(select 1 from public.payments where user_id=v_uid and status='approved') then raise exception 'Referral must be applied before the first successful paid subscription'; end if;
 select user_id into v_referrer from public.referral_codes where code=upper(trim(p_code));
 if v_referrer is null then raise exception 'Referral code not found'; end if;
 if v_referrer=v_uid then raise exception 'Self-referrals are not allowed'; end if;
 insert into public.referrals(referrer_id,referred_id,referral_code) values(v_referrer,v_uid,upper(trim(p_code)));
end; $$;
revoke all on function public.clario_apply_referral(text) from public;
grant execute on function public.clario_apply_referral(text) to authenticated;

create or replace function public.clario_process_paid_reward()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare v_policy public.reward_policy%rowtype; v_ref public.referrals%rowtype;
begin
 if new.status='approved' and old.status is distinct from 'approved' then
   select * into v_policy from public.reward_policy where id=true;
   if coalesce(v_policy.loyalty_points_per_paid_payment,0)>0 then
     insert into public.reward_ledger(user_id,kind,points,currency,source_payment_id)
     values(new.user_id,'loyalty_points',v_policy.loyalty_points_per_paid_payment,v_policy.credit_currency,new.id)
     on conflict do nothing;
   end if;
   select * into v_ref from public.referrals where referred_id=new.user_id and status='pending' for update;
   if found then
     update public.referrals set status='qualified',qualifying_payment_id=new.id,qualified_at=now() where id=v_ref.id;
     if coalesce(v_policy.referral_credit_amount,0)>0 then
       insert into public.reward_ledger(user_id,kind,amount,currency,source_payment_id,source_referral_id)
       values(v_ref.referrer_id,'referral_credit',v_policy.referral_credit_amount,v_policy.credit_currency,new.id,v_ref.id)
       on conflict do nothing;
       update public.referrals set status='rewarded' where id=v_ref.id;
     end if;
   end if;
 end if;
 return new;
end; $$;
drop trigger if exists clario_paid_reward_after_payment on public.payments;
create trigger clario_paid_reward_after_payment after update of status on public.payments
for each row execute function public.clario_process_paid_reward();

create or replace function public.clario_reward_policy_set(p_referral_credit numeric,p_points integer,p_currency text,p_reason text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if not public.is_owner() then raise exception 'Owner access required'; end if;
 if p_referral_credit<0 or p_points<0 then raise exception 'Reward values cannot be negative'; end if;
 if p_currency not in ('BDT','USD','EUR','INR','GBP') then raise exception 'Unsupported currency'; end if;
 if length(trim(coalesce(p_reason,'')))<8 then raise exception 'A reason of at least 8 characters is required'; end if;
 update public.reward_policy set referral_credit_amount=p_referral_credit,loyalty_points_per_paid_payment=p_points,credit_currency=p_currency,updated_at=now() where id=true;
 insert into public.audit_log(actor,action,reason) values(auth.uid(),'update_reward_policy',trim(p_reason));
end; $$;
revoke all on function public.clario_reward_policy_set(numeric,integer,text,text) from public;
grant execute on function public.clario_reward_policy_set(numeric,integer,text,text) to authenticated;
