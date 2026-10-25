-- Clario social profile foundation. Apply to a dedicated staging Supabase project first.
alter table public.profiles
  add column if not exists username text,
  add column if not exists bio text not null default '',
  add column if not exists interests text[] not null default '{}',
  add column if not exists profile_visibility text not null default 'private'
    check (profile_visibility in ('public','private','followers'));

create unique index if not exists profiles_username_lower_unique
  on public.profiles (lower(username)) where username is not null;

create or replace function public.clario_guard_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Profile owners may edit profile fields, never grant themselves privileges or paid plans.
  if auth.uid() is not null and old.id = auth.uid() then
    if new.role is distinct from old.role or new.plan is distinct from old.plan then
      raise exception 'Role and plan changes require an authorized server-side workflow';
    end if;
  end if;
  if new.username is not null then
    new.username := lower(trim(new.username));
    if new.username !~ '^[a-z0-9_]{3,24}$' then
      raise exception 'Username must be 3–24 characters using letters, numbers, or underscores';
    end if;
  end if;
  if char_length(coalesce(new.bio,'')) > 240 then
    raise exception 'Bio must be 240 characters or fewer';
  end if;
  if cardinality(coalesce(new.interests,'{}'::text[])) > 12 then
    raise exception 'Choose no more than 12 interests';
  end if;
  return new;
end $$;

drop trigger if exists clario_guard_profile_privileges on public.profiles;
create trigger clario_guard_profile_privileges
before update on public.profiles
for each row execute function public.clario_guard_profile_privileges();

comment on column public.profiles.profile_visibility is 'Profile visibility preference; public/follower feed enforcement must be implemented before enabling social discovery.';
