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
  post_id uuid, -- retain the reported post identifier even if the post is later deleted
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

-- Username resolution exposes only the target UUID, never private profile fields.
create or replace function public.resolve_social_username(p_username text)
returns uuid language plpgsql stable security definer set search_path=public,pg_temp as $$
declare v_target uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_username is null or lower(trim(p_username)) !~ '^[a-z0-9_]{3,24}$' then raise exception 'Invalid username'; end if;
  select id into v_target from public.profiles where lower(username)=lower(trim(p_username)) and id<>auth.uid();
  if v_target is null then raise exception 'No available member found'; end if;
  if public.clario_social_is_blocked(auth.uid(),v_target) then raise exception 'No available member found'; end if;
  return v_target;
end $$;
revoke all on function public.resolve_social_username(text) from public;
grant execute on function public.resolve_social_username(text) to authenticated;

create or replace function public.block_social_member(p_username text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare v_target uuid;
begin
  v_target := public.resolve_social_username(p_username);
  insert into public.social_blocks(blocker_id,blocked_id) values(auth.uid(),v_target) on conflict do nothing;
  delete from public.social_follows where (requester_id=auth.uid() and target_id=v_target) or (requester_id=v_target and target_id=auth.uid());
end $$;
revoke all on function public.block_social_member(text) from public;
grant execute on function public.block_social_member(text) to authenticated;

create or replace function public.mute_social_member(p_username text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare v_target uuid;
begin
  v_target := public.resolve_social_username(p_username);
  insert into public.social_mutes(muter_id,muted_id) values(auth.uid(),v_target) on conflict do nothing;
end $$;
revoke all on function public.mute_social_member(text) from public;
grant execute on function public.mute_social_member(text) to authenticated;

drop policy if exists social_posts_read_audience on public.social_posts;
create policy social_posts_read_audience on public.social_posts for select to authenticated
using (
  status='published'
  and not public.clario_social_is_blocked(auth.uid(),author_id)
  and not exists(select 1 from public.social_mutes m where m.muter_id=auth.uid() and m.muted_id=author_id)
  and (
    author_id=auth.uid()
    or (audience='public' and exists(select 1 from public.profiles p where p.id=author_id and p.profile_visibility='public'))
    or (audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=author_id and f.status='accepted'))
  )
);
drop policy if exists social_stories_read_active_audience on public.social_stories;
create policy social_stories_read_active_audience on public.social_stories for select to authenticated
using (
  expires_at > now()
  and not public.clario_social_is_blocked(auth.uid(),author_id)
  and not exists(select 1 from public.social_mutes m where m.muter_id=auth.uid() and m.muted_id=author_id)
  and (
    author_id=auth.uid()
    or (audience='public' and exists(select 1 from public.profiles p where p.id=author_id and p.profile_visibility='public'))
    or (audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=author_id and f.status='accepted'))
  )
);

-- Only a verified owner can resolve reports; client users cannot edit report status directly.
create or replace function public.review_social_report(p_report_id uuid, p_status text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='owner') then
    raise exception 'Owner access required';
  end if;
  if p_status not in ('reviewing','resolved','dismissed') then
    raise exception 'Invalid moderation status';
  end if;
  update public.social_reports
    set status=p_status, reviewed_at=now(), reviewed_by=auth.uid()
    where id=p_report_id;
  if not found then raise exception 'Report not found'; end if;
end $$;
revoke all on function public.review_social_report(uuid,text) from public;
grant execute on function public.review_social_report(uuid,text) to authenticated;

create or replace function public.list_social_reports()
returns table (
  id uuid, reporter_id uuid, reported_user_id uuid, post_id uuid,
  reason text, details text, status text, created_at timestamptz
)
language plpgsql stable security definer set search_path=public,pg_temp as $$
begin
  if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and role='owner') then
    raise exception 'Owner access required';
  end if;
  return query
    select r.id,r.reporter_id,r.reported_user_id,r.post_id,r.reason,r.details,r.status,r.created_at
    from public.social_reports r
    where r.status in ('open','reviewing')
    order by r.created_at asc
    limit 100;
end $$;
revoke all on function public.list_social_reports() from public;
grant execute on function public.list_social_reports() to authenticated;

create or replace function public.report_social_post(p_post_id uuid, p_reason text, p_details text default '')
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare
  v_author uuid;
  v_report uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_reason not in ('spam','harassment','hate','sexual_content','violence','self_harm','impersonation','other') then
    raise exception 'Invalid report reason';
  end if;
  if char_length(coalesce(p_details,'')) > 1500 then raise exception 'Report details are too long'; end if;
  select author_id into v_author from public.social_posts where id=p_post_id;
  if v_author is null then raise exception 'Post not found'; end if;
  if v_author=auth.uid() then raise exception 'You cannot report your own post'; end if;
  insert into public.social_reports(reporter_id,reported_user_id,post_id,reason,details)
  values(auth.uid(),v_author,p_post_id,p_reason,coalesce(p_details,'')) returning id into v_report;
  return v_report;
end $$;
revoke all on function public.report_social_post(uuid,text,text) from public;
grant execute on function public.report_social_post(uuid,text,text) to authenticated;
