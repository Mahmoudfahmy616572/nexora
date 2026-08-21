-- Phase 2C (Opportunity Intelligence): extend job_analyses with the rich,
-- explainable analysis detail and an optional link to a Career Target.
--
-- This migration is ADDITIVE: it only adds columns and an index. Existing rows
-- and the existing owner-based RLS policies (defined in 20260812090000) continue
-- to apply, so no data migration or policy change is required.
--
-- NOTE: this migration is NOT deployed yet. It must be applied with
-- `supabase db push` (or via the Supabase CLI migration runner) before the
-- enriched detail is persisted server-side. Until then the app uses the
-- SharedPreferences fallback and stores detail in the offline row payload.

alter table public.job_analyses
  add column if not exists target_id uuid references public.career_targets (id) on delete cascade,
  add column if not exists job_description text not null default '',
  add column if not exists detail jsonb not null default '{}'::jsonb;

-- Speed up the Analyze history query (newest first) per user.
create index if not exists job_analyses_user_idx
  on public.job_analyses (user_id, created_at desc);
