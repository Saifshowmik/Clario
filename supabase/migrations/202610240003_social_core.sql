-- Clario social core: follow requests, posts, reactions, comments, blocks, and stories.
-- Storage uploads and media URL signing are intentionally separate; do not store private media URLs here.
create table if not exists public.social_follows (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  target_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint social_follows_not_self check (requester_id <> target_id),
  constraint social_follows_pair_unique unique (requester_id,target_id)
);
create table if not exists public.social_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id,blocked_id),
  constraint social_blocks_not_self check (blocker_id <> blocked_id)
);
create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 3000),
  audience text not null default 'followers' check (audience in ('public','followers','private')),
  status text not null default 'published' check (status in ('published','archived','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.social_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1500),
  created_at timestamptz not null default now()
);
create table if not exists public.social_reactions (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction text not null default 'like' check (reaction in ('like','love','support','insightful')),
  created_at timestamptz not null default now(),
  primary key (post_id,user_id)
);
create table if not exists public.social_stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  text_content text not null default '' check (char_length(text_content) <= 1000),
  audience text not null default 'followers' check (audience in ('public','followers','private')),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now()
);

-- Public profile discovery is explicit; private profiles remain visible only to self/owner and accepted followers.
drop policy if exists profiles_social_read on public.profiles;
create policy profiles_social_read on public.profiles for select to authenticated
using (
  id=auth.uid()
  or profile_visibility='public'
  or (profile_visibility='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=public.profiles.id and f.status='accepted'))
);

create or replace function public.clario_guard_follow_identity()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if new.requester_id is distinct from old.requester_id or new.target_id is distinct from old.target_id then
    raise exception 'Follow request participants cannot be changed';
  end if;
  if auth.uid() is not null and auth.uid() <> old.target_id then
    raise exception 'Only the requested account can accept or reject a follow request';
  end if;
  return new;
end $$;
revoke all on function public.clario_guard_follow_identity() from public;
grant execute on function public.clario_guard_follow_identity() to authenticated;
drop trigger if exists clario_guard_follow_identity on public.social_follows;
create trigger clario_guard_follow_identity before update on public.social_follows
for each row execute function public.clario_guard_follow_identity();

create or replace function public.clario_social_is_blocked(p_user_a uuid, p_user_b uuid)
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists(select 1 from public.social_blocks b
    where (b.blocker_id=p_user_a and b.blocked_id=p_user_b)
       or (b.blocker_id=p_user_b and b.blocked_id=p_user_a));
$$;
revoke all on function public.clario_social_is_blocked(uuid,uuid) from public;
grant execute on function public.clario_social_is_blocked(uuid,uuid) to authenticated;

create index if not exists social_posts_author_created_idx on public.social_posts(author_id,created_at desc);
create index if not exists social_posts_feed_idx on public.social_posts(status,audience,created_at desc);
create index if not exists social_comments_post_created_idx on public.social_comments(post_id,created_at);
create index if not exists social_stories_expiry_idx on public.social_stories(expires_at);
alter table public.social_follows enable row level security;
alter table public.social_blocks enable row level security;
alter table public.social_posts enable row level security;
alter table public.social_comments enable row level security;
alter table public.social_reactions enable row level security;
alter table public.social_stories enable row level security;

-- Avoid exposing block lists. A user can only manage their own block rows.
create policy social_blocks_read_own on public.social_blocks for select to authenticated using (blocker_id=auth.uid());
create policy social_blocks_insert_own on public.social_blocks for insert to authenticated with check (blocker_id=auth.uid());
create policy social_blocks_delete_own on public.social_blocks for delete to authenticated using (blocker_id=auth.uid());

create policy social_follows_read_participants on public.social_follows for select to authenticated
using (requester_id=auth.uid() or target_id=auth.uid());
create policy social_follows_request_own on public.social_follows for insert to authenticated
with check (requester_id=auth.uid() and not public.clario_social_is_blocked(auth.uid(),target_id));
create policy social_follows_update_target on public.social_follows for update to authenticated
using (target_id=auth.uid()) with check (target_id=auth.uid() and status in ('accepted','rejected'));
create policy social_follows_delete_participant on public.social_follows for delete to authenticated
using (requester_id=auth.uid() or target_id=auth.uid());

-- Private profiles remain invisible to non-followers. Accepted followers can see followers-only posts.
create policy social_posts_read_audience on public.social_posts for select to authenticated
using (
  status='published'
  and not public.clario_social_is_blocked(auth.uid(),author_id)
  and (
    author_id=auth.uid()
    or (audience='public' and exists(select 1 from public.profiles p where p.id=author_id and p.profile_visibility='public'))
    or (audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=author_id and f.status='accepted'))
  )
);
create policy social_posts_insert_own on public.social_posts for insert to authenticated
with check (author_id=auth.uid());
create policy social_posts_update_own on public.social_posts for update to authenticated
using (author_id=auth.uid()) with check (author_id=auth.uid());
create policy social_posts_delete_own on public.social_posts for delete to authenticated using (author_id=auth.uid());

create policy social_comments_read_visible_post on public.social_comments for select to authenticated
using (exists(select 1 from public.social_posts p where p.id=post_id));
create policy social_comments_insert_visible_post on public.social_comments for insert to authenticated
with check (author_id=auth.uid() and exists(select 1 from public.social_posts p where p.id=post_id));
create policy social_comments_delete_own on public.social_comments for delete to authenticated using (author_id=auth.uid());

create policy social_reactions_read_visible_post on public.social_reactions for select to authenticated
using (exists(select 1 from public.social_posts p where p.id=post_id));
create policy social_reactions_insert_own on public.social_reactions for insert to authenticated
with check (user_id=auth.uid() and exists(select 1 from public.social_posts p where p.id=post_id));
create policy social_reactions_delete_own on public.social_reactions for delete to authenticated using (user_id=auth.uid());

create policy social_stories_read_active_audience on public.social_stories for select to authenticated
using (
  expires_at > now()
  and not public.clario_social_is_blocked(auth.uid(),author_id)
  and (
    author_id=auth.uid()
    or (audience='public' and exists(select 1 from public.profiles p where p.id=author_id and p.profile_visibility='public'))
    or (audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=author_id and f.status='accepted'))
  )
);
create policy social_stories_insert_own on public.social_stories for insert to authenticated with check (author_id=auth.uid());
create policy social_stories_delete_own on public.social_stories for delete to authenticated using (author_id=auth.uid());

comment on table public.social_posts is 'Text-only social posts foundation. Add signed media storage and moderation before enabling media uploads.';
comment on table public.social_stories is 'Stories expire after 24 hours; client queries must filter expires_at > now().';
