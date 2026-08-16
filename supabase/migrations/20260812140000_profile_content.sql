-- Real, structured career profile data — the single source of truth for AI
-- match scoring. One row per user.
create table if not exists public.profile_content (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  summary text not null default '',
  experience jsonb not null default '[]'::jsonb,
  projects jsonb not null default '[]'::jsonb,
  education jsonb not null default '[]'::jsonb,
  certifications jsonb not null default '[]'::jsonb,
  achievements jsonb not null default '[]'::jsonb,
  languages jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.profile_content enable row level security;

create policy "profile content is selectable by owner"
  on public.profile_content for select
  using (auth.uid() = user_id);

create policy "profile content is insertable by owner"
  on public.profile_content for insert
  with check (auth.uid() = user_id);

create policy "profile content is updatable by owner"
  on public.profile_content for update
  using (auth.uid() = user_id);

create policy "profile content is deletable by owner"
  on public.profile_content for delete
  using (auth.uid() = user_id);
