-- Create Auth Users First
-- Run this BEFORE 06_seed_users_roles.sql
-- This creates users in auth.users so they can be referenced in public.users

-- IMPORTANT: After running this, users must set their passwords via Supabase Dashboard
-- or use the Supabase API to set passwords programmatically

-- State Admin
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
) VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'state.admin@sewamitr.in',
    crypt('SewaMitr@2024', gen_salt('bf')), -- Password: SewaMitr@2024
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    false,
    'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- Note: Creating all 134 users this way is tedious
-- Better approach: Skip this migration and create users via Supabase Dashboard or API
