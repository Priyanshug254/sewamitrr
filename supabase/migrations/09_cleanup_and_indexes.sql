-- SewaMitr Cleanup and Performance Indexes
-- Migration 09: Additional indexes for query optimization

-- ============================================================================
-- COMPOSITE INDEXES for common query patterns
-- ============================================================================

-- Issues: city + status (for city dashboard filtering)
CREATE INDEX IF NOT EXISTS idx_issues_city_status ON public.issues(city_id, status);

-- Issues: ward + status (for ward dashboard filtering)
CREATE INDEX IF NOT EXISTS idx_issues_ward_status ON public.issues(ward_id, status);

-- Issues: zone + status (for CRC dashboard filtering)
CREATE INDEX IF NOT EXISTS idx_issues_zone_status ON public.issues(zone_id, status);

-- Issues: user + created_at (for user's issue history)
CREATE INDEX IF NOT EXISTS idx_issues_user_created ON public.issues(user_id, created_at DESC);

-- Issues: status + sla_due_at (for SLA monitoring)
CREATE INDEX IF NOT EXISTS idx_issues_status_sla ON public.issues(status, sla_due_at) WHERE sla_due_at IS NOT NULL;

-- Issues: category + city (for category analytics per city)
CREATE INDEX IF NOT EXISTS idx_issues_category_city ON public.issues(category, city_id);

-- Assignments: assigned_to + status (for worker dashboard)
CREATE INDEX IF NOT EXISTS idx_assignments_worker_status ON public.assignments(assigned_to, status);

-- Audit logs: issue + created_at (for issue timeline)
CREATE INDEX IF NOT EXISTS idx_audit_logs_issue_created ON public.audit_logs(issue_id, created_at DESC);

-- ============================================================================
-- PARTIAL INDEXES for specific queries
-- ============================================================================

-- Open issues only (excludes resolved and rejected)
CREATE INDEX IF NOT EXISTS idx_issues_open ON public.issues(city_id, created_at DESC) 
WHERE status NOT IN ('resolved', 'rejected');

-- Unverified issues for CRC (submitted status only)
CREATE INDEX IF NOT EXISTS idx_issues_unverified_zone ON public.issues(zone_id, created_at DESC) 
WHERE status = 'submitted';

-- SLA breached issues (removed - NOW() is not IMMUTABLE, query without index is acceptable)
-- Use: SELECT * FROM issues WHERE sla_due_at < NOW() AND status NOT IN ('resolved', 'rejected');

-- Active assignments
CREATE INDEX IF NOT EXISTS idx_assignments_active ON public.assignments(assigned_to, created_at DESC) 
WHERE status IN ('pending', 'accepted', 'in_progress');

-- ============================================================================
-- TEXT SEARCH INDEXES
-- ============================================================================

-- Full-text search on issue description and address
CREATE INDEX IF NOT EXISTS idx_issues_description_search ON public.issues 
USING gin(to_tsvector('english', description || ' ' || address));

-- ============================================================================
-- STATISTICS for query planner
-- ============================================================================

-- Analyze all tables to update statistics
ANALYZE public.users;
ANALYZE public.cities;
ANALYZE public.wards;
ANALYZE public.zones;
ANALYZE public.issues;
ANALYZE public.assignments;
ANALYZE public.audit_logs;
ANALYZE public.votes;
ANALYZE public.contractor_profiles;

-- ============================================================================
-- COMMENTS for documentation
-- ============================================================================

COMMENT ON INDEX idx_issues_city_status IS 'Optimizes city dashboard filtering by status';
COMMENT ON INDEX idx_issues_ward_status IS 'Optimizes ward dashboard filtering by status';
COMMENT ON INDEX idx_issues_zone_status IS 'Optimizes CRC dashboard filtering by status';
COMMENT ON INDEX idx_issues_unverified_zone IS 'Optimizes CRC unverified queue queries';
COMMENT ON INDEX idx_issues_description_search IS 'Enables full-text search on issues';

