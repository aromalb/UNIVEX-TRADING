-- =====================================================================
--  Univex Trade Docs - Supabase database setup
--  Paste this whole file into Supabase > SQL Editor > New query > Run.
--  Safe to run more than once.
-- =====================================================================

-- 1. PROFILES: one row per login, holding the person's name and role
--    Roles: admin  = everything, including company settings and user roles
--           staff  = create and edit orders, products, parties, BOEs
--           viewer = read and download documents only
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  full_name   text default '',
  role        text not null default 'staff' check (role in ('admin','staff','viewer')),
  created_at  timestamptz not null default now()
);

-- 2. APP DATA: every order, product, party, BOE entry and the company settings
create table if not exists public.app_docs (
  collection  text not null check (collection in ('orders','products','parties','boes','config')),
  id          text not null,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id) on delete set null default auth.uid(),
  primary key (collection, id)
);

-- 3. Helper: the signed-in person's role
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- 4. Create a profile automatically for every new login.
--    The very first account becomes admin; everyone after that starts as staff.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    case when exists (select 1 from public.profiles where role = 'admin') then 'staff' else 'admin' end
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Add profiles for any logins created before this script was run
insert into public.profiles (id, email, created_at)
select id, email, created_at from auth.users
on conflict (id) do nothing;

-- Make sure at least one admin exists (the oldest account)
update public.profiles set role = 'admin'
where id = (select id from public.profiles order by created_at limit 1)
  and not exists (select 1 from public.profiles where role = 'admin');

-- 5. Stamp who changed each record and when
create or replace function public.touch_app_doc()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  return new;
end $$;

drop trigger if exists app_docs_touch on public.app_docs;
create trigger app_docs_touch
  before insert or update on public.app_docs
  for each row execute function public.touch_app_doc();

-- 6. SECURITY (Row Level Security): nobody can read or write without logging in
alter table public.profiles enable row level security;
alter table public.app_docs enable row level security;

drop policy if exists "profiles read"          on public.profiles;
drop policy if exists "profiles admin update"  on public.profiles;
drop policy if exists "docs read"              on public.app_docs;
drop policy if exists "docs insert"            on public.app_docs;
drop policy if exists "docs update"            on public.app_docs;
drop policy if exists "docs delete"            on public.app_docs;

-- Everyone logged in can see the team list
create policy "profiles read" on public.profiles
  for select to authenticated using (true);

-- Only admins can change names and roles
create policy "profiles admin update" on public.profiles
  for update to authenticated
  using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- Any team member can read the data
create policy "docs read" on public.app_docs
  for select to authenticated using (public.my_role() is not null);

-- Staff and admins can write; company settings ('config') are admin-only
create policy "docs insert" on public.app_docs
  for insert to authenticated
  with check (
    (collection <> 'config' and public.my_role() in ('admin','staff'))
    or (collection = 'config' and public.my_role() = 'admin')
  );

create policy "docs update" on public.app_docs
  for update to authenticated
  using (
    (collection <> 'config' and public.my_role() in ('admin','staff'))
    or (collection = 'config' and public.my_role() = 'admin')
  )
  with check (
    (collection <> 'config' and public.my_role() in ('admin','staff'))
    or (collection = 'config' and public.my_role() = 'admin')
  );

create policy "docs delete" on public.app_docs
  for delete to authenticated
  using (
    (collection <> 'config' and public.my_role() in ('admin','staff'))
    or (collection = 'config' and public.my_role() = 'admin')
  );

-- 7. LIVE UPDATES: changes appear instantly on every open screen
do $$
begin
  begin
    alter publication supabase_realtime add table public.app_docs;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.profiles;
  exception when duplicate_object then null;
  end;
end $$;

-- Done. Check: Table Editor should now show "profiles" and "app_docs".
