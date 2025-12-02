-- Fix RLS to allow fetching supervisor names
-- The previous policy might have been too restrictive or failing
-- This allows any authenticated user (like admins) to read user names/roles
-- This is necessary for the dashboard to show "Supervisor: Name"

CREATE POLICY "allow_read_all_users_basic" ON public.users
    FOR SELECT
    TO authenticated
    USING (true);
