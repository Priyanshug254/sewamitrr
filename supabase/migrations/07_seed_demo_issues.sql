-- SewaMitr Seed Data: Demo Issues
-- Migration 07: 200+ realistic demo issues

-- ============================================================================
-- SEED DEMO ISSUES (200 issues distributed across cities)
-- ============================================================================
DO $$
DECLARE
    v_categories TEXT[] := ARRAY[
        'Pothole', 'Drainage', 'Streetlight', 'Waste Management', 
        'Water Supply', 'Sanitation', 'Road Repair', 'Tree Maintenance',
        'Traffic Sign', 'Public Toilet', 'Park Maintenance', 'Illegal Dumping'
    ];
    v_priorities TEXT[] := ARRAY['low', 'medium', 'high', 'critical'];
    v_statuses TEXT[] := ARRAY['submitted', 'crc_verified', 'forwarded_to_ward', 'in_progress', 'resolved'];
    v_cities RECORD;
    v_wards RECORD;
    v_citizen_ids UUID[];
    v_worker_ids UUID[];
    v_counter INTEGER := 1;
    v_issue_id UUID;
    v_category TEXT;
    v_priority TEXT;
    v_status TEXT;
    v_citizen_id UUID;
    v_worker_id UUID;
    v_lat NUMERIC;
    v_lng NUMERIC;
    v_description TEXT;
    v_media_urls TEXT[];
BEGIN
    -- Get citizen IDs
    SELECT array_agg(id) INTO v_citizen_ids FROM public.users WHERE role = 'citizen';
    
    -- Get worker IDs
    SELECT array_agg(id) INTO v_worker_ids FROM public.users WHERE role = 'worker';
    
    -- Create issues for each city
    FOR v_cities IN SELECT id, name, ST_Y(center::geometry) as lat, ST_X(center::geometry) as lng FROM public.cities LOOP
        -- Create 60-70 issues per city
        FOR v_counter IN 1..((60 + (random() * 10))::INTEGER) LOOP
            v_issue_id := uuid_generate_v4();
            v_category := v_categories[(random() * (array_length(v_categories, 1) - 1) + 1)::INTEGER];
            v_priority := v_priorities[(random() * (array_length(v_priorities, 1) - 1) + 1)::INTEGER];
            v_status := v_statuses[(random() * (array_length(v_statuses, 1) - 1) + 1)::INTEGER];
            v_citizen_id := v_citizen_ids[(random() * (array_length(v_citizen_ids, 1) - 1) + 1)::INTEGER];
            
            -- Random location within city bounds (±0.05 degrees)
            v_lat := v_cities.lat + (random() * 0.1 - 0.05);
            v_lng := v_cities.lng + (random() * 0.1 - 0.05);
            
            -- Generate description based on category
            v_description := CASE v_category
                WHEN 'Pothole' THEN 'Large pothole on road causing traffic issues'
                WHEN 'Drainage' THEN 'Clogged drainage system causing water stagnation'
                WHEN 'Streetlight' THEN 'Broken streetlight needs immediate repair'
                WHEN 'Waste Management' THEN 'Garbage not collected for several days'
                WHEN 'Water Supply' THEN 'Water pipeline leak causing wastage'
                WHEN 'Sanitation' THEN 'Public toilet in poor condition'
                WHEN 'Road Repair' THEN 'Road surface damaged and needs repair'
                WHEN 'Tree Maintenance' THEN 'Tree branches blocking pathway'
                WHEN 'Traffic Sign' THEN 'Missing or damaged traffic sign'
                WHEN 'Public Toilet' THEN 'Public toilet requires maintenance'
                WHEN 'Park Maintenance' THEN 'Park equipment broken or damaged'
                WHEN 'Illegal Dumping' THEN 'Illegal waste dumping in public area'
                ELSE 'Issue reported by citizen'
            END;
            
            -- Generate 1-3 media URLs
            v_media_urls := ARRAY[
                'https://wncfoybbezszisxdebme.supabase.co/storage/v1/object/public/sewamitr/issues/' || v_issue_id || '/photo1.jpg'
            ];
            IF random() > 0.5 THEN
                v_media_urls := array_append(v_media_urls, 
                    'https://wncfoybbezszisxdebme.supabase.co/storage/v1/object/public/sewamitr/issues/' || v_issue_id || '/photo2.jpg'
                );
            END IF;
            IF random() > 0.7 THEN
                v_media_urls := array_append(v_media_urls, 
                    'https://wncfoybbezszisxdebme.supabase.co/storage/v1/object/public/sewamitr/issues/' || v_issue_id || '/photo3.jpg'
                );
            END IF;
            
            -- Assign worker if status is in_progress or resolved
            v_worker_id := NULL;
            IF v_status IN ('in_progress', 'resolved') THEN
                v_worker_id := v_worker_ids[(random() * (array_length(v_worker_ids, 1) - 1) + 1)::INTEGER];
            END IF;
            
            -- Insert issue
            INSERT INTO public.issues (
                id, user_id, category, description, address,
                latitude, longitude, media_urls,
                audio_url, priority, status, progress,
                assigned_to, upvotes, created_at, updated_at
            ) VALUES (
                v_issue_id,
                v_citizen_id,
                v_category,
                v_description,
                v_cities.name || ' Ward Area',
                v_lat,
                v_lng,
                v_media_urls,
                CASE WHEN random() > 0.8 THEN 
                    'https://wncfoybbezszisxdebme.supabase.co/storage/v1/object/public/sewamitr/audio/' || v_issue_id || '/audio.m4a'
                ELSE NULL END,
                v_priority,
                v_status,
                CASE v_status
                    WHEN 'submitted' THEN 0
                    WHEN 'crc_verified' THEN 10
                    WHEN 'forwarded_to_ward' THEN 20
                    WHEN 'in_progress' THEN (30 + (random() * 60))::INTEGER
                    WHEN 'resolved' THEN 100
                    ELSE 0
                END,
                v_worker_id,
                (random() * 20)::INTEGER,
                NOW() - (random() * INTERVAL '30 days'),
                NOW() - (random() * INTERVAL '15 days')
            );
            
            -- Create assignment if worker assigned
            IF v_worker_id IS NOT NULL THEN
                INSERT INTO public.assignments (
                    issue_id, assigned_by, assigned_to, eta, status, created_at
                )
                SELECT 
                    v_issue_id,
                    (SELECT id FROM public.users WHERE role = 'ward_supervisor' LIMIT 1),
                    v_worker_id,
                    NOW() + INTERVAL '2 days',
                    CASE v_status
                        WHEN 'in_progress' THEN 'in_progress'
                        WHEN 'resolved' THEN 'completed'
                        ELSE 'accepted'
                    END,
                    NOW() - (random() * INTERVAL '10 days');
            END IF;
            
            -- Add some votes
            IF random() > 0.6 THEN
                INSERT INTO public.votes (issue_id, user_id, created_at)
                SELECT 
                    v_issue_id,
                    unnest(v_citizen_ids[1:(random() * 5 + 1)::INTEGER]),
                    NOW() - (random() * INTERVAL '20 days')
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
    END LOOP;
    
    -- Update user stats
    UPDATE public.users u
    SET 
        total_reports = (SELECT COUNT(*) FROM public.issues WHERE user_id = u.id),
        resolved_issues = (SELECT COUNT(*) FROM public.issues WHERE user_id = u.id AND status = 'resolved')
    WHERE role = 'citizen';
    
    -- Update contractor stats
    UPDATE public.contractor_profiles cp
    SET 
        active_assignments = (
            SELECT COUNT(*) FROM public.assignments 
            WHERE assigned_to = cp.user_id AND status IN ('pending', 'accepted', 'in_progress')
        ),
        completed_assignments = (
            SELECT COUNT(*) FROM public.assignments 
            WHERE assigned_to = cp.user_id AND status = 'completed'
        );
END $$;
