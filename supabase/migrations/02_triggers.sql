-- SewaMitr Database Triggers
-- Migration 02: Triggers for automation

-- ============================================================================
-- TRIGGER: Sync auth.users to public.users
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, role, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'citizen'),
        NEW.created_at
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- TRIGGER: Auto-populate location from latitude/longitude
-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_populate_location()
RETURNS TRIGGER AS $$
BEGIN
    -- Populate location geography from latitude and longitude
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_populate_location ON public.issues;
CREATE TRIGGER trigger_auto_populate_location
    BEFORE INSERT OR UPDATE OF latitude, longitude ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_populate_location();

-- ============================================================================
-- TRIGGER: Auto-assign ward and zone based on geography
-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_assign_ward_zone()
RETURNS TRIGGER AS $$
DECLARE
    v_ward_id UUID;
    v_zone_id UUID;
    v_city_id UUID;
BEGIN
    -- Skip if location is not set
    IF NEW.location IS NULL THEN
        RETURN NEW;
    END IF;

    -- Find ward containing this point
    SELECT id, city_id INTO v_ward_id, v_city_id
    FROM public.wards
    WHERE ST_Contains(polygon::geometry, NEW.location::geometry)
    LIMIT 1;

    -- If ward found, assign it
    IF v_ward_id IS NOT NULL THEN
        NEW.ward_id = v_ward_id;
        NEW.city_id = v_city_id;

        -- Find zone containing this ward
        SELECT id INTO v_zone_id
        FROM public.zones
        WHERE city_id = v_city_id
        AND v_ward_id = ANY(ward_ids)
        LIMIT 1;

        IF v_zone_id IS NOT NULL THEN
            NEW.zone_id = v_zone_id;
        END IF;
    ELSE
        -- If no ward found, try to find nearest ward
        SELECT w.id, w.city_id INTO v_ward_id, v_city_id
        FROM public.wards w
        ORDER BY ST_Distance(w.centroid, NEW.location)
        LIMIT 1;

        IF v_ward_id IS NOT NULL THEN
            NEW.ward_id = v_ward_id;
            NEW.city_id = v_city_id;

            -- Find zone containing this ward
            SELECT id INTO v_zone_id
            FROM public.zones
            WHERE city_id = v_city_id
            AND v_ward_id = ANY(ward_ids)
            LIMIT 1;

            IF v_zone_id IS NOT NULL THEN
                NEW.zone_id = v_zone_id;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_assign_ward_zone ON public.issues;
CREATE TRIGGER trigger_auto_assign_ward_zone
    BEFORE INSERT OR UPDATE OF location ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_assign_ward_zone();

-- ============================================================================
-- TRIGGER: Auto-calculate SLA based on category and priority
-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_calculate_sla()
RETURNS TRIGGER AS $$
DECLARE
    v_sla_hours INTEGER;
BEGIN
    -- Set SLA hours based on priority
    CASE NEW.priority
        WHEN 'critical' THEN v_sla_hours = 12;
        WHEN 'high' THEN v_sla_hours = 24;
        WHEN 'medium' THEN v_sla_hours = 72;
        WHEN 'low' THEN v_sla_hours = 168; -- 7 days
        ELSE v_sla_hours = 72;
    END CASE;

    -- Adjust SLA based on category
    CASE NEW.category
        WHEN 'Water Supply' THEN v_sla_hours = LEAST(v_sla_hours, 24);
        WHEN 'Drainage' THEN v_sla_hours = LEAST(v_sla_hours, 24);
        WHEN 'Sanitation' THEN v_sla_hours = LEAST(v_sla_hours, 48);
        WHEN 'Pothole' THEN v_sla_hours = GREATEST(v_sla_hours, 48);
        ELSE NULL;
    END CASE;

    NEW.sla_allowed_hours = v_sla_hours;
    NEW.sla_due_at = NEW.created_at + (v_sla_hours || ' hours')::INTERVAL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_calculate_sla ON public.issues;
CREATE TRIGGER trigger_auto_calculate_sla
    BEFORE INSERT ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_calculate_sla();

-- ============================================================================
-- TRIGGER: Audit log for issue changes
-- ============================================================================
CREATE OR REPLACE FUNCTION public.log_issue_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_action TEXT;
    v_performed_by UUID;
BEGIN
    -- Determine action
    IF TG_OP = 'INSERT' THEN
        v_action = 'created';
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != NEW.status THEN
            v_action = 'status_changed: ' || OLD.status || ' → ' || NEW.status;
        ELSIF OLD.assigned_to IS DISTINCT FROM NEW.assigned_to THEN
            v_action = 'assigned';
        ELSIF OLD.progress != NEW.progress THEN
            v_action = 'progress_updated: ' || OLD.progress || '% → ' || NEW.progress || '%';
        ELSE
            v_action = 'updated';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        v_action = 'deleted';
    END IF;

    -- Try to get current user from session
    BEGIN
        v_performed_by = auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_performed_by = NULL;
    END;

    -- Insert audit log
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_logs (issue_id, action, performed_by, old_data, created_at)
        VALUES (OLD.id, v_action, v_performed_by, to_jsonb(OLD), NOW());
        RETURN OLD;
    ELSE
        INSERT INTO public.audit_logs (issue_id, action, performed_by, old_data, new_data, created_at)
        VALUES (
            NEW.id,
            v_action,
            v_performed_by,
            CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
            to_jsonb(NEW),
            NOW()
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_log_issue_changes ON public.issues;
CREATE TRIGGER trigger_log_issue_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.log_issue_changes();

-- ============================================================================
-- TRIGGER: Update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON public.users;
CREATE TRIGGER trigger_update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_issues_updated_at ON public.issues;
CREATE TRIGGER trigger_update_issues_updated_at
    BEFORE UPDATE ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_assignments_updated_at ON public.assignments;
CREATE TRIGGER trigger_update_assignments_updated_at
    BEFORE UPDATE ON public.assignments
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_update_contractor_profiles_updated_at ON public.contractor_profiles;
CREATE TRIGGER trigger_update_contractor_profiles_updated_at
    BEFORE UPDATE ON public.contractor_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- TRIGGER: Update contractor active assignments count
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_contractor_assignments()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Increment active assignments
        UPDATE public.contractor_profiles
        SET active_assignments = active_assignments + 1
        WHERE user_id = NEW.assigned_to;
    ELSIF TG_OP = 'UPDATE' THEN
        -- If status changed to completed
        IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
            UPDATE public.contractor_profiles
            SET 
                active_assignments = GREATEST(active_assignments - 1, 0),
                completed_assignments = completed_assignments + 1
            WHERE user_id = NEW.assigned_to;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrement active assignments
        UPDATE public.contractor_profiles
        SET active_assignments = GREATEST(active_assignments - 1, 0)
        WHERE user_id = OLD.assigned_to;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_contractor_assignments ON public.assignments;
CREATE TRIGGER trigger_update_contractor_assignments
    AFTER INSERT OR UPDATE OR DELETE ON public.assignments
    FOR EACH ROW
    EXECUTE FUNCTION public.update_contractor_assignments();
