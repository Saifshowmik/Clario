\set ON_ERROR_STOP on
-- Migration should create a private bucket with the configured MIME/size restrictions.
do $$
begin
  if not exists (
    select 1 from storage.buckets
    where id='profile-media' and public=false and file_size_limit=5242880
      and allowed_mime_types=array['image/jpeg','image/png','image/webp']
  ) then raise exception 'Private profile-media bucket configuration is missing'; end if;
  if (select count(*) from pg_policies where schemaname='storage' and tablename='objects'
      and policyname in ('Profile media owner read','Profile media owner upload','Profile media owner update','Profile media owner delete')) <> 4
  then raise exception 'Expected four owner-scoped storage policies'; end if;
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='avatar_path')
     or not exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='cover_path')
  then raise exception 'Profile media path fields are missing'; end if;
end $$;
-- Seed a file in another member's folder, then prove a regular user cannot read it.
insert into storage.objects(bucket_id,name) values
 ('profile-media','10000000-0000-4000-8000-000000000003/avatar.png');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
set role authenticated;
do $$
declare n integer;
begin
  select count(*) into n from storage.objects
   where bucket_id='profile-media' and name='10000000-0000-4000-8000-000000000003/avatar.png';
  if n <> 0 then raise exception 'A user can read another member''s private profile media'; end if;
end $$;
reset role;
