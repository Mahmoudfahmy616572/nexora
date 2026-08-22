-- Job Applications: the opportunities a user has actually applied to and is
-- tracking on the Tracker tab (status pipeline, match/ATS scores).
-- Additive schema only — no changes to existing tables.
create table if not exists public.job_applications (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  company text not null,
  role text not null,
  status text not null default 'Applied',
  date text not null default '',
  "match" integer not null default 0,
  ats integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.job_applications is
  'The job applications a user is tracking (Tracker tab): company, role, status pipeline, match/ATS scores.';

create index if not exists job_applications_user_idx
  on public.job_applications(user_id, created_at desc);

alter table public.job_applications enable row level security;

create policy "job_applications is selectable by owner"
  on public.job_applications for select
  using (auth.uid() = user_id);

create policy "job_applications is insertable by owner"
  on public.job_applications for insert
  with check (auth.uid() = user_id);

create policy "job_applications is updatable by owner"
  on public.job_applications for update
  using (auth.uid() = user_id);

create policy "job_applications is deletable by owner"
  on public.job_applications for delete
  using (auth.uid() = user_id);
