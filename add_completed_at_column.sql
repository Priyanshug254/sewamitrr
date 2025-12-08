-- ============================================================================
-- ADD MISSING COLUMNS TO ISSUES TABLE
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Add completed_at column (for reopen functionality)
ALTER TABLE public.issues 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Update existing completed/resolved issues to set completed_at
UPDATE public.issues 
SET completed_at = updated_at 
WHERE (status = 'completed' OR status = 'resolved') 
AND completed_at IS NULL;

-- Add comment
COMMENT ON COLUMN public.issues.completed_at IS 'Timestamp when issue was marked as completed/resolved (enables 48-hour reopen window)';
