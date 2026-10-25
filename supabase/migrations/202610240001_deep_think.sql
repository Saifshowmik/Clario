-- Clario Deep Think: human-only review workflow.
-- Apply to a dedicated staging Supabase project first. Do not run against production until reviewed.
create table if not exists public.deep_think_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 240),
  background text not null default '',
  goals text not null default '',
  options_text text not null default '',
  constraints_text text not null default '',
  risks text not null default '',
  additional_text text not null default '',
  status text not null default 'submitted' check (status in ('draft','submitted','in_review','needs_information','decision_ready','delivered','closed')),
  final_decision text,
  internal_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz
);
create table if not exists public.deep_think_case_events (
 id uuid primary key default gen_random_uuid(),
 case_id uuid not null references public.deep_think_cases(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 event_type text not null check (event_type in ('submitted','status_changed','decision_delivered')),
 status text,
 message text,
 created_at timestamptz not null default now()
);
create index if not exists deep_think_case_events_case_created_idx on public.deep_think_case_events(case_id, created_at);
alter table public.deep_think_case_events enable row level security;
revoke all on public.deep_think_case_events from anon, authenticated;
grant select (id,case_id,actor_id,event_type,status,message,created_at) on public.deep_think_case_events to authenticated;
create index if not exists deep_think_cases_user_created_idx on public.deep_think_cases(user_id, created_at desc);
create index if not exists deep_think_cases_status_created_idx on public.deep_think_cases(status, created_at);
alter table public.deep_think_cases enable row level security;
revoke all on public.deep_think_cases from anon, authenticated;
-- Column-level grants intentionally exclude internal_note from all client reads.
grant select (id,user_id,title,background,goals,options_text,constraints_text,risks,additional_text,status,final_decision,created_at,updated_at,reviewed_by,reviewed_at)
on public.deep_think_cases to authenticated;

create or replace function public.clario_can_review_deep_think()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner');
$$;
revoke all on function public.clario_can_review_deep_think() from public;
grant execute on function public.clario_can_review_deep_think() to authenticated;

drop policy if exists deep_think_events_own_or_reviewer on public.deep_think_case_events;
create policy deep_think_events_own_or_reviewer on public.deep_think_case_events for select to authenticated
using (exists(select 1 from public.deep_think_cases c where c.id=case_id and (c.user_id=auth.uid() or public.clario_can_review_deep_think())));

drop policy if exists deep_think_select_own_or_reviewer on public.deep_think_cases;
create policy deep_think_select_own_or_reviewer on public.deep_think_cases
for select to authenticated
using (user_id = auth.uid() or public.clario_can_review_deep_think());

create or replace function public.submit_deep_think_case(
  p_title text, p_background text default '', p_goals text default '',
  p_options text default '', p_constraints text default '', p_risks text default '',
  p_additional text default ''
) returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 240 then
    raise exception 'Decision title must be between 3 and 240 characters';
  end if;
  insert into public.deep_think_cases(user_id,title,background,goals,options_text,constraints_text,risks,additional_text)
  values(auth.uid(),trim(p_title),coalesce(p_background,''),coalesce(p_goals,''),coalesce(p_options,''),coalesce(p_constraints,''),coalesce(p_risks,''),coalesce(p_additional,''))
  returning id into new_id;
  insert into public.deep_think_case_events(case_id,actor_id,event_type,status,message)
  values(new_id,auth.uid(),'submitted','submitted','Case submitted for human-only review');
  return new_id;
end $$;
revoke all on function public.submit_deep_think_case(text,text,text,text,text,text,text) from public, anon;
grant execute on function public.submit_deep_think_case(text,text,text,text,text,text,text) to authenticated;

create or replace function public.review_deep_think_case(
  p_case_id uuid, p_status text, p_final_decision text default null, p_internal_note text default ''
) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null or not public.clario_can_review_deep_think() then raise exception 'Owner access required'; end if;
  if p_status not in ('in_review','needs_information','decision_ready','delivered','closed') then raise exception 'Invalid status'; end if;
  if p_status = 'delivered' and (p_final_decision is null or char_length(trim(p_final_decision)) = 0) then
    raise exception 'A final decision is required before delivery';
  end if;
  update public.deep_think_cases
  set status=p_status,
      final_decision=case when p_status='delivered' then p_final_decision else final_decision end,
      internal_note=coalesce(p_internal_note,''),
      reviewed_by=auth.uid(), reviewed_at=now(), updated_at=now()
  where id=p_case_id;
  if not found then raise exception 'Case not found'; end if;
  insert into public.deep_think_case_events(case_id,actor_id,event_type,status,message)
  values(p_case_id,auth.uid(),case when p_status='delivered' then 'decision_delivered' else 'status_changed' end,p_status,
    case when p_status='delivered' then 'Human decision delivered' else 'Review status updated' end);
end $$;
revoke all on function public.review_deep_think_case(uuid,text,text,text) from public, anon;
grant execute on function public.review_deep_think_case(uuid,text,text,text) to authenticated;
