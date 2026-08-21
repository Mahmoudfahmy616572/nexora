-- Phase 2D CV Engine — additive tables only.
-- No existing tables or columns are altered or dropped.
-- Intentionally NOT deployed; mirrors Phase 2B/2C practice.

create table if not exists public.cv_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  target_id uuid not null references public.career_targets (id) on delete cascade,
  template_id text not null default 'nexoraMinimal',
  title text not null default 'CV',
  analysis_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists cv_documents_user_idx on public.cv_documents (user_id);
create index if not exists cv_documents_target_idx on public.cv_documents (target_id);

create table if not exists public.cv_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.cv_documents (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  version integer not null default 1,
  content jsonb not null default '{}'::jsonb,
  template_id text not null default 'nexoraMinimal',
  evaluation_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists cv_versions_document_idx on public.cv_versions (document_id);
create index if not exists cv_versions_user_idx on public.cv_versions (user_id);

alter table public.cv_documents enable row level security;
alter table public.cv_versions enable row level security;

drop policy if exists "cv_documents_owner" on public.cv_documents;
create policy "cv_documents_owner" on public.cv_documents
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cv_versions_owner" on public.cv_versions;
create policy "cv_versions_owner" on public.cv_versions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
