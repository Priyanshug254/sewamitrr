-- SewaMitr RPC Functions
-- Migration 03: PostgreSQL functions for business logic

-- ============================================================================
-- FUNCTION: Find nearest ward by coordinates
-- ============================================================================
CREATE OR REPLACE FUNCTION public.find_nearest_ward(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
RETURNS UUID AS $$
DECLARE
    v_ward_id UUID;
    v_point GEOGRAPHY;
BEGIN
    v_point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
    
    -- First try to find ward containing the point
    SELECT id INTO v_ward_id
    FROM public.wards
    WHERE ST_Contains(polygon::geometry, v_point::geometry)
    LIMIT 1;
    
    -- If not found, find nearest ward by centroid
    IF v_ward_id IS NULL THEN
        SELECT id INTO v_ward_id
        FROM public.wards
        ORDER BY ST_Distance(centroid, v_point)
        LIMIT 1;
    END IF;
    
    RETURN v_ward_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Find nearest zone by coordinates
-- ============================================================================
CREATE OR REPLACE FUNCTION public.find_nearest_zone(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
RETURNS UUID AS $$
DECLARE
    v_zone_id UUID;
    v_point GEOGRAPHY;
BEGIN
    v_point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
    
    -- First try to find zone containing the point
    SELECT id INTO v_zone_id
    FROM public.zones
    WHERE ST_Contains(polygon::geometry, v_point::geometry)
    LIMIT 1;
    
    -- If not found, find nearest zone by polygon
    IF v_zone_id IS NULL THEN
        SELECT id INTO v_zone_id
        FROM public.zones
        ORDER BY ST_Distance(polygon, v_point)
        LIMIT 1;
    END IF;
    
    RETURN v_zone_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get nearby issues (Flutter app compatibility)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_nearby_issues(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS SETOF public.issues AS $$
DECLARE
    v_point GEOGRAPHY;
BEGIN
    v_point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
    
    RETURN QUERY
    SELECT i.*
    FROM public.issues i
    WHERE ST_DWithin(i.location, v_point, radius_km * 1000)
    ORDER BY ST_Distance(i.location, v_point);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get unverified issues for CRC supervisor
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_unverified_issues(
    zone_uuid UUID,
    limit_count INT DEFAULT 50,
    offset_count INT DEFAULT 0
)
RETURNS SETOF public.issues AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.issues
    WHERE zone_id = zone_uuid
    AND status = 'submitted'
    ORDER BY created_at DESC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Verify issue (CRC supervisor action)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.verify_issue(
    issue_uuid UUID,
    verifier_uuid UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.issues
    SET 
        status = 'crc_verified',
        updated_at = NOW()
    WHERE id = issue_uuid;
    
    -- Audit log is automatically created by trigger
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Forward issue to ward
-- ============================================================================
CREATE OR REPLACE FUNCTION public.forward_to_ward(
    issue_uuid UUID,
    ward_uuid UUID,
    forwarded_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_city_id UUID;
    v_zone_id UUID;
BEGIN
    -- Get city_id and zone_id for the ward
    SELECT city_id INTO v_city_id
    FROM public.wards
    WHERE id = ward_uuid;
    
    -- Find zone containing this ward
    SELECT id INTO v_zone_id
    FROM public.zones
    WHERE ward_uuid = ANY(ward_ids)
    LIMIT 1;
    
    UPDATE public.issues
    SET 
        status = 'forwarded_to_ward',
        ward_id = ward_uuid,
        city_id = v_city_id,
        zone_id = v_zone_id,
        updated_at = NOW()
    WHERE id = issue_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Assign issue to contractor
-- ============================================================================
CREATE OR REPLACE FUNCTION public.assign_issue_to_contractor(
    issue_uuid UUID,
    contractor_uuid UUID,
    assigned_by UUID,
    eta TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Update issue
    UPDATE public.issues
    SET 
        assigned_to = contractor_uuid,
        status = 'in_progress',
        updated_at = NOW()
    WHERE id = issue_uuid;
    
    -- Create assignment record
    INSERT INTO public.assignments (issue_id, assigned_by, assigned_to, eta, status)
    VALUES (issue_uuid, assigned_by, contractor_uuid, eta, 'accepted');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Close/resolve issue
-- ============================================================================
CREATE OR REPLACE FUNCTION public.close_issue(
    issue_uuid UUID,
    closed_by UUID,
    resolution_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.issues
    SET 
        status = 'resolved',
        progress = 100,
        updated_at = NOW()
    WHERE id = issue_uuid;
    
    -- Update assignment status
    UPDATE public.assignments
    SET 
        status = 'completed',
        notes = resolution_notes,
        updated_at = NOW()
    WHERE issue_id = issue_uuid
    AND status != 'completed';
    
    -- Update user stats
    UPDATE public.users
    SET resolved_issues = resolved_issues + 1
    WHERE id = (SELECT user_id FROM public.issues WHERE id = issue_uuid);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Upvote issue (Flutter app compatibility)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upvote_issue(
    issue_uuid UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.issues
    SET upvotes = upvotes + 1
    WHERE id = issue_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get community stats (Flutter app compatibility)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_community_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_issues BIGINT,
    resolved_issues BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM public.users WHERE role = 'citizen') AS total_users,
        (SELECT COUNT(*) FROM public.issues) AS total_issues,
        (SELECT COUNT(*) FROM public.issues WHERE status = 'resolved') AS resolved_issues;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get city analytics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_city_analytics(
    city_uuid UUID
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_issues', COUNT(*),
        'open_issues', COUNT(*) FILTER (WHERE status NOT IN ('resolved', 'rejected')),
        'resolved_issues', COUNT(*) FILTER (WHERE status = 'resolved'),
        'rejected_issues', COUNT(*) FILTER (WHERE status = 'rejected'),
        'sla_compliant', COUNT(*) FILTER (WHERE sla_due_at > NOW() OR status = 'resolved'),
        'sla_breached', COUNT(*) FILTER (WHERE sla_due_at < NOW() AND status NOT IN ('resolved', 'rejected')),
        'by_category', (
            SELECT jsonb_object_agg(category, count)
            FROM (
                SELECT category, COUNT(*) as count
                FROM public.issues
                WHERE city_id = city_uuid
                GROUP BY category
            ) cat
        ),
        'by_priority', (
            SELECT jsonb_object_agg(priority, count)
            FROM (
                SELECT priority, COUNT(*) as count
                FROM public.issues
                WHERE city_id = city_uuid
                GROUP BY priority
            ) pri
        )
    ) INTO v_result
    FROM public.issues
    WHERE city_id = city_uuid;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get ward analytics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_ward_analytics(
    ward_uuid UUID
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_issues', COUNT(*),
        'open_issues', COUNT(*) FILTER (WHERE status NOT IN ('resolved', 'rejected')),
        'resolved_issues', COUNT(*) FILTER (WHERE status = 'resolved'),
        'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
        'avg_resolution_time_hours', AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600) FILTER (WHERE status = 'resolved'),
        'by_category', (
            SELECT jsonb_object_agg(category, count)
            FROM (
                SELECT category, COUNT(*) as count
                FROM public.issues
                WHERE ward_id = ward_uuid
                GROUP BY category
            ) cat
        )
    ) INTO v_result
    FROM public.issues
    WHERE ward_id = ward_uuid;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get zone analytics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_zone_analytics(
    zone_uuid UUID
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_issues', COUNT(*),
        'unverified', COUNT(*) FILTER (WHERE status = 'submitted'),
        'verified', COUNT(*) FILTER (WHERE status = 'crc_verified'),
        'forwarded', COUNT(*) FILTER (WHERE status = 'forwarded_to_ward'),
        'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
        'by_ward', (
            SELECT jsonb_object_agg(w.name, count)
            FROM (
                SELECT w.name, COUNT(i.*) as count
                FROM public.wards w
                LEFT JOIN public.issues i ON i.ward_id = w.id AND i.zone_id = zone_uuid
                WHERE w.id = ANY(
                    SELECT unnest(ward_ids) FROM public.zones WHERE id = zone_uuid
                )
                GROUP BY w.name
            ) w
        )
    ) INTO v_result
    FROM public.issues
    WHERE zone_id = zone_uuid;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get state-level analytics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_state_analytics()
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_issues', COUNT(*),
        'open_issues', COUNT(*) FILTER (WHERE status NOT IN ('resolved', 'rejected')),
        'resolved_issues', COUNT(*) FILTER (WHERE status = 'resolved'),
        'sla_compliance_rate', 
            ROUND(
                (COUNT(*) FILTER (WHERE sla_due_at > NOW() OR status = 'resolved')::NUMERIC / 
                NULLIF(COUNT(*), 0) * 100), 2
            ),
        'by_city', (
            SELECT jsonb_object_agg(c.name, count)
            FROM (
                SELECT c.name, COUNT(i.*) as count
                FROM public.cities c
                LEFT JOIN public.issues i ON i.city_id = c.id
                GROUP BY c.name
            ) c
        ),
        'by_status', (
            SELECT jsonb_object_agg(status, count)
            FROM (
                SELECT status, COUNT(*) as count
                FROM public.issues
                GROUP BY status
            ) s
        )
    ) INTO v_result
    FROM public.issues;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get contractor performance
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_contractor_performance(
    contractor_uuid UUID
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'active_assignments', cp.active_assignments,
        'completed_assignments', cp.completed_assignments,
        'rating', cp.rating,
        'avg_completion_time_hours', (
            SELECT AVG(EXTRACT(EPOCH FROM (a.updated_at - a.created_at)) / 3600)
            FROM public.assignments a
            WHERE a.assigned_to = contractor_uuid
            AND a.status = 'completed'
        ),
        'specializations', cp.specializations
    ) INTO v_result
    FROM public.contractor_profiles cp
    WHERE cp.user_id = contractor_uuid;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;
