-- Modified User Seed Script
-- This version removes the auth.users dependency for testing
-- Users will be created in public.users only (for demo/testing purposes)

-- IMPORTANT: In production, you should:
-- 1. Create users via Supabase Dashboard → Authentication → Users
-- 2. The trigger will auto-sync them to public.users
-- 3. Or use Supabase API to create auth users programmatically

-- For now, we'll modify the schema to make auth.users optional for seeding

-- Temporarily disable the foreign key constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- Now run the original 06_seed_users_roles.sql content here
-- (The INSERT statements from the original file)

-- After seeding, you can optionally re-enable the constraint
-- But leave it disabled if you want to test without creating auth users
-- ALTER TABLE public.users ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
