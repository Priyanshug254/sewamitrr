-- ============================================
-- SewaMitr Worker System Setup (Safe Version)
-- ============================================
-- This version preserves existing data in assigned_to column
-- Run this if you have existing assignments as TEXT

-- ============================================
-- 1. ADD WORKER COLUMNS
-- ============================================

-- Add role column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- Backup existing assigned_to data if it exists as TEXT
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'issues' 
    AND column_name = 'assigned_to' 
    AND data_type = 'text'
  ) THEN
    -- Create backup column
    ALTER TABLE issues ADD COLUMN IF NOT EXISTS assigned_to_backup TEXT;
    -- Copy data
    UPDATE issues SET assigned_to_backup = assigned_to WHERE assigned_to IS NOT NULL;
    -- Drop old column
    ALTER TABLE issues DROP COLUMN assigned_to;
  END IF;
END $$;

-- Add assigned_to as UUID
ALTER TABLE issues 
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id);

-- Restore data if backup exists (convert TEXT to UUID)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'issues' 
    AND column_name = 'assigned_to_backup'
  ) THEN
    -- Try to convert TEXT UUIDs to UUID type
    UPDATE issues 
    SET assigned_to = assigned_to_backup::UUID 
    WHERE assigned_to_backup IS NOT NULL 
    AND assigned_to_backup ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    
    -- Drop backup column
    ALTER TABLE issues DROP COLUMN assigned_to_backup;
  END IF;
END $$;

-- Add update_logs column
ALTER TABLE issues 
ADD COLUMN IF NOT EXISTS update_logs JSONB DEFAULT '[]'::jsonb;

-- ============================================
-- 2. CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_issues_assigned_to ON issues(assigned_to);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);

-- ============================================
-- 3. RLS POLICIES
-- ============================================

-- Drop existing conflicting policies if they exist
DROP POLICY IF EXISTS "Workers can update assigned issues" ON issues;
DROP POLICY IF EXISTS "Workers can view assigned issues" ON issues;
DROP POLICY IF EXISTS "Authenticated users can assign issues" ON issues;

-- Allow workers to update assigned issues
CREATE POLICY "Workers can update assigned issues" ON issues
  FOR UPDATE 
  USING (assigned_to = auth.uid());

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- Get all workers
CREATE OR REPLACE FUNCTION get_workers()
RETURNS TABLE (
  id UUID,
  email TEXT,
  name TEXT,
  photo_url TEXT,
  assigned_issues_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email,
    u.name,
    u.photo_url,
    u.photo_url,
    COUNT(i.id) as assigned_issues_count
  FROM users u
  LEFT JOIN issues i ON i.assigned_to = u.id
  GROUP BY u.id, u.email, u.name, u.photo_url
  ORDER BY u.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get issues for a worker
CREATE OR REPLACE FUNCTION get_worker_issues(worker_id UUID)
RETURNS SETOF issues AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM issues 
  WHERE assigned_to = worker_id
  ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get unassigned issues
CREATE OR REPLACE FUNCTION get_unassigned_issues()
RETURNS SETOF issues AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM issues 
  WHERE assigned_to IS NULL
  ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Assign issue to worker
CREATE OR REPLACE FUNCTION assign_issue_to_worker(
  issue_uuid UUID,
  worker_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE issues 
  SET assigned_to = worker_uuid,
      updated_at = NOW()
  WHERE id = issue_uuid;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. NOTIFICATION TRIGGERS
-- ============================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS issue_assigned_notification ON issues;
DROP TRIGGER IF EXISTS issue_progress_notification ON issues;

-- Notify when issue is assigned
CREATE OR REPLACE FUNCTION notify_issue_assigned()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.assigned_to IS NOT NULL AND (OLD.assigned_to IS NULL OR OLD.assigned_to != NEW.assigned_to) THEN
    INSERT INTO notifications (user_id, issue_id, title, message, type)
    VALUES (
      NEW.user_id,
      NEW.id,
      'Issue Assigned',
      'Your issue has been assigned to a worker.',
      'info'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER issue_assigned_notification
AFTER UPDATE ON issues
FOR EACH ROW
EXECUTE FUNCTION notify_issue_assigned();

-- Notify when progress is updated
CREATE OR REPLACE FUNCTION notify_issue_updated()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.progress != OLD.progress OR NEW.status != OLD.status THEN
    INSERT INTO notifications (user_id, issue_id, title, message, type)
    VALUES (
      NEW.user_id,
      NEW.id,
      'Issue Update',
      format('Your issue is now %s%% complete (%s)', NEW.progress, NEW.status),
      'success'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER issue_progress_notification
AFTER UPDATE ON issues
FOR EACH ROW
EXECUTE FUNCTION notify_issue_updated();

-- ============================================
-- 6. HELPER VIEWS
-- ============================================

DROP VIEW IF EXISTS worker_workload;
CREATE VIEW worker_workload AS
SELECT 
  u.id as worker_id,
  u.name as worker_name,
  u.email as worker_email,
  COUNT(CASE WHEN i.status = 'pending' THEN 1 END) as pending_issues,
  COUNT(CASE WHEN i.status = 'in_progress' THEN 1 END) as in_progress_issues,
  COUNT(CASE WHEN i.status = 'completed' THEN 1 END) as completed_issues,
  COUNT(i.id) as total_assigned
FROM users u
LEFT JOIN issues i ON i.assigned_to = u.id
GROUP BY u.id, u.name, u.email
ORDER BY total_assigned DESC;

DROP VIEW IF EXISTS unassigned_by_category;
CREATE VIEW unassigned_by_category AS
SELECT 
  category,
  COUNT(*) as count,
  COALESCE(AVG(upvotes), 0) as avg_upvotes
FROM issues
WHERE assigned_to IS NULL
GROUP BY category
ORDER BY count DESC;

-- ============================================
-- SETUP COMPLETE!
-- ============================================

-- Verify setup
SELECT 
  'Setup Complete!' as status,
  (SELECT COUNT(*) FROM users) as total_users,
  (SELECT COUNT(*) FROM issues) as total_issues,
  (SELECT COUNT(*) FROM issues WHERE assigned_to IS NOT NULL) as assigned_issues,
  (SELECT COUNT(*) FROM issues WHERE assigned_to IS NULL) as unassigned_issues;
