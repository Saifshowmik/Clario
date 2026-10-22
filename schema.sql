-- Clario schema. Run once in Supabase > SQL Editor.
-- Security lives here, not in the web page: row-level security (RLS) plus owner-only functions.

create table public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  email text, name text,
  budget numeric not null default 0,
  priority text not null default 'balanced' check (priority in ('price','balanced','quality')),
  role text not null default 'user' check (role in ('user','owner')),
  plan text not null default 'free' check (plan in ('free','pro','premium','extra_premium')),
  created_at timestamptz not null default now());

create table public.decisions(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  best text not null, score int not null,
  created_at timestamptz not null default now());

create table public.usage(
  user_id uuid references public.profiles(id) on delete cascade,
  day date not null, n int not null default 0,
  primary key(user_id, day));

create table public.payments(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan text not null check (plan in ('pro','premium','extra_premium')),
  period text not null check (period in ('weekly','monthly','yearly')),
  method text not null check (method in ('bkash','nagad')),
  trx_id text not null check (length(trx_id) between 4 and 40),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reason text,
  created_at timestamptz not null default now(),
  unique(method, trx_id));

create table public.prices(
  plan text not null, period text not null,
  price numeric not null check (price >= 0),
  primary key(plan, period));

create table public.audit_log(
  id bigint generated always as identity primary key,
  actor uuid, action text not null, reason text not null,
  created_at timestamptz not null default now());

-- Helpers
create function public.is_owner() returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from profiles where id = auth.uid() and role = 'owner') $$;

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as
$$ begin insert into public.profiles(id, email) values (new.id, new.email); return new; end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row-level security: customers only reach their own rows
alter table public.profiles  enable row level security;
alter table public.decisions enable row level security;
alter table public.usage     enable row level security;
alter table public.payments  enable row level security;
alter table public.prices    enable row level security;
alter table public.audit_log enable row level security;

create policy profiles_read   on public.profiles  for select using (id = auth.uid() or public.is_owner());
create policy profiles_update on public.profiles  for update using (id = auth.uid()) with check (id = auth.uid());
create policy decisions_read  on public.decisions for select using (user_id = auth.uid());
create policy decisions_del   on public.decisions for delete using (user_id = auth.uid());
create policy usage_read      on public.usage     for select using (user_id = auth.uid());
create policy payments_read   on public.payments  for select using (user_id = auth.uid() or public.is_owner());
create policy payments_ins    on public.payments  for insert with check (user_id = auth.uid() and status = 'pending' and reason is null);
create policy prices_read     on public.prices    for select using (true);
create policy audit_read      on public.audit_log for select using (public.is_owner());

-- Block direct writes. Customers can edit only name, budget and priority on their own profile.
revoke insert, update, delete on public.profiles  from anon, authenticated;
grant  update (name, budget, priority) on public.profiles to authenticated;
revoke insert, update on public.decisions from anon, authenticated;
revoke insert, update, delete on public.usage     from anon, authenticated;
revoke update, delete on public.payments          from anon, authenticated;
revoke insert, update, delete on public.prices    from anon, authenticated;
revoke insert, update, delete on public.audit_log from anon, authenticated;

-- Daily limit, enforced on the server (free 5, pro 15, premium 25, extra premium and owner unlimited)
create function public.save_decision(p_best text, p_score int) returns void
language plpgsql security definer set search_path = public as $$
declare v_plan text; v_lim int; v_n int;
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  select case when role = 'owner' then 'extra_premium' else plan end into v_plan from profiles where id = auth.uid();
  v_lim := case v_plan when 'free' then 5 when 'pro' then 15 when 'premium' then 25 else 2147483647 end;
  insert into usage(user_id, day, n) values (auth.uid(), current_date, 0) on conflict do nothing;
  update usage set n = n + 1 where user_id = auth.uid() and day = current_date and n < v_lim returning n into v_n;
  if v_n is null then raise exception 'daily limit reached'; end if;
  insert into decisions(user_id, best, score) values (auth.uid(), left(p_best, 120), p_score);
end $$;

-- Owner-only actions. Each needs a written reason and writes to the audit log.
create function public.review_payment(p_id uuid, p_ok boolean, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare v_u uuid; v_p text;
begin
  if not public.is_owner() then raise exception 'owner only'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'reason required'; end if;
  update payments set status = case when p_ok then 'approved' else 'rejected' end, reason = p_reason
    where id = p_id and status = 'pending' returning user_id, plan into v_u, v_p;
  if v_u is null then raise exception 'payment not found or already reviewed'; end if;
  if p_ok then update profiles set plan = v_p where id = v_u; end if;
  insert into audit_log(actor, action, reason)
    values (auth.uid(), case when p_ok then 'approve_payment ' else 'reject_payment ' end || p_id, p_reason);
end $$;

create function public.set_plan(p_user uuid, p_plan text, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_owner() then raise exception 'owner only'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'reason required'; end if;
  update profiles set plan = p_plan where id = p_user;
  insert into audit_log(actor, action, reason) values (auth.uid(), 'set_plan ' || p_user || ' ' || p_plan, p_reason);
end $$;

create function public.set_price(p_plan text, p_period text, p_price numeric, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_owner() then raise exception 'owner only'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'reason required'; end if;
  insert into prices(plan, period, price) values (p_plan, p_period, p_price)
    on conflict (plan, period) do update set price = excluded.price;
  insert into audit_log(actor, action, reason) values (auth.uid(), 'set_price ' || p_plan || ' ' || p_period || ' ' || p_price, p_reason);
end $$;

-- AFTER you sign up on the site and confirm your email, make yourself the owner (run this in the SQL Editor):
-- update public.profiles set role = 'owner' where email = 'YOUR-EMAIL@example.com';
