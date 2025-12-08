-- ============================================================================
-- ADD MISSING FLUTTER APP FEATURES
-- This adds features from db.sql that are missing in the main schema
-- Run this in Supabase SQL Editor AFTER running all migrations
-- ============================================================================

-- ============================================
-- 1. ADD COMPLETED_AT COLUMN
-- ============================================
ALTER TABLE public.issues 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

UPDATE public.issues 
SET completed_at = updated_at 
WHERE (status = 'completed' OR status = 'resolved') 
AND completed_at IS NULL;

COMMENT ON COLUMN public.issues.completed_at IS 'Timestamp when issue was marked as completed/resolved';

-- ============================================
-- 2. COMMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id UUID REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_issue_id ON public.comments(issue_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comments
DROP POLICY IF EXISTS "Anyone can view comments" ON public.comments;
CREATE POLICY "Anyone can view comments" ON public.comments
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert comments" ON public.comments;
CREATE POLICY "Authenticated users can insert comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comments" ON public.comments;
CREATE POLICY "Users can delete own comments" ON public.comments
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. ISSUE_UPDATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.issue_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id UUID REFERENCES public.issues(id) ON DELETE CASCADE NOT NULL,
  worker_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  progress INTEGER NOT NULL CHECK (progress >= 0 AND progress <= 100),
  status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_issue_updates_issue_id ON public.issue_updates(issue_id);
CREATE INDEX IF NOT EXISTS idx_issue_updates_created_at ON public.issue_updates(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_issue_updates_worker_id ON public.issue_updates(worker_id);

ALTER TABLE public.issue_updates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for issue_updates
DROP POLICY IF EXISTS "Users can view updates for their issues" ON public.issue_updates;
CREATE POLICY "Users can view updates for their issues" ON public.issue_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.issues 
      WHERE issues.id = issue_updates.issue_id 
      AND issues.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Workers can insert their own updates" ON public.issue_updates;
CREATE POLICY "Workers can insert their own updates" ON public.issue_updates
  FOR INSERT WITH CHECK (worker_id = auth.uid());

DROP POLICY IF EXISTS "Workers can view updates for assigned issues" ON public.issue_updates;
CREATE POLICY "Workers can view updates for assigned issues" ON public.issue_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.issues 
      WHERE issues.id = issue_updates.issue_id 
      AND issues.assigned_to = auth.uid()
    )
  );

-- ============================================
-- 4. UPVOTE FUNCTION
-- ============================================
DROP FUNCTION IF EXISTS public.upvote_issue(uuid);

CREATE OR REPLACE FUNCTION public.upvote_issue(issue_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.issues 
  SET upvotes = upvotes + 1 
  WHERE id = issue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. AWARD POINTS TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION public.award_points()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET points = points + 10 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'UPDATE' AND (NEW.status = 'completed' OR NEW.status = 'resolved') AND (OLD.status != 'completed' AND OLD.status != 'resolved') THEN
    UPDATE public.users SET points = points + 50 WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS issue_points_trigger ON public.issues;
CREATE TRIGGER issue_points_trigger
AFTER INSERT OR UPDATE ON public.issues
FOR EACH ROW EXECUTE FUNCTION public.award_points();

-- ============================================
-- 6. UPDATE USER STATS TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION public.update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET total_reports = total_reports + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'UPDATE' AND (NEW.status = 'completed' OR NEW.status = 'resolved') AND (OLD.status != 'completed' AND OLD.status != 'resolved') THEN
    UPDATE public.users SET resolved_issues = resolved_issues + 1 WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_user_stats_trigger ON public.issues;
CREATE TRIGGER update_user_stats_trigger
AFTER INSERT OR UPDATE ON public.issues
FOR EACH ROW EXECUTE FUNCTION public.update_user_stats();

-- ============================================
-- 7. GET NEARBY ISSUES FUNCTION
-- ============================================
DROP FUNCTION IF EXISTS public.get_nearby_issues(double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION public.get_nearby_issues(
  lat DOUBLE PRECISION, 
  lng DOUBLE PRECISION, 
  radius_km DOUBLE PRECISION
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  category TEXT,
  description TEXT,
  latitude NUMERIC,
  longitude NUMERIC,
  address TEXT,
  media_urls TEXT[],
  audio_url TEXT,
  status TEXT,
  upvotes INTEGER,
  progress INTEGER,
  assigned_to UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.user_id,
    i.category,
    i.description,
    i.latitude,
    i.longitude,
    i.address,
    i.media_urls,
    i.audio_url,
    i.status,
    i.upvotes,
    i.progress,
    i.assigned_to,
    i.created_at,
    i.updated_at,
    (6371 * acos(
      cos(radians(lat)) * cos(radians(i.latitude::double precision)) * 
      cos(radians(i.longitude::double precision) - radians(lng)) + 
      sin(radians(lat)) * sin(radians(i.latitude::double precision))
    )) AS distance_km
  FROM public.issues i
  WHERE (6371 * acos(
    cos(radians(lat)) * cos(radians(i.latitude::double precision)) * 
    cos(radians(i.longitude::double precision) - radians(lng)) + 
    sin(radians(lat)) * sin(radians(i.latitude::double precision))
  )) <= radius_km
  ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. GET COMMUNITY STATS FUNCTION
-- ============================================
DROP FUNCTION IF EXISTS public.get_community_stats();

CREATE OR REPLACE FUNCTION public.get_community_stats()
RETURNS TABLE (
  total_users INTEGER,
  total_issues INTEGER,
  resolved_issues INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM public.issues),
    (SELECT COUNT(*)::INTEGER FROM public.issues),
    (SELECT COUNT(*)::INTEGER FROM public.issues WHERE status = 'completed' OR status = 'resolved');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. GET ISSUE UPDATES HELPER FUNCTIONS
-- ============================================
CREATE OR REPLACE FUNCTION public.get_issue_updates(p_issue_id UUID)
RETURNS SETOF public.issue_updates AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.issue_updates
  WHERE issue_id = p_issue_id
  ORDER BY created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_issue_update_count(p_issue_id UUID)
RETURNS INTEGER AS $$
DECLARE
  update_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO update_count
  FROM public.issue_updates
  WHERE issue_id = p_issue_id;
  RETURN update_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- All missing Flutter app features have been added!
-- Your User App and Worker App should now work perfectly.
