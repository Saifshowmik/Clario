-- Private profile media: users can upload only to their own folder.
alter table public.profiles
  add column if not exists avatar_path text,
  add column if not exists cover_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-media', 'profile-media', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public=false, file_size_limit=5242880, allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "Profile media owner read" on storage.objects;
create policy "Profile media owner read"
on storage.objects for select to authenticated
using (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Profile media owner upload" on storage.objects;
create policy "Profile media owner upload"
on storage.objects for insert to authenticated
with check (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Profile media owner update" on storage.objects;
create policy "Profile media owner update"
on storage.objects for update to authenticated
using (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Profile media owner delete" on storage.objects;
create policy "Profile media owner delete"
on storage.objects for delete to authenticated
using (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);
