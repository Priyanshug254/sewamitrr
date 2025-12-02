-- SewaMitr Database Schema
-- Run this entire file in Supabase SQL Editor

-- ============================================
-- 1. USERS TABLE
-- ============================================

CREATE TABLE users (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  photo_url TEXT,
  language TEXT DEFAULT 'en',
  total_reports INTEGER DEFAULT 0,
  resolved_issues INTEGER DEFAULT 0,
  points INTEGER DEFAULT 0,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, language)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    COALESCE(new.raw_user_meta_data->>'language', 'en')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================
-- 2. ISSUES TABLE
-- ============================================

CREATE TABLE issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT NOT NULL,
  media_urls TEXT[] DEFAULT '{}',
  audio_url TEXT,
  status TEXT DEFAULT 'pending',
  upvotes INTEGER DEFAULT 0,
  progress INTEGER DEFAULT 0,
  assigned_to TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view issues" ON issues
  FOR SELECT USING (true);

CREATE POLICY "Users can create issues" ON issues
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own issues" ON issues
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own issues" ON issues
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. VOTES TABLE
-- ============================================

CREATE TABLE votes (
  id SERIAL PRIMARY KEY,
  issue_id UUID REFERENCES issues(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(issue_id, user_id)
);

-- Enable RLS
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view votes" ON votes
  FOR SELECT USING (true);

CREATE POLICY "Users can create votes" ON votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 4. NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  issue_id UUID REFERENCES issues(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Upvote an issue
CREATE OR REPLACE FUNCTION upvote_issue(issue_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE issues 
  SET upvotes = upvotes + 1 
  WHERE id = issue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Award points for reporting and resolving issues
CREATE OR REPLACE FUNCTION award_points()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET points = points + 10 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE users SET points = points + 50 WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER issue_points_trigger
AFTER INSERT OR UPDATE ON issues
FOR EACH ROW EXECUTE FUNCTION award_points();

-- Get nearby issues (within radius)
CREATE OR REPLACE FUNCTION get_nearby_issues(
  lat DOUBLE PRECISION, 
  lng DOUBLE PRECISION, 
  radius_km DOUBLE PRECISION
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  category TEXT,
  description TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  media_urls TEXT[],
  audio_url TEXT,
  status TEXT,
  upvotes INTEGER,
  progress INTEGER,
  assigned_to TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.*,
    (6371 * acos(
      cos(radians(lat)) * cos(radians(i.latitude)) * 
      cos(radians(i.longitude) - radians(lng)) + 
      sin(radians(lat)) * sin(radians(i.latitude))
    )) AS distance_km
  FROM issues i
  WHERE (6371 * acos(
    cos(radians(lat)) * cos(radians(i.latitude)) * 
    cos(radians(i.longitude) - radians(lng)) + 
    sin(radians(lat)) * sin(radians(i.latitude))
  )) <= radius_km
  ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. STORAGE POLICIES
-- ============================================
-- Run AFTER creating storage bucket "sewamitr" (public)
-- Storage structure: audio/{issue_id}/, issues/{issue_id}/, profiles/

CREATE POLICY "Anyone can view files" ON storage.objects
  FOR SELECT USING (bucket_id = 'sewamitr');

CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'sewamitr' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update files" ON storage.objects
  FOR UPDATE USING (bucket_id = 'sewamitr' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete files" ON storage.objects
  FOR DELETE USING (bucket_id = 'sewamitr' AND auth.role() = 'authenticated');

-- ============================================
-- 7. USER STATS AUTO-UPDATE
-- ============================================

DROP TRIGGER IF EXISTS update_user_stats_trigger ON issues;

CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET total_reports = total_reports + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE users SET resolved_issues = resolved_issues + 1 WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_user_stats_trigger
AFTER INSERT OR UPDATE ON issues
FOR EACH ROW EXECUTE FUNCTION update_user_stats();

-- ============================================
-- 8. COMMUNITY STATS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_community_stats()
RETURNS TABLE (
  total_users INTEGER,
  total_issues INTEGER,
  resolved_issues INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM issues),
    (SELECT COUNT(*)::INTEGER FROM issues),
    (SELECT COUNT(*)::INTEGER FROM issues WHERE status = 'completed');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SETUP COMPLETE
-- ============================================

-- Next steps:
-- 1. Create storage bucket: "sewamitr" (public) in Supabase Storage
-- 2. Copy Project URL and anon key to .env
-- 3. All triggers and functions are now set up automatically!
