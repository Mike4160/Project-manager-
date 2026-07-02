-- Electrical Project Manager schema
-- Run this in a separate Supabase project or database from the material tracking app.

create table if not exists pm_contacts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  created_at timestamptz not null default now()
);

create table if not exists pm_jobs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  customer text,
  job_number text,
  start_date date,
  due_date date,
  status text not null default 'Active',
  manager_id uuid references pm_contacts(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists pm_folder_items (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references pm_jobs(id) on delete cascade,
  folder text not null default 'Other',
  title text not null,
  status text not null default 'Needed',
  item_date date,
  link text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists pm_materials (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references pm_jobs(id) on delete cascade,
  material text not null,
  quantity text not null,
  unit text,
  needed_by date,
  status text not null default 'Needed',
  vendor text,
  po_number text,
  created_at timestamptz not null default now()
);

create table if not exists pm_tasks (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references pm_jobs(id) on delete cascade,
  title text not null,
  assignee text,
  due_date date,
  priority text not null default 'Normal',
  status text not null default 'Open',
  created_at timestamptz not null default now()
);

alter table pm_contacts enable row level security;
alter table pm_jobs enable row level security;
alter table pm_folder_items enable row level security;
alter table pm_materials enable row level security;
alter table pm_tasks enable row level security;

drop policy if exists "pm_contacts all" on pm_contacts;
drop policy if exists "pm_jobs all" on pm_jobs;
drop policy if exists "pm_folder_items all" on pm_folder_items;
drop policy if exists "pm_materials all" on pm_materials;
drop policy if exists "pm_tasks all" on pm_tasks;

create policy "pm_contacts all" on pm_contacts for all using (true) with check (true);
create policy "pm_jobs all" on pm_jobs for all using (true) with check (true);
create policy "pm_folder_items all" on pm_folder_items for all using (true) with check (true);
create policy "pm_materials all" on pm_materials for all using (true) with check (true);
create policy "pm_tasks all" on pm_tasks for all using (true) with check (true);

insert into pm_contacts (name, email)
select 'Project Manager', 'pm@example.com'
where not exists (select 1 from pm_contacts where email = 'pm@example.com');


-- Storage bucket for actual project files.
-- Public bucket keeps file links easy to open from the job folders.
insert into storage.buckets (id, name, public)
values ('project-manager-files', 'project-manager-files', true)
on conflict (id) do update set public = true;

drop policy if exists "project manager files read" on storage.objects;
drop policy if exists "project manager files insert" on storage.objects;
drop policy if exists "project manager files update" on storage.objects;
drop policy if exists "project manager files delete" on storage.objects;

create policy "project manager files read" on storage.objects
for select using (bucket_id = 'project-manager-files');

create policy "project manager files insert" on storage.objects
for insert with check (bucket_id = 'project-manager-files');

create policy "project manager files update" on storage.objects
for update using (bucket_id = 'project-manager-files') with check (bucket_id = 'project-manager-files');

create policy "project manager files delete" on storage.objects
for delete using (bucket_id = 'project-manager-files');
