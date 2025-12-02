-- SewaMitr Materialized Views for Analytics
-- Migration 08: Materialized views for fast analytics queries

-- ============================================================================
-- MATERIALIZED VIEW: State-level analytics
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_state_overview AS
SELECT
    COUNT(*) as total_issues,
    COUNT(*) FILTER (WHERE status NOT IN ('resolved', 'rejected')) as open_issues,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_issues,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected_issues,
    COUNT(*) FILTER (WHERE status = 'submitted') as unverified_issues,
    COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_issues,
    ROUND(
        (COUNT(*) FILTER (WHERE sla_due_at > NOW() OR status = 'resolved')::NUMERIC / 
        NULLIF(COUNT(*), 0) * 100), 2
    ) as sla_compliance_rate,
    COUNT(*) FILTER (WHERE sla_due_at < NOW() AND status NOT IN ('resolved', 'rejected')) as sla_breached,
    COUNT(DISTINCT user_id) as total_reporters,
    COUNT(DISTINCT assigned_to) FILTER (WHERE assigned_to IS NOT NULL) as active_workers,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600) FILTER (WHERE status = 'resolved') as avg_resolution_time_hours,
    NOW() as refreshed_at
FROM public.issues;

CREATE UNIQUE INDEX ON public.analytics_state_overview ((1));

-- ============================================================================
-- MATERIALIZED VIEW: City-level analytics
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_by_city AS
SELECT
    c.id as city_id,
    c.name as city_name,
    COUNT(i.*) as total_issues,
    COUNT(i.*) FILTER (WHERE i.status NOT IN ('resolved', 'rejected')) as open_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'resolved') as resolved_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'submitted') as unverified_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'in_progress') as in_progress_issues,
    ROUND(
        (COUNT(i.*) FILTER (WHERE i.sla_due_at > NOW() OR i.status = 'resolved')::NUMERIC / 
        NULLIF(COUNT(i.*), 0) * 100), 2
    ) as sla_compliance_rate,
    COUNT(i.*) FILTER (WHERE i.priority = 'critical') as critical_issues,
    COUNT(i.*) FILTER (WHERE i.priority = 'high') as high_priority_issues,
    AVG(EXTRACT(EPOCH FROM (i.updated_at - i.created_at)) / 3600) FILTER (WHERE i.status = 'resolved') as avg_resolution_time_hours,
    NOW() as refreshed_at
FROM public.cities c
LEFT JOIN public.issues i ON i.city_id = c.id
GROUP BY c.id, c.name;

CREATE UNIQUE INDEX ON public.analytics_by_city (city_id);

-- ============================================================================
-- MATERIALIZED VIEW: Ward-level analytics
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_by_ward AS
SELECT
    w.id as ward_id,
    w.name as ward_name,
    w.city_id,
    c.name as city_name,
    COUNT(i.*) as total_issues,
    COUNT(i.*) FILTER (WHERE i.status NOT IN ('resolved', 'rejected')) as open_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'resolved') as resolved_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'in_progress') as in_progress_issues,
    COUNT(i.*) FILTER (WHERE i.assigned_to IS NOT NULL) as assigned_issues,
    AVG(EXTRACT(EPOCH FROM (i.updated_at - i.created_at)) / 3600) FILTER (WHERE i.status = 'resolved') as avg_resolution_time_hours,
    COUNT(DISTINCT i.assigned_to) FILTER (WHERE i.assigned_to IS NOT NULL) as active_workers,
    NOW() as refreshed_at
FROM public.wards w
LEFT JOIN public.cities c ON c.id = w.city_id
LEFT JOIN public.issues i ON i.ward_id = w.id
GROUP BY w.id, w.name, w.city_id, c.name;

CREATE UNIQUE INDEX ON public.analytics_by_ward (ward_id);

-- ============================================================================
-- MATERIALIZED VIEW: Zone-level analytics
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_by_zone AS
SELECT
    z.id as zone_id,
    z.name as zone_name,
    z.city_id,
    c.name as city_name,
    z.supervisor_user_id,
    u.full_name as supervisor_name,
    COUNT(i.*) as total_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'submitted') as unverified_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'crc_verified') as verified_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'forwarded_to_ward') as forwarded_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'rejected') as rejected_issues,
    COUNT(i.*) FILTER (WHERE i.status = 'resolved') as resolved_issues,
    AVG(EXTRACT(EPOCH FROM (i.updated_at - i.created_at)) / 3600) FILTER (WHERE i.status IN ('crc_verified', 'forwarded_to_ward')) as avg_verification_time_hours,
    NOW() as refreshed_at
FROM public.zones z
LEFT JOIN public.cities c ON c.id = z.city_id
LEFT JOIN public.users u ON u.id = z.supervisor_user_id
LEFT JOIN public.issues i ON i.zone_id = z.id
GROUP BY z.id, z.name, z.city_id, c.name, z.supervisor_user_id, u.full_name;

CREATE UNIQUE INDEX ON public.analytics_by_zone (zone_id);

-- ============================================================================
-- MATERIALIZED VIEW: Category analytics
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_by_category AS
SELECT
    category,
    COUNT(*) as total_issues,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_issues,
    COUNT(*) FILTER (WHERE status NOT IN ('resolved', 'rejected')) as open_issues,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600) FILTER (WHERE status = 'resolved') as avg_resolution_time_hours,
    AVG(sla_allowed_hours) as avg_sla_hours,
    ROUND(
        (COUNT(*) FILTER (WHERE sla_due_at > NOW() OR status = 'resolved')::NUMERIC / 
        NULLIF(COUNT(*), 0) * 100), 2
    ) as sla_compliance_rate,
    NOW() as refreshed_at
FROM public.issues
GROUP BY category;

CREATE UNIQUE INDEX ON public.analytics_by_category (category);

-- ============================================================================
-- MATERIALIZED VIEW: Contractor performance
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.analytics_contractor_performance AS
SELECT
    u.id as contractor_id,
    u.full_name as contractor_name,
    u.city_id,
    c.name as city_name,
    cp.specializations,
    cp.rating,
    cp.active_assignments,
    cp.completed_assignments,
    COUNT(a.*) as total_assignments,
    COUNT(a.*) FILTER (WHERE a.status = 'completed') as completed_count,
    COUNT(a.*) FILTER (WHERE a.status IN ('pending', 'accepted', 'in_progress')) as active_count,
    AVG(EXTRACT(EPOCH FROM (a.updated_at - a.created_at)) / 3600) FILTER (WHERE a.status = 'completed') as avg_completion_time_hours,
    NOW() as refreshed_at
FROM public.users u
INNER JOIN public.contractor_profiles cp ON cp.user_id = u.id
LEFT JOIN public.cities c ON c.id = u.city_id
LEFT JOIN public.assignments a ON a.assigned_to = u.id
WHERE u.role = 'worker'
GROUP BY u.id, u.full_name, u.city_id, c.name, cp.specializations, cp.rating, cp.active_assignments, cp.completed_assignments;

CREATE UNIQUE INDEX ON public.analytics_contractor_performance (contractor_id);

-- ============================================================================
-- FUNCTION: Refresh all materialized views
-- ============================================================================
CREATE OR REPLACE FUNCTION public.refresh_all_analytics()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public.analytics_state_overview;
    REFRESH MATERIALIZED VIEW public.analytics_by_city;
    REFRESH MATERIALIZED VIEW public.analytics_by_ward;
    REFRESH MATERIALIZED VIEW public.analytics_by_zone;
    REFRESH MATERIALIZED VIEW public.analytics_by_category;
    REFRESH MATERIALIZED VIEW public.analytics_contractor_performance;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT SELECT on materialized views
-- ============================================================================
GRANT SELECT ON public.analytics_state_overview TO anon, authenticated;
GRANT SELECT ON public.analytics_by_city TO anon, authenticated;
GRANT SELECT ON public.analytics_by_ward TO anon, authenticated;
GRANT SELECT ON public.analytics_by_zone TO anon, authenticated;
GRANT SELECT ON public.analytics_by_category TO anon, authenticated;
GRANT SELECT ON public.analytics_contractor_performance TO anon, authenticated;

-- ============================================================================
-- INITIAL REFRESH
-- ============================================================================
SELECT public.refresh_all_analytics();
