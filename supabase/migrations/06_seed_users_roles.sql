-- SewaMitr Seed Data: Users and Roles
-- Migration 06: Seed users across all roles

-- NOTE: This file only creates entries in public.users table.
-- For demo/testing purposes, we temporarily disable the auth.users foreign key constraint.
-- In production, create auth users via Supabase Dashboard first, then they auto-sync to public.users.
-- See CREDENTIALS.md for the list of users to create in auth.users.

-- Temporarily disable foreign key constraint to allow seeding without auth users
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- ============================================================================
-- SEED STATE ADMIN
-- ============================================================================
INSERT INTO public.users (id, email, full_name, role, phone, language, created_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID, 'state.admin@sewamitr.in', 'Rajesh Kumar', 'state_admin', '+919876543210', 'en', NOW());

-- ============================================================================
-- SEED CITY ADMINS (one per city)
-- ============================================================================
INSERT INTO public.users (id, email, full_name, role, city_id, phone, language, created_at) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID, 'ranchi.admin@sewamitr.in', 'Priya Sharma', 'city_admin', '11111111-1111-1111-1111-111111111111'::UUID, '+919876543211', 'en', NOW()),
('cccccccc-cccc-cccc-cccc-cccccccccccc'::UUID, 'dhanbad.admin@sewamitr.in', 'Amit Singh', 'city_admin', '22222222-2222-2222-2222-222222222222'::UUID, '+919876543212', 'en', NOW()),
('dddddddd-dddd-dddd-dddd-dddddddddddd'::UUID, 'jamshedpur.admin@sewamitr.in', 'Sunita Devi', 'city_admin', '33333333-3333-3333-3333-333333333333'::UUID, '+919876543213', 'en', NOW());

-- ============================================================================
-- SEED CRC SUPERVISORS (distributed across zones)
-- ============================================================================
-- Ranchi CRC Supervisors (20 zones → 20 supervisors)
DO $$
DECLARE
    v_zone RECORD;
    v_counter INTEGER := 1;
    v_user_id UUID;
BEGIN
    FOR v_zone IN 
        SELECT id, name FROM public.zones 
        WHERE city_id = '11111111-1111-1111-1111-111111111111'::UUID 
        ORDER BY name
    LOOP
        v_user_id := uuid_generate_v4();
        
        INSERT INTO public.users (id, email, full_name, role, city_id, zone_id, phone, language, created_at)
        VALUES (
            v_user_id,
            'crc.ranchi.' || v_counter || '@sewamitr.in',
            'CRC Supervisor Ranchi ' || v_counter,
            'crc_supervisor',
            '11111111-1111-1111-1111-111111111111'::UUID,
            v_zone.id,
            '+9198765432' || (13 + v_counter),
            'en',
            NOW()
        );
        
        -- Update zone with supervisor
        UPDATE public.zones SET supervisor_user_id = v_user_id WHERE id = v_zone.id;
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- Dhanbad CRC Supervisors
DO $$
DECLARE
    v_zone RECORD;
    v_counter INTEGER := 1;
    v_user_id UUID;
BEGIN
    FOR v_zone IN 
        SELECT id, name FROM public.zones 
        WHERE city_id = '22222222-2222-2222-2222-222222222222'::UUID 
        ORDER BY name
    LOOP
        v_user_id := uuid_generate_v4();
        
        INSERT INTO public.users (id, email, full_name, role, city_id, zone_id, phone, language, created_at)
        VALUES (
            v_user_id,
            'crc.dhanbad.' || v_counter || '@sewamitr.in',
            'CRC Supervisor Dhanbad ' || v_counter,
            'crc_supervisor',
            '22222222-2222-2222-2222-222222222222'::UUID,
            v_zone.id,
            '+9198765433' || (13 + v_counter),
            'en',
            NOW()
        );
        
        UPDATE public.zones SET supervisor_user_id = v_user_id WHERE id = v_zone.id;
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- Jamshedpur CRC Supervisors
DO $$
DECLARE
    v_zone RECORD;
    v_counter INTEGER := 1;
    v_user_id UUID;
BEGIN
    FOR v_zone IN 
        SELECT id, name FROM public.zones 
        WHERE city_id = '33333333-3333-3333-3333-333333333333'::UUID 
        ORDER BY name
    LOOP
        v_user_id := uuid_generate_v4();
        
        INSERT INTO public.users (id, email, full_name, role, city_id, zone_id, phone, language, created_at)
        VALUES (
            v_user_id,
            'crc.jamshedpur.' || v_counter || '@sewamitr.in',
            'CRC Supervisor Jamshedpur ' || v_counter,
            'crc_supervisor',
            '33333333-3333-3333-3333-333333333333'::UUID,
            v_zone.id,
            '+9198765434' || (13 + v_counter),
            'en',
            NOW()
        );
        
        UPDATE public.zones SET supervisor_user_id = v_user_id WHERE id = v_zone.id;
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- ============================================================================
-- SEED WARD SUPERVISORS (subset of wards - 30 total)
-- ============================================================================
-- Ranchi Ward Supervisors (10 wards)
DO $$
DECLARE
    v_ward RECORD;
    v_counter INTEGER := 1;
BEGIN
    FOR v_ward IN 
        SELECT id, name, city_id FROM public.wards 
        WHERE city_id = '11111111-1111-1111-1111-111111111111'::UUID 
        ORDER BY name
        LIMIT 10
    LOOP
        INSERT INTO public.users (id, email, full_name, role, city_id, ward_id, phone, language, created_at)
        VALUES (
            uuid_generate_v4(),
            'ward.ranchi.' || v_counter || '@sewamitr.in',
            'Ward Supervisor Ranchi ' || v_counter,
            'ward_supervisor',
            v_ward.city_id,
            v_ward.id,
            '+9198765435' || (13 + v_counter),
            'en',
            NOW()
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- Dhanbad Ward Supervisors (10 wards)
DO $$
DECLARE
    v_ward RECORD;
    v_counter INTEGER := 1;
BEGIN
    FOR v_ward IN 
        SELECT id, name, city_id FROM public.wards 
        WHERE city_id = '22222222-2222-2222-2222-222222222222'::UUID 
        ORDER BY name
        LIMIT 10
    LOOP
        INSERT INTO public.users (id, email, full_name, role, city_id, ward_id, phone, language, created_at)
        VALUES (
            uuid_generate_v4(),
            'ward.dhanbad.' || v_counter || '@sewamitr.in',
            'Ward Supervisor Dhanbad ' || v_counter,
            'ward_supervisor',
            v_ward.city_id,
            v_ward.id,
            '+9198765436' || (13 + v_counter),
            'en',
            NOW()
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- Jamshedpur Ward Supervisors (10 wards)
DO $$
DECLARE
    v_ward RECORD;
    v_counter INTEGER := 1;
BEGIN
    FOR v_ward IN 
        SELECT id, name, city_id FROM public.wards 
        WHERE city_id = '33333333-3333-3333-3333-333333333333'::UUID 
        ORDER BY name
        LIMIT 10
    LOOP
        INSERT INTO public.users (id, email, full_name, role, city_id, ward_id, phone, language, created_at)
        VALUES (
            uuid_generate_v4(),
            'ward.jamshedpur.' || v_counter || '@sewamitr.in',
            'Ward Supervisor Jamshedpur ' || v_counter,
            'ward_supervisor',
            v_ward.city_id,
            v_ward.id,
            '+9198765437' || (13 + v_counter),
            'en',
            NOW()
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END $$;

-- ============================================================================
-- SEED CONTRACTORS/WORKERS (50 total - distributed across cities)
-- ============================================================================
DO $$
DECLARE
    v_city_ids UUID[] := ARRAY[
        '11111111-1111-1111-1111-111111111111'::UUID,
        '22222222-2222-2222-2222-222222222222'::UUID,
        '33333333-3333-3333-3333-333333333333'::UUID
    ];
    v_city_names TEXT[] := ARRAY['Ranchi', 'Dhanbad', 'Jamshedpur'];
    v_city_idx INTEGER;
    v_counter INTEGER;
    v_user_id UUID;
    v_specializations TEXT[];
    v_all_specializations TEXT[] := ARRAY[
        'Pothole Repair',
        'Drainage Cleaning',
        'Streetlight Maintenance',
        'Waste Management',
        'Water Supply',
        'Sanitation',
        'Road Repair',
        'Tree Maintenance'
    ];
BEGIN
    FOR v_counter IN 1..50 LOOP
        v_city_idx := ((v_counter - 1) % 3) + 1;
        v_user_id := uuid_generate_v4();
        
        -- Random 2-3 specializations
        v_specializations := ARRAY[
            v_all_specializations[(random() * 7 + 1)::INTEGER],
            v_all_specializations[(random() * 7 + 1)::INTEGER]
        ];
        
        INSERT INTO public.users (id, email, full_name, role, city_id, phone, language, created_at)
        VALUES (
            v_user_id,
            'worker.' || v_city_names[v_city_idx] || '.' || v_counter || '@sewamitr.in',
            'Worker ' || v_city_names[v_city_idx] || ' ' || v_counter,
            'worker',
            v_city_ids[v_city_idx],
            '+9198765438' || (13 + v_counter),
            'en',
            NOW()
        );
        
        -- Create contractor profile
        INSERT INTO public.contractor_profiles (user_id, specializations, rating)
        VALUES (
            v_user_id,
            v_specializations,
            3.5 + (random() * 1.5)
        );
    END LOOP;
END $$;

-- ============================================================================
-- SEED CITIZENS (50 total - distributed across cities)
-- ============================================================================
DO $$
DECLARE
    v_city_ids UUID[] := ARRAY[
        '11111111-1111-1111-1111-111111111111'::UUID,
        '22222222-2222-2222-2222-222222222222'::UUID,
        '33333333-3333-3333-3333-333333333333'::UUID
    ];
    v_city_names TEXT[] := ARRAY['Ranchi', 'Dhanbad', 'Jamshedpur'];
    v_city_idx INTEGER;
    v_counter INTEGER;
BEGIN
    FOR v_counter IN 1..50 LOOP
        v_city_idx := ((v_counter - 1) % 3) + 1;
        
        INSERT INTO public.users (id, email, full_name, role, city_id, phone, language, total_reports, points, created_at)
        VALUES (
            uuid_generate_v4(),
            'citizen.' || v_city_names[v_city_idx] || '.' || v_counter || '@sewamitr.in',
            'Citizen ' || v_city_names[v_city_idx] || ' ' || v_counter,
            'citizen',
            v_city_ids[v_city_idx],
            '+9198765439' || (13 + v_counter),
            CASE WHEN random() > 0.5 THEN 'hi' ELSE 'en' END,
            (random() * 10)::INTEGER,
            (random() * 100)::INTEGER,
            NOW() - (random() * INTERVAL '90 days')
        );
    END LOOP;
END $$;
