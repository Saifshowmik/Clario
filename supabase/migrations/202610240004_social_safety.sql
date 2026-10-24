-- Clario social safety: user blocks, mutes, and report queue.
create table if not exists public.social_mutes (
  muter_id uuid not null references public.profiles(id) on delete cascade,
  muted_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (muter_id,muted_id),
  constraint social_mutes_not_self check (muter_id <> muted_id)
);
create table if not exists public.social_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  post_id uuid references public.social_posts(id) on delete set null,
  reason text not null check (reason in ('spam','harassment','hate','sexual_content','violence','self_harm','impersonation','other')),
  details text not null default '' check (char_length(details) <= 1500),
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  constraint social_reports_target_required check (reported_user_id is not null or post_id is not null)
);
alter table public.social_mutes enable row level security;
alter table public.social_reports enable row level security;
create policy social_mutes_read_own on public.social_mutes for select to authenticated using (muter_id=auth.uid());
create policy social_mutes_insert_own on public.social_mutes for insert to authenticated with check (muter_id=auth.uid() and not public.clario_social_is_blocked(auth.uid(),muted_id));
create policy social_mutes_delete_own on public.social_mutes for delete to authenticated using (muter_id=auth.uid());
create policy social_reports_insert_own on public.social_reports for insert to authenticated
with check (reporter_id=auth.uid() and (reported_user_id is null or reported_user_id <> auth.uid()));
create policy social_reports_read_own on public.social_reports for select to authenticated using (reporter_id=auth.uid());
revoke update, delete on public.social_reports from authenticated;
grant select, insert on public.social_reports to authenticated;
grant select, insert, delete on public.social_mutes to authenticated;
create index if not exists social_reports_open_created_idx on public.social_reports(status,created_at desc);
create index if not exists social_mutes_lookup_idx on public.social_mutes(muter_id,muted_id);
comment on table public.social_reports is 'User reports are private to the reporter; status changes require trusted moderation tooling.';
