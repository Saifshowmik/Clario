-- Test-only Supabase auth/profile fixture for CI. Never used by production.
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (id uuid primary key);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('user','owner')),
  plan text not null default 'free'
);
create or replace function auth.uid()
returns uuid language sql stable as $
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$;

-- Minimal core Clario schema needed to integration-test paid rewards and streak entitlements.
create table public.decisions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 best text not null,
 score integer not null,
 created_at timestamptz not null default now()
);
create table public.usage (
 user_id uuid references public.profiles(id) on delete cascade,
 day date not null,
 n integer not null default 0,
 primary key(user_id,day)
);
create table public.payments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 plan text not null check(plan in ('pro','premium','extra_premium')),
 period text not null check(period in ('weekly','monthly','yearly')),
 method text not null check(method in ('bkash','nagad')),
 trx_id text not null unique,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 reason text,
 created_at timestamptz not null default now()
);
create table public.audit_log (
 id bigint generated always as identity primary key,
 actor uuid,
 action text not null,
 reason text not null,
 created_at timestamptz not null default now()
);
create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path=public as $
 select exists(select 1 from public.profiles where id=auth.uid() and role='owner')
$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
insert into auth.users(id) values
 ('10000000-0000-4000-8000-000000000001'),
 ('10000000-0000-4000-8000-000000000002'),
 ('10000000-0000-4000-8000-000000000003');
insert into public.profiles(id, role) values
 ('10000000-0000-4000-8000-000000000001','user'),
 ('10000000-0000-4000-8000-000000000002','owner'),
 ('10000000-0000-4000-8000-000000000003','user');

grant select, update on public.profiles to authenticated;

-- Minimal storage schema fixture for testing private profile-media policies.
create schema storage;
create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table storage.objects (
  id bigint generated always as identity primary key,
  bucket_id text not null,
  name text not null
);
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
create or replace function storage.foldername(object_name text)
returns text[] language sql immutable as $$
  select case
    when object_name is null or position('/' in object_name) = 0 then array[]::text[]
    else string_to_array(regexp_replace(object_name, '/[^/]+$', ''), '/')
  end;
$$;
grant execute on function storage.foldername(text) to authenticated;
