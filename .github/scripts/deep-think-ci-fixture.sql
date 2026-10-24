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
returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
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
grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
create or replace function storage.foldername(name text)
returns text[] language sql immutable as $$
  select string_to_array(name, '/')[1:greatest(array_length(string_to_array(name, '/'),1)-1,0)];
$$;
grant execute on function storage.foldername(text) to authenticated;
