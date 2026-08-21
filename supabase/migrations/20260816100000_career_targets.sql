-- Career Targets: the specific opportunities a user is preparing for
-- (jobs, internships, graduate programs, academic applications, custom).
-- Additive schema only — no changes to existing tables.
create table if not exists public.career_targets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null default 'custom',
  role text not null,
  industry text,
  country_region text,
  seniority text,
  language text,
  job_description text,
  company text,
  url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.career_targets is
  'The specific opportunities a user is targeting (job, internship, graduate program, academic application, custom).';

create index if not exists career_targets_user_idx
  on public.career_targets(user_id, created_at desc);

alter table public.career_targets enable row level security;

create policy "career_targets is selectable by owner"
  on public.career_targets for select
  using (auth.uid() = user_id);

create policy "career_targets is insertable by owner"
  on public.career_targets for insert
  with check (auth.uid() = user_id);

create policy "career_targets is updatable by owner"
  on public.career_targets for update
  using (auth.uid() = user_id);

create policy "career_targets is deletable by owner"
  on public.career_targets for delete
  using (auth.uid() = user_id);
