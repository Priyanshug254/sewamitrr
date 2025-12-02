-- SewaMitr Row Level Security Policies
-- Migration 04: RLS policies for role-based access control

-- ============================================================================
-- HELPER FUNCTION: Get user role
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
    SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================================
-- HELPER FUNCTION: Get user city_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_city_id()
RETURNS UUID AS $$
    SELECT city_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================================
-- HELPER FUNCTION: Get user ward_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_ward_id()
RETURNS UUID AS $$
    SELECT ward_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================================
-- HELPER FUNCTION: Get user zone_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_zone_id()
RETURNS UUID AS $$
    SELECT zone_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES: users table
-- ============================================================================

-- State admin: full access
CREATE POLICY "state_admin_users_all" ON public.users
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- City admin: access to users in their city
CREATE POLICY "city_admin_users_select" ON public.users
    FOR SELECT
    USING (
        public.get_user_role() = 'city_admin' 
        AND city_id = public.get_user_city_id()
    );

-- CRC supervisor: access to users in their zone
CREATE POLICY "crc_supervisor_users_select" ON public.users
    FOR SELECT
    USING (
        public.get_user_role() = 'crc_supervisor' 
        AND zone_id = public.get_user_zone_id()
    );

-- Ward supervisor: access to users in their ward
CREATE POLICY "ward_supervisor_users_select" ON public.users
    FOR SELECT
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND ward_id = public.get_user_ward_id()
    );

-- Users can view and update their own profile
CREATE POLICY "users_own_profile" ON public.users
    FOR ALL
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- ============================================================================
-- RLS POLICIES: cities table
-- ============================================================================

-- Everyone can view cities
CREATE POLICY "cities_select_all" ON public.cities
    FOR SELECT
    USING (true);

-- Only state admin can modify cities
CREATE POLICY "state_admin_cities_modify" ON public.cities
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- ============================================================================
-- RLS POLICIES: wards table
-- ============================================================================

-- Everyone can view wards
CREATE POLICY "wards_select_all" ON public.wards
    FOR SELECT
    USING (true);

-- State and city admins can modify wards
CREATE POLICY "admin_wards_modify" ON public.wards
    FOR ALL
    USING (
        public.get_user_role() IN ('state_admin', 'city_admin')
        AND (
            public.get_user_role() = 'state_admin'
            OR city_id = public.get_user_city_id()
        )
    )
    WITH CHECK (
        public.get_user_role() IN ('state_admin', 'city_admin')
        AND (
            public.get_user_role() = 'state_admin'
            OR city_id = public.get_user_city_id()
        )
    );

-- ============================================================================
-- RLS POLICIES: zones table
-- ============================================================================

-- Everyone can view zones
CREATE POLICY "zones_select_all" ON public.zones
    FOR SELECT
    USING (true);

-- State and city admins can modify zones
CREATE POLICY "admin_zones_modify" ON public.zones
    FOR ALL
    USING (
        public.get_user_role() IN ('state_admin', 'city_admin')
        AND (
            public.get_user_role() = 'state_admin'
            OR city_id = public.get_user_city_id()
        )
    )
    WITH CHECK (
        public.get_user_role() IN ('state_admin', 'city_admin')
        AND (
            public.get_user_role() = 'state_admin'
            OR city_id = public.get_user_city_id()
        )
    );

-- ============================================================================
-- RLS POLICIES: issues table
-- ============================================================================

-- State admin: full access to all issues
CREATE POLICY "state_admin_issues_all" ON public.issues
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- City admin: access to issues in their city
CREATE POLICY "city_admin_issues_select" ON public.issues
    FOR SELECT
    USING (
        public.get_user_role() = 'city_admin' 
        AND city_id = public.get_user_city_id()
    );

CREATE POLICY "city_admin_issues_update" ON public.issues
    FOR UPDATE
    USING (
        public.get_user_role() = 'city_admin' 
        AND city_id = public.get_user_city_id()
    )
    WITH CHECK (
        public.get_user_role() = 'city_admin' 
        AND city_id = public.get_user_city_id()
    );

-- CRC supervisor: access to issues in their zone
CREATE POLICY "crc_supervisor_issues_select" ON public.issues
    FOR SELECT
    USING (
        public.get_user_role() = 'crc_supervisor' 
        AND zone_id = public.get_user_zone_id()
    );

CREATE POLICY "crc_supervisor_issues_update" ON public.issues
    FOR UPDATE
    USING (
        public.get_user_role() = 'crc_supervisor' 
        AND zone_id = public.get_user_zone_id()
    )
    WITH CHECK (
        public.get_user_role() = 'crc_supervisor' 
        AND zone_id = public.get_user_zone_id()
    );

-- Ward supervisor: access to issues in their ward
CREATE POLICY "ward_supervisor_issues_select" ON public.issues
    FOR SELECT
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND ward_id = public.get_user_ward_id()
    );

CREATE POLICY "ward_supervisor_issues_update" ON public.issues
    FOR UPDATE
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND ward_id = public.get_user_ward_id()
    )
    WITH CHECK (
        public.get_user_role() = 'ward_supervisor' 
        AND ward_id = public.get_user_ward_id()
    );

-- Worker: access to assigned issues only
CREATE POLICY "worker_issues_select" ON public.issues
    FOR SELECT
    USING (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    );

CREATE POLICY "worker_issues_update" ON public.issues
    FOR UPDATE
    USING (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    )
    WITH CHECK (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    );

-- Citizens: can create issues and view their own
CREATE POLICY "citizen_issues_insert" ON public.issues
    FOR INSERT
    WITH CHECK (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    );

CREATE POLICY "citizen_issues_select" ON public.issues
    FOR SELECT
    USING (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    );

CREATE POLICY "citizen_issues_update" ON public.issues
    FOR UPDATE
    USING (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    )
    WITH CHECK (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    );

CREATE POLICY "citizen_issues_delete" ON public.issues
    FOR DELETE
    USING (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    );

-- Everyone can view all issues (for public feed)
CREATE POLICY "issues_public_select" ON public.issues
    FOR SELECT
    USING (true);

-- ============================================================================
-- RLS POLICIES: assignments table
-- ============================================================================

-- State admin: full access
CREATE POLICY "state_admin_assignments_all" ON public.assignments
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- City admin: access to assignments in their city
CREATE POLICY "city_admin_assignments_select" ON public.assignments
    FOR SELECT
    USING (
        public.get_user_role() = 'city_admin' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = assignments.issue_id 
            AND issues.city_id = public.get_user_city_id()
        )
    );

-- Ward supervisor: can create and view assignments in their ward
CREATE POLICY "ward_supervisor_assignments_insert" ON public.assignments
    FOR INSERT
    WITH CHECK (
        public.get_user_role() = 'ward_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = issue_id 
            AND issues.ward_id = public.get_user_ward_id()
        )
    );

CREATE POLICY "ward_supervisor_assignments_select" ON public.assignments
    FOR SELECT
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = assignments.issue_id 
            AND issues.ward_id = public.get_user_ward_id()
        )
    );

-- Worker: can view and update their own assignments
CREATE POLICY "worker_assignments_select" ON public.assignments
    FOR SELECT
    USING (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    );

CREATE POLICY "worker_assignments_update" ON public.assignments
    FOR UPDATE
    USING (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    )
    WITH CHECK (
        public.get_user_role() = 'worker' 
        AND assigned_to = auth.uid()
    );

-- ============================================================================
-- RLS POLICIES: audit_logs table
-- ============================================================================

-- State admin: full access
CREATE POLICY "state_admin_audit_logs_all" ON public.audit_logs
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- City admin: view audit logs for issues in their city
CREATE POLICY "city_admin_audit_logs_select" ON public.audit_logs
    FOR SELECT
    USING (
        public.get_user_role() = 'city_admin' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = audit_logs.issue_id 
            AND issues.city_id = public.get_user_city_id()
        )
    );

-- Ward supervisor: view audit logs for issues in their ward
CREATE POLICY "ward_supervisor_audit_logs_select" ON public.audit_logs
    FOR SELECT
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = audit_logs.issue_id 
            AND issues.ward_id = public.get_user_ward_id()
        )
    );

-- CRC supervisor: view audit logs for issues in their zone
CREATE POLICY "crc_supervisor_audit_logs_select" ON public.audit_logs
    FOR SELECT
    USING (
        public.get_user_role() = 'crc_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.issues 
            WHERE issues.id = audit_logs.issue_id 
            AND issues.zone_id = public.get_user_zone_id()
        )
    );

-- ============================================================================
-- RLS POLICIES: votes table
-- ============================================================================

-- Citizens can vote
CREATE POLICY "citizen_votes_insert" ON public.votes
    FOR INSERT
    WITH CHECK (
        public.get_user_role() = 'citizen' 
        AND user_id = auth.uid()
    );

-- Everyone can view votes
CREATE POLICY "votes_select_all" ON public.votes
    FOR SELECT
    USING (true);

-- Users can delete their own votes
CREATE POLICY "users_votes_delete" ON public.votes
    FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================================
-- RLS POLICIES: contractor_profiles table
-- ============================================================================

-- State admin: full access
CREATE POLICY "state_admin_contractor_profiles_all" ON public.contractor_profiles
    FOR ALL
    USING (public.get_user_role() = 'state_admin')
    WITH CHECK (public.get_user_role() = 'state_admin');

-- City admin: access to contractors in their city
CREATE POLICY "city_admin_contractor_profiles_select" ON public.contractor_profiles
    FOR SELECT
    USING (
        public.get_user_role() = 'city_admin' 
        AND EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = contractor_profiles.user_id 
            AND users.city_id = public.get_user_city_id()
        )
    );

-- Ward supervisor: access to contractors in their ward
CREATE POLICY "ward_supervisor_contractor_profiles_select" ON public.contractor_profiles
    FOR SELECT
    USING (
        public.get_user_role() = 'ward_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = contractor_profiles.user_id 
            AND users.ward_id = public.get_user_ward_id()
        )
    );

CREATE POLICY "ward_supervisor_contractor_profiles_insert" ON public.contractor_profiles
    FOR INSERT
    WITH CHECK (
        public.get_user_role() = 'ward_supervisor' 
        AND EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = user_id 
            AND users.ward_id = public.get_user_ward_id()
        )
    );

-- Workers can view their own profile
CREATE POLICY "worker_contractor_profiles_select" ON public.contractor_profiles
    FOR SELECT
    USING (
        public.get_user_role() = 'worker' 
        AND user_id = auth.uid()
    );
