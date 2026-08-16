-- Career data: the four feature tables behind the main app tabs.
-- Each row belongs to exactly one user and Row Level Security guarantees
-- users only ever read, write, or delete their own rows.
--
--   job_applications  <- Tracker tab
--   job_analyses      <- Analyze tab
--   cvs               <- Studio tab
--   profile_sections  <- DNA tab (only user-added sections are stored; the
--                        base section list is product content, not data)

create table if not exists public.job_applications (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  company text not null default '',
  role text not null default '',
  status text not null default 'Applied',
  date text not null default '',
  match int not null default 0,
  ats int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.job_analyses (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default '',
  company text not null default '',
  time_ago text not null default '',
  overall double precision not null default 0,
  skills double precision not null default 0,
  experience double precision not null default 0,
  education double precision not null default 0,
  keywords double precision not null default 0,
  strong text[] not null default '{}',
  missing text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.cvs (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default '',
  ats int not null default 0,
  purpose text not null default '',
  updated text not null default '',
  match int not null default 0,
  best boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.profile_sections (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  label text not null default '',
  pct double precision not null default 0,
  category text not null default 'v',
  created_at timestamptz not null default now()
);

-- RLS: enable on every table.
alter table public.job_applications enable row level security;
alter table public.job_analyses enable row level security;
alter table public.cvs enable row level security;
alter table public.profile_sections enable row level security;

-- Helper: emit the four CRUD policies for a table.
do $$
declare
  t text;
begin
  foreach t in array array['job_applications', 'job_analyses', 'cvs', 'profile_sections']
  loop
    execute format(
      'create policy "Users can view own %1$s" on public.%1$s for select using (auth.uid() = user_id);', t);
    execute format(
      'create policy "Users can insert own %1$s" on public.%1$s for insert with check (auth.uid() = user_id);', t);
    execute format(
      'create policy "Users can update own %1$s" on public.%1$s for update using (auth.uid() = user_id) with check (auth.uid() = user_id);', t);
    execute format(
      'create policy "Users can delete own %1$s" on public.%1$s for delete using (auth.uid() = user_id);', t);
  end loop;
end $$;
