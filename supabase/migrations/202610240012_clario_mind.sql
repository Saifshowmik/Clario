-- Clario Mind: privacy-first wellbeing sessions.
-- This stores user-authored check-ins only; it does not provide AI diagnosis or emergency monitoring.
create table if not exists public.mind_sessions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 age_band text not null check(age_band in ('under_13','13_15','16_17','18_plus')),
 locale text not null default 'en' check(locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
 session_mode text not null default 'temporary' check(session_mode in ('temporary','saved')),
 mood text not null check(mood in ('great','okay','low','anxious','overwhelmed','angry','numb','other')),
 needs text[] not null default '{}' check(cardinality(needs)<=8),
 note text not null default '' check(length(note)<=4000),
 created_at timestamptz not null default now(),
 expires_at timestamptz,
 check((session_mode='temporary' and expires_at is not null) or (session_mode='saved' and expires_at is null))
);
create index if not exists mind_sessions_user_created_idx on public.mind_sessions(user_id,created_at desc);
alter table public.mind_sessions enable row level security;
drop policy if exists mind_sessions_select_own on public.mind_sessions;
create policy mind_sessions_select_own on public.mind_sessions for select to authenticated using(user_id=auth.uid() and session_mode='saved');
drop policy if exists mind_sessions_insert_own on public.mind_sessions;
create policy mind_sessions_insert_own on public.mind_sessions for insert to authenticated with check(user_id=auth.uid());
drop policy if exists mind_sessions_delete_own on public.mind_sessions;
create policy mind_sessions_delete_own on public.mind_sessions for delete to authenticated using(user_id=auth.uid());
revoke all on public.mind_sessions from anon;
revoke update on public.mind_sessions from anon,authenticated;
grant select,insert,delete on public.mind_sessions to authenticated;

create or replace function public.clario_mind_save_session(
 p_age_band text,p_locale text,p_session_mode text,p_mood text,p_needs text[],p_note text
) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_id uuid; v_exp timestamptz;
begin
 if v_uid is null then raise exception 'Sign-in required'; end if;
 if p_age_band not in ('under_13','13_15','16_17','18_plus') then raise exception 'Invalid age group'; end if;
 if p_locale !~ '^[a-z]{2}(-[A-Z]{2})?$' then raise exception 'Invalid language'; end if;
 if p_session_mode not in ('temporary','saved') then raise exception 'Invalid session mode'; end if;
 if p_mood not in ('great','okay','low','anxious','overwhelmed','angry','numb','other') then raise exception 'Invalid mood'; end if;
 if coalesce(cardinality(p_needs),0)>8 or length(coalesce(p_note,''))>4000 then raise exception 'Session is too long'; end if;
 -- Minors' guardian-consent verification is not implemented: do not persist their sessions yet.
 if p_age_band<>'18_plus' then raise exception 'Saved sessions for minors are disabled until guardian-consent safeguards are configured'; end if;
 v_exp:=case when p_session_mode='temporary' then now()+interval '24 hours' else null end;
 insert into public.mind_sessions(user_id,age_band,locale,session_mode,mood,needs,note,expires_at)
 values(v_uid,p_age_band,p_locale,p_session_mode,p_mood,coalesce(p_needs,'{}'),coalesce(p_note,''),v_exp) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.clario_mind_save_session(text,text,text,text,text[],text) from public;
grant execute on function public.clario_mind_save_session(text,text,text,text,text[],text) to authenticated;

create or replace function public.clario_mind_list_sessions()
returns setof public.mind_sessions language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'Sign-in required'; end if;
 delete from public.mind_sessions where user_id=auth.uid() and session_mode='temporary' and expires_at<=now();
 return query select * from public.mind_sessions where user_id=auth.uid() and session_mode='saved' order by created_at desc limit 100;
end; $$;
revoke all on function public.clario_mind_list_sessions() from public;
grant execute on function public.clario_mind_list_sessions() to authenticated;
