-- ============================================================================
-- FIX STATUS CHECK CONSTRAINT
-- The User App needs 'submitted' status but constraint might be outdated
-- ============================================================================

-- Drop the old constraint
ALTER TABLE public.issues DROP CONSTRAINT IF EXISTS "issues_status_check";
ALTER TABLE public.issues DROP CONSTRAINT IF EXISTS "issues-status-check";

-- Add new constraint with all valid statuses
ALTER TABLE public.issues 
ADD CONSTRAINT issues_status_check 
CHECK (status IN ('pending', 'submitted', 'crc_verified', 'forwarded_to_ward', 'in_progress', 'resolved', 'rejected', 'completed'));

-- Verify the constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'public.issues'::regclass 
AND conname LIKE '%status%';
