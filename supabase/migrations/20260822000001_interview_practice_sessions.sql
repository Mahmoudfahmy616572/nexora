-- Interview Practice Coach sessions (Phase 5): the practice runs a user
-- performs against their Interview Readiness plan, with deterministic scoring
-- and (optionally) AI coaching. Additive schema only — no changes to existing
-- tables. Raw AI responses are NOT persisted; only the deterministic scoring
-- and any model-authored coaching sketch live in `turns` (jsonb).
create table if not exists public.interview_practice_sessions (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_id text,
  application_id text,
  analysis_id text,
  role text,
  company text,
  status text not null default 'inProgress',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  question_count integer not null default 0,
  answered_count integer not null default 0,
  completed_count integer not null default 0,
  relevance_score integer not null default 0,
  specificity_score integer not null default 0,
  structure_score integer not null default 0,
  profile_consistency_score integer not null default 0,
  overall_score integer not null default 0,
  recommended_next_area text,
  focus_areas jsonb not null default '[]'::jsonb,
  turns jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.interview_practice_sessions is
  'Interview Practice Coach sessions: role-specific mock-interview runs with '
  'deterministic scoring and optional AI coaching.';

create index if not exists interview_practice_sessions_user_idx
  on public.interview_practice_sessions(user_id, started_at desc);

alter table public.interview_practice_sessions enable row level security;

create policy "interview_practice_sessions is selectable by owner"
  on public.interview_practice_sessions for select
  using (auth.uid() = user_id);

create policy "interview_practice_sessions is insertable by owner"
  on public.interview_practice_sessions for insert
  with check (auth.uid() = user_id);

create policy "interview_practice_sessions is updatable by owner"
  on public.interview_practice_sessions for update
  using (auth.uid() = user_id);

create policy "interview_practice_sessions is deletable by owner"
  on public.interview_practice_sessions for delete
  using (auth.uid() = user_id);
