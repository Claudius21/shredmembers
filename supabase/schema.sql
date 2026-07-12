-- ============================================================
-- shredMembers – Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─── Profiles (extends auth.users) ───────────────────────────
create table public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  name             text not null default '',
  goal             text not null default 'buildMuscle',
  weekly_target    int  not null default 4,
  active_plan_id   text,
  avatar_url       text,
  gender           text,
  height_cm        numeric(5,1),
  weight_kg        numeric(5,1),
  created_at       timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── Workout Plans ────────────────────────────────────────────
create table public.workout_plans (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid not null references public.profiles(id) on delete cascade,
  name           text not null,
  description    text not null default '',
  difficulty     text not null default 'intermediate',
  duration_weeks int  not null default 8,
  is_active      boolean not null default false,
  is_template    boolean not null default false,
  created_at     timestamptz not null default now()
);

alter table public.workout_plans enable row level security;

create policy "Users manage own plans"
  on public.workout_plans for all
  using (auth.uid() = user_id);

-- ─── Workout Days ─────────────────────────────────────────────
create table public.workout_days (
  id           uuid primary key default uuid_generate_v4(),
  plan_id      uuid not null references public.workout_plans(id) on delete cascade,
  name         text not null,
  day_of_week  int  not null default 1,
  sort_order   int  not null default 0
);

alter table public.workout_days enable row level security;

create policy "Users manage own days"
  on public.workout_days for all
  using (
    exists (
      select 1 from public.workout_plans p
      where p.id = plan_id and p.user_id = auth.uid()
    )
  );

-- ─── Exercises (global catalogue) ────────────────────────────
create table public.exercises (
  id           uuid primary key default uuid_generate_v4(),
  name         text not null,
  muscle_group text not null,
  description  text,
  created_at   timestamptz not null default now()
);

-- Public read access for exercise catalogue
alter table public.exercises enable row level security;
create policy "Anyone can read exercises"
  on public.exercises for select using (true);

-- ─── Day Exercises (exercises within a day) ───────────────────
create table public.day_exercises (
  id           uuid primary key default uuid_generate_v4(),
  day_id       uuid not null references public.workout_days(id) on delete cascade,
  exercise_id  uuid not null references public.exercises(id),
  sort_order   int  not null default 0,
  sets         int  not null default 3,
  target_reps  int  not null default 10,
  target_weight numeric(6,2) not null default 0,
  rest_seconds int  not null default 90
);

alter table public.day_exercises enable row level security;

create policy "Users manage own day exercises"
  on public.day_exercises for all
  using (
    exists (
      select 1 from public.workout_days d
      join public.workout_plans p on p.id = d.plan_id
      where d.id = day_id and p.user_id = auth.uid()
    )
  );

-- ─── Workout Sessions ─────────────────────────────────────────
create table public.workout_sessions (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  plan_id         uuid references public.workout_plans(id) on delete set null,
  day_id          uuid references public.workout_days(id) on delete set null,
  day_name        text not null,
  started_at                 timestamptz not null default now(),
  finished_at                timestamptz,
  started_at_offset_minutes  int,
  finished_at_offset_minutes int,
  status                     text not null default 'completed',
  total_volume_kg int  not null default 0,
  session_type    text not null default 'strength',
  cardio_minutes  int,
  distance_km     numeric(6,2),
  calories_burned int
);

alter table public.workout_sessions enable row level security;

create policy "Users manage own sessions"
  on public.workout_sessions for all
  using (auth.uid() = user_id);

-- ─── Session Sets (logged sets per session) ───────────────────
create table public.session_sets (
  id           uuid primary key default uuid_generate_v4(),
  session_id   uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id  uuid references public.exercises(id),
  exercise_name text not null,
  set_number   int  not null,
  reps         int,
  weight_kg    numeric(6,2),
  is_completed boolean not null default false
);

alter table public.session_sets enable row level security;

create policy "Users manage own session sets"
  on public.session_sets for all
  using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id and s.user_id = auth.uid()
    )
  );

-- ─── Personal Records ─────────────────────────────────────────
create table public.personal_records (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  exercise_id  text not null,
  exercise_ref text,
  exercise_name text not null,
  weight_kg    numeric(6,2) not null,
  reps         int not null,
  achieved_at  timestamptz not null default now()
);

alter table public.personal_records enable row level security;

create policy "Users manage own PRs"
  on public.personal_records for all
  using (auth.uid() = user_id);

-- ─── Seed: Exercise Catalogue ─────────────────────────────────
insert into public.exercises (id, name, muscle_group, description) values
  ('00000000-0000-0000-0000-000000000001', 'Bench Press',             'chest',     'Classic compound chest exercise. Keep elbows at 75°.'),
  ('00000000-0000-0000-0000-000000000002', 'Incline Dumbbell Press',  'chest',     'Targets upper chest. Set bench to 30-45°.'),
  ('00000000-0000-0000-0000-000000000003', 'Cable Flyes',             'chest',     'Isolation movement. Focus on the squeeze at peak.'),
  ('00000000-0000-0000-0000-000000000004', 'Deadlift',                'back',      'King of compound movements. Neutral spine throughout.'),
  ('00000000-0000-0000-0000-000000000005', 'Pull-Ups',                'back',      'Full range of motion. Dead hang at bottom.'),
  ('00000000-0000-0000-0000-000000000006', 'Barbell Row',             'back',      'Hinge at hip, row to lower chest.'),
  ('00000000-0000-0000-0000-000000000007', 'Squat',                   'legs',      'Break parallel, knees track over toes.'),
  ('00000000-0000-0000-0000-000000000008', 'Romanian Deadlift',       'legs',      'Hip hinge, soft knee bend, stretch hamstrings.'),
  ('00000000-0000-0000-0000-000000000009', 'Leg Press',               'legs',      'Full range. Feet hip-width apart.'),
  ('00000000-0000-0000-0000-000000000010', 'Walking Lunges',          'legs',      'Keep torso upright, knee doesn''t touch ground.'),
  ('00000000-0000-0000-0000-000000000011', 'Overhead Press',          'shoulders', 'Press bar directly overhead, full lockout.'),
  ('00000000-0000-0000-0000-000000000012', 'Lateral Raises',          'shoulders', 'Control the negative, slight forward lean.'),
  ('00000000-0000-0000-0000-000000000013', 'Face Pulls',              'shoulders', 'Pull to face level, external rotation.'),
  ('00000000-0000-0000-0000-000000000014', 'Plank',                   'core',      'Neutral spine, don''t let hips sag.'),
  ('00000000-0000-0000-0000-000000000015', 'Hanging Leg Raises',      'core',      'Control the movement, avoid swinging.');

-- ─── Subscription Plans ───────────────────────────────────────
create table if not exists public.subscription_plans (
  id                      uuid primary key default uuid_generate_v4(),
  name                    text not null,
  description             text,
  stripe_monthly_price_id text,
  stripe_yearly_price_id  text,
  monthly_price_eur       numeric(8,2),
  yearly_price_eur        numeric(8,2),
  features                jsonb default '[]',
  is_active               boolean not null default true,
  created_at              timestamptz not null default now()
);

-- ─── User Subscriptions ───────────────────────────────────────
create table if not exists public.subscriptions (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  plan_id              uuid references public.subscription_plans(id),
  stripe_customer_id   text,
  stripe_subscription_id text,
  status               text not null default 'free',  -- free | active | canceled | past_due
  price_type           text default 'monthly',        -- monthly | yearly
  current_period_start timestamptz,
  current_period_end   timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique(user_id)
);

-- ─── Discount Codes ───────────────────────────────────────────
create table if not exists public.discount_codes (
  id               uuid primary key default uuid_generate_v4(),
  code             text not null unique,
  stripe_coupon_id text,
  discount_percent int,
  max_uses         int,
  current_uses     int not null default 0,
  valid_from       timestamptz not null default now(),
  valid_until      timestamptz,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

-- RLS
alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.discount_codes enable row level security;

create policy "Anyone can read plans"    on public.subscription_plans for select using (true);
create policy "Users read own sub"       on public.subscriptions for select using (auth.uid() = user_id);
create policy "Users insert own sub"     on public.subscriptions for insert with check (auth.uid() = user_id);
create policy "Users update own sub"     on public.subscriptions for update using (auth.uid() = user_id);
create policy "Anyone can read codes"    on public.discount_codes for select using (true);

-- Auto-create trial subscription on signup
create or replace function public.handle_new_subscription()
returns trigger language plpgsql security definer as $$
begin
  insert into public.subscriptions (user_id, plan_id, status)
  values (
    new.id,
    (select id from public.subscription_plans limit 1),
    'trial'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create or replace trigger on_auth_user_created_subscription
  after insert on auth.users
  for each row execute procedure public.handle_new_subscription();

-- ─── Default Subscription Plan ────────────────────────────────
-- Note: Full subscription schema is in supabase/migrations/add_subscription_system.sql
-- Run that migration first, then the plan is already inserted there.
