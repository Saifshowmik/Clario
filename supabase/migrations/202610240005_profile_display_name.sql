-- Add a separate public display name without exposing account privileges.
alter table public.profiles
  add column if not exists display_name text not null default '';

create or replace function public.clario_guard_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
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
  if char_length(coalesce(new.display_name,'')) > 80 then
    raise exception 'Display name must be 80 characters or fewer';
  end if;
  if char_length(coalesce(new.bio,'')) > 240 then
    raise exception 'Bio must be 240 characters or fewer';
  end if;
  if cardinality(coalesce(new.interests,'{}'::text[])) > 12 then
    raise exception 'Choose no more than 12 interests';
  end if;
  return new;
end $$;
