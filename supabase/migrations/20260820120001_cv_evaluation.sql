-- Phase 2E: CV Evaluation + ATS + Improvement Loop.
-- ADDITIVE ONLY: does not modify or drop any Phase 2D tables.
-- Intentionally NOT deployed by this change.

create table if not exists public.cv_evaluations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  version_id uuid not null references public.cv_versions (id) on delete cascade,
  target_id text not null default '',
  overall int not null default 0,
  ats int not null default 0,
  target_alignment int not null default 0,
  content_strength int not null default 0,
  evidence_strength int not null default 0,
  readability int not null default 0,
  clarity int not null default 0,
  structure int not null default 0,
  keyword_alignment int not null default 0,
  skill_alignment int not null default 0,
  section_completeness int not null default 0,
  explanations jsonb not null default '{}'::jsonb,
  deterministic_only boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists cv_evaluations_user_idx
  on public.cv_evaluations (user_id);
create index if not exists cv_evaluations_version_idx
  on public.cv_evaluations (version_id);

create table if not exists public.cv_suggestions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  evaluation_id uuid not null references public.cv_evaluations (id) on delete cascade,
  version_id uuid not null,
  section text not null default '',
  problem text not null default '',
  current text not null default '',
  suggested text not null default '',
  why text not null default '',
  target_requirement text not null default '',
  status text not null default 'pending',
  edited_text text,
  created_at timestamptz not null default now()
);

create index if not exists cv_suggestions_user_idx
  on public.cv_suggestions (user_id);
create index if not exists cv_suggestions_evaluation_idx
  on public.cv_suggestions (evaluation_id);

alter table public.cv_evaluations enable row level security;
alter table public.cv_suggestions enable row level security;

drop policy if exists "cv_evaluations_owner" on public.cv_evaluations;
create policy "cv_evaluations_owner" on public.cv_evaluations
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "cv_suggestions_owner" on public.cv_suggestions;
create policy "cv_suggestions_owner" on public.cv_suggestions
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
