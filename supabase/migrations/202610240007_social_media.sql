-- Social post/story private image media.
-- Apply after migrations 003 (social core), 004 (social safety), and 006 (profile media).
alter table public.social_posts add column if not exists media_path text;
alter table public.social_stories add column if not exists media_path text;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('social-media','social-media',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public=false,file_size_limit=8388608,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "Social media owner upload" on storage.objects;
create policy "Social media owner upload" on storage.objects for insert to authenticated
with check (
  bucket_id='social-media'
  and (storage.foldername(name))[1]=auth.uid()::text
  and (storage.foldername(name))[2] is not null
  and (
    exists(select 1 from public.social_posts p
      where p.id::text=(storage.foldername(name))[2] and p.author_id=auth.uid()
        and p.media_path=name and p.status='published')
    or exists(select 1 from public.social_stories s
      where s.id::text=(storage.foldername(name))[2] and s.author_id=auth.uid()
        and s.media_path=name and s.expires_at>now())
  )
);

drop policy if exists "Social media authorized read" on storage.objects;
create policy "Social media authorized read" on storage.objects for select to authenticated
using (
  bucket_id='social-media'
  and (
    exists(select 1 from public.social_posts p
      where p.media_path=name and p.status='published'
        and not public.clario_social_is_blocked(auth.uid(),p.author_id)
        and (
          p.author_id=auth.uid()
          or (p.audience='public' and exists(select 1 from public.profiles pr where pr.id=p.author_id and pr.profile_visibility='public'))
          or (p.audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=p.author_id and f.status='accepted'))
        ))
    or exists(select 1 from public.social_stories s
      where s.media_path=name and s.expires_at>now()
        and not public.clario_social_is_blocked(auth.uid(),s.author_id)
        and (
          s.author_id=auth.uid()
          or (s.audience='public' and exists(select 1 from public.profiles pr where pr.id=s.author_id and pr.profile_visibility='public'))
          or (s.audience='followers' and exists(select 1 from public.social_follows f where f.requester_id=auth.uid() and f.target_id=s.author_id and f.status='accepted'))
        ))
  )
);

drop policy if exists "Social media owner update" on storage.objects;
create policy "Social media owner update" on storage.objects for update to authenticated
using (bucket_id='social-media' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='social-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Social media owner delete" on storage.objects;
create policy "Social media owner delete" on storage.objects for delete to authenticated
using (bucket_id='social-media' and (storage.foldername(name))[1]=auth.uid()::text);

comment on column public.social_posts.media_path is 'Optional private storage path; access governed by social-media storage RLS and post audience.';
comment on column public.social_stories.media_path is 'Optional private storage path; access governed by social-media storage RLS and story audience/expiry.';
