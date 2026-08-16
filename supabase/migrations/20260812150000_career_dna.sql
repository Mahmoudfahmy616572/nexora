-- Career DNA: the canonical, versioned professional identity for each user.
-- Replaces ad-hoc profile stores as the single source of truth for Phases 1-3.
create table if not exists public.career_dna (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  goal text,
  career_stage text,
  target_field text,
  target_role text not null default '',
  target_industry text not null default '',
  preferences jsonb not null default '[]'::jsonb,
  content jsonb not null default '{}'::jsonb,
  skills text[] not null default '{}',
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.career_dna is
  'The user''s evolving professional identity (goal, stage, target, structured profile, skills).';

alter table public.career_dna enable row level security;

create policy "career_dna is selectable by owner"
  on public.career_dna for select
  using (auth.uid() = user_id);

create policy "career_dna is insertable by owner"
  on public.career_dna for insert
  with check (auth.uid() = user_id);

create policy "career_dna is updatable by owner"
  on public.career_dna for update
  using (auth.uid() = user_id);

-- Version history of the Career DNA so the platform can show evolution.
create table if not exists public.career_dna_versions (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  version integer not null,
  goal text,
  career_stage text,
  target_field text,
  target_role text not null default '',
  target_industry text not null default '',
  preferences jsonb not null default '[]'::jsonb,
  content jsonb not null default '{}'::jsonb,
  skills text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists career_dna_versions_user_idx
  on public.career_dna_versions(user_id, created_at desc);

alter table public.career_dna_versions enable row level security;

create policy "career_dna_versions is selectable by owner"
  on public.career_dna_versions for select
  using (auth.uid() = user_id);

create policy "career_dna_versions is insertable by owner"
  on public.career_dna_versions for insert
  with check (auth.uid() = user_id);
