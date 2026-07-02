-- Add timezone offset columns to workout_sessions so we can reconstruct the
-- local time of the workout in the timezone it was originally performed.
alter table public.workout_sessions
  add column if not exists started_at_offset_minutes int,
  add column if not exists finished_at_offset_minutes int;
