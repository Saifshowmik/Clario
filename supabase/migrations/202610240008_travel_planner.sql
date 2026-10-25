-- Clario Tour & Travel: private trip-planning workspace, not a booking engine.
create table if not exists public.travel_trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 100),
  origin text not null check (char_length(trim(origin)) between 1 and 160),
  destination text not null check (char_length(trim(destination)) between 1 and 160),
  start_date date,
  end_date date,
  travel_style text not null default 'solo' check (travel_style in ('solo','duo','group')),
  group_size integer not null default 1 check (group_size between 1 and 30),
  budget_amount numeric(12,2) check (budget_amount is null or budget_amount >= 0),
  budget_currency text not null default 'BDT' check (budget_currency in ('BDT','USD','EUR','INR','GBP')),
  interests text[] not null default '{}',
  accessibility_notes text not null default '' check (char_length(accessibility_notes) <= 1000),
  itinerary_notes text not null default '' check (char_length(itinerary_notes) <= 10000),
  status text not null default 'draft' check (status in ('draft','planned','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint travel_dates_order check (start_date is null or end_date is null or end_date >= start_date)
);
alter table public.travel_trips enable row level security;
drop policy if exists travel_trips_read_own on public.travel_trips;
create policy travel_trips_read_own on public.travel_trips for select to authenticated using (user_id=auth.uid());
drop policy if exists travel_trips_insert_own on public.travel_trips;
create policy travel_trips_insert_own on public.travel_trips for insert to authenticated with check (user_id=auth.uid());
drop policy if exists travel_trips_update_own on public.travel_trips;
create policy travel_trips_update_own on public.travel_trips for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists travel_trips_delete_own on public.travel_trips;
create policy travel_trips_delete_own on public.travel_trips for delete to authenticated using (user_id=auth.uid());
revoke all on public.travel_trips from anon;
grant select,insert,update,delete on public.travel_trips to authenticated;
create index if not exists travel_trips_user_updated_idx on public.travel_trips(user_id,updated_at desc);
create or replace function public.clario_travel_touch_updated_at()
returns trigger language plpgsql set search_path=public,pg_temp as $$
begin new.updated_at=now(); return new; end; $$;
drop trigger if exists travel_trips_touch_updated_at on public.travel_trips;
create trigger travel_trips_touch_updated_at before update on public.travel_trips
for each row execute function public.clario_travel_touch_updated_at();
comment on table public.travel_trips is 'Private travel planning drafts. Not a booking or live-price availability system.';
