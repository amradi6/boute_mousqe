-- ============================================================
-- مسار العلم — Supabase Database Schema (actual live schema)
-- ============================================================
-- NOTE: The tables below reflect the real DB managed by the admin dashboard.
-- Auth uses user_credentials + Supabase Auth (no profiles table).
-- Disable email confirmation: Authentication → Settings → OFF

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── PROFILES (extends auth.users) ───
CREATE TABLE profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name  TEXT NOT NULL,
  email      TEXT,
  avatar_url TEXT,
  phone      TEXT,
  role       TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'parent')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- ─── HALAQAH GROUPS ───
CREATE TABLE halaqah_groups (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  teacher_id    UUID REFERENCES profiles(id),
  location      TEXT,
  schedule_day  TEXT,
  schedule_time TEXT,
  max_students  INT DEFAULT 20,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE halaqah_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "All authenticated can view groups" ON halaqah_groups FOR SELECT TO authenticated USING (true);
CREATE POLICY "Teachers can manage their groups" ON halaqah_groups FOR ALL USING (auth.uid() = teacher_id);

-- ─── STUDENTS ───
CREATE TABLE students (
  id              UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  group_id        UUID REFERENCES halaqah_groups(id),
  grade_level     TEXT,
  enrollment_date DATE DEFAULT CURRENT_DATE
);

ALTER TABLE students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students can view themselves" ON students FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Teachers can view their students" ON students FOR SELECT TO authenticated
  USING (group_id IN (SELECT id FROM halaqah_groups WHERE teacher_id = auth.uid()));
CREATE POLICY "Teachers can update students" ON students FOR UPDATE TO authenticated
  USING (group_id IN (SELECT id FROM halaqah_groups WHERE teacher_id = auth.uid()));

-- ─── TEACHERS ───
CREATE TABLE teachers (
  id               UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  specialization   TEXT,
  bio              TEXT,
  years_experience INT DEFAULT 0
);

ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated can view teachers" ON teachers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Teachers manage themselves" ON teachers FOR UPDATE USING (auth.uid() = id);

-- ─── PARENTS ───
CREATE TABLE parents (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE
);

-- ─── PARENT-STUDENT RELATIONSHIP ───
CREATE TABLE parent_student (
  parent_id    UUID REFERENCES parents(id) ON DELETE CASCADE,
  student_id   UUID REFERENCES students(id) ON DELETE CASCADE,
  relationship TEXT CHECK (relationship IN ('mother', 'father', 'guardian')),
  PRIMARY KEY (parent_id, student_id)
);

ALTER TABLE parent_student ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents view their children" ON parent_student FOR SELECT TO authenticated USING (auth.uid() = parent_id);

-- ─── LESSONS ───
CREATE TABLE lessons (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id         UUID REFERENCES halaqah_groups(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  content          TEXT,
  lesson_date      DATE NOT NULL,
  duration_minutes INT DEFAULT 60,
  status           TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view lessons" ON lessons FOR SELECT TO authenticated USING (
  group_id IN (
    SELECT id FROM halaqah_groups WHERE teacher_id = auth.uid()
    UNION
    SELECT group_id FROM students WHERE id = auth.uid()
  )
);
CREATE POLICY "Teachers manage lessons" ON lessons FOR ALL TO authenticated
  USING (group_id IN (SELECT id FROM halaqah_groups WHERE teacher_id = auth.uid()));

-- ─── ATTENDANCES ───
CREATE TABLE attendances (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID REFERENCES students(id) ON DELETE CASCADE,
  lesson_id   UUID REFERENCES lessons(id) ON DELETE CASCADE,
  status      TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
  notes       TEXT,
  recorded_by UUID REFERENCES profiles(id),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (student_id, lesson_id)
);

ALTER TABLE attendances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students view own attendance" ON attendances FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "Teachers manage attendance" ON attendances FOR ALL TO authenticated
  USING (lesson_id IN (
    SELECT l.id FROM lessons l
    JOIN halaqah_groups g ON l.group_id = g.id
    WHERE g.teacher_id = auth.uid()
  ));

-- ─── EVALUATIONS ───
CREATE TABLE evaluations (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID REFERENCES students(id) ON DELETE CASCADE,
  teacher_id     UUID REFERENCES teachers(id),
  type           TEXT CHECK (type IN ('memorization', 'recitation', 'understanding', 'behavior')),
  score          NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
  max_score      NUMERIC(5,2) DEFAULT 100,
  notes          TEXT,
  evaluated_date DATE DEFAULT CURRENT_DATE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students view own evaluations" ON evaluations FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "Teachers manage evaluations" ON evaluations FOR ALL TO authenticated USING (teacher_id = auth.uid());
CREATE POLICY "Parents view children evals" ON evaluations FOR SELECT TO authenticated
  USING (student_id IN (SELECT student_id FROM parent_student WHERE parent_id = auth.uid()));

-- ─── NOTIFICATIONS ───
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT DEFAULT 'general',
  is_read    BOOLEAN DEFAULT FALSE,
  data       JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Teachers insert notifications" ON notifications FOR INSERT TO authenticated WITH CHECK (true);

-- ─── TRIGGER: Auto-create profile on signup ───
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─── APP USERS (admin-managed, name-based login) ───
-- Admin inserts rows here. No self-registration.
-- IMPORTANT: Disable email confirmation in Supabase Dashboard →
--   Authentication → Settings → "Enable email confirmations" → OFF
CREATE TABLE app_users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT UNIQUE NOT NULL,
  role         TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'parent')),
  has_password BOOLEAN DEFAULT FALSE,
  auth_user_id UUID UNIQUE REFERENCES auth.users(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
-- Allow anonymous lookup (name + role + has_password only — no auth_user_id in queries)
CREATE POLICY "Public name lookup" ON app_users FOR SELECT USING (true);
-- Allow authenticated update (for setting auth_user_id on first login)
CREATE POLICY "System update on first login" ON app_users FOR UPDATE USING (true);

-- ─── STORAGE BUCKET for avatars ───
-- Run in Supabase Storage section:
-- Create a bucket named "avatars" with public access

-- ─── SAMPLE DATA: add users via admin ───
-- INSERT INTO app_users (name, role) VALUES ('فاطمة أحمد', 'student');
-- INSERT INTO app_users (name, role) VALUES ('أميرة محمد', 'teacher');
-- INSERT INTO app_users (name, role) VALUES ('نورة عبدالله', 'parent');
