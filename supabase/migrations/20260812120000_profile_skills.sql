-- Real user profile data for AI matching: the candidate's declared skills.
alter table public.profiles
  add column if not exists skills text[] not null default '{}';
