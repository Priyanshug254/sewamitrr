-- SewaMitr Seed Data: Cities, Wards, and Zones
-- Migration 05: Jharkhand geography with realistic ward counts

-- ============================================================================
-- SEED CITIES
-- ============================================================================
-- Ranchi: Capital city with 55 wards
-- Dhanbad: Coal capital with 53 wards  
-- Jamshedpur: Industrial city with 60 wards

INSERT INTO public.cities (id, name, state, center, population, metadata) VALUES
(
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Ranchi',
    'Jharkhand',
    ST_SetSRID(ST_MakePoint(85.3096, 23.3441), 4326)::geography,
    1126741,
    '{"capital": true, "district": "Ranchi"}'::jsonb
),
(
    '22222222-2222-2222-2222-222222222222'::UUID,
    'Dhanbad',
    'Jharkhand',
    ST_SetSRID(ST_MakePoint(86.4304, 23.7957), 4326)::geography,
    1162472,
    '{"district": "Dhanbad", "known_for": "Coal Capital"}'::jsonb
),
(
    '33333333-3333-3333-3333-333333333333'::UUID,
    'Jamshedpur',
    'Jharkhand',
    ST_SetSRID(ST_MakePoint(86.1842, 22.8046), 4326)::geography,
    1337131,
    '{"district": "East Singhbhum", "known_for": "Steel City"}'::jsonb
);

-- ============================================================================
-- SEED WARDS FOR RANCHI (55 wards)
-- ============================================================================
-- Creating realistic ward boundaries around Ranchi center (23.3441, 85.3096)
-- Wards are distributed in a grid pattern with slight variations

DO $$
DECLARE
    v_city_id UUID := '11111111-1111-1111-1111-111111111111'::UUID;
    v_base_lat NUMERIC := 23.3441;
    v_base_lng NUMERIC := 85.3096;
    v_ward_num INTEGER;
    v_lat_offset NUMERIC;
    v_lng_offset NUMERIC;
    v_ward_id UUID;
    v_polygon GEOGRAPHY;
    v_centroid GEOGRAPHY;
BEGIN
    FOR v_ward_num IN 1..55 LOOP
        -- Calculate grid position (7x8 grid approximately)
        v_lat_offset := ((v_ward_num - 1) / 8) * 0.02 - 0.07;
        v_lng_offset := ((v_ward_num - 1) % 8) * 0.02 - 0.07;
        
        -- Create ward polygon (approximately 2km x 2km)
        v_polygon := ST_SetSRID(
            ST_MakePolygon(
                ST_MakeLine(ARRAY[
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset)
                ])
            ),
            4326
        )::geography;
        
        v_centroid := ST_SetSRID(
            ST_MakePoint(v_base_lng + v_lng_offset + 0.009, v_base_lat + v_lat_offset + 0.009),
            4326
        )::geography;
        
        INSERT INTO public.wards (id, name, city_id, polygon, centroid, population)
        VALUES (
            uuid_generate_v4(),
            'Ward ' || v_ward_num,
            v_city_id,
            v_polygon,
            v_centroid,
            20000 + (random() * 10000)::INTEGER
        );
    END LOOP;
END $$;

-- ============================================================================
-- SEED WARDS FOR DHANBAD (53 wards)
-- ============================================================================
DO $$
DECLARE
    v_city_id UUID := '22222222-2222-2222-2222-222222222222'::UUID;
    v_base_lat NUMERIC := 23.7957;
    v_base_lng NUMERIC := 86.4304;
    v_ward_num INTEGER;
    v_lat_offset NUMERIC;
    v_lng_offset NUMERIC;
    v_polygon GEOGRAPHY;
    v_centroid GEOGRAPHY;
BEGIN
    FOR v_ward_num IN 1..53 LOOP
        v_lat_offset := ((v_ward_num - 1) / 8) * 0.02 - 0.065;
        v_lng_offset := ((v_ward_num - 1) % 8) * 0.02 - 0.065;
        
        v_polygon := ST_SetSRID(
            ST_MakePolygon(
                ST_MakeLine(ARRAY[
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset)
                ])
            ),
            4326
        )::geography;
        
        v_centroid := ST_SetSRID(
            ST_MakePoint(v_base_lng + v_lng_offset + 0.009, v_base_lat + v_lat_offset + 0.009),
            4326
        )::geography;
        
        INSERT INTO public.wards (id, name, city_id, polygon, centroid, population)
        VALUES (
            uuid_generate_v4(),
            'Ward ' || v_ward_num,
            v_city_id,
            v_polygon,
            v_centroid,
            21000 + (random() * 10000)::INTEGER
        );
    END LOOP;
END $$;

-- ============================================================================
-- SEED WARDS FOR JAMSHEDPUR (60 wards)
-- ============================================================================
DO $$
DECLARE
    v_city_id UUID := '33333333-3333-3333-3333-333333333333'::UUID;
    v_base_lat NUMERIC := 22.8046;
    v_base_lng NUMERIC := 86.1842;
    v_ward_num INTEGER;
    v_lat_offset NUMERIC;
    v_lng_offset NUMERIC;
    v_polygon GEOGRAPHY;
    v_centroid GEOGRAPHY;
BEGIN
    FOR v_ward_num IN 1..60 LOOP
        v_lat_offset := ((v_ward_num - 1) / 8) * 0.02 - 0.075;
        v_lng_offset := ((v_ward_num - 1) % 8) * 0.02 - 0.075;
        
        v_polygon := ST_SetSRID(
            ST_MakePolygon(
                ST_MakeLine(ARRAY[
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset),
                    ST_MakePoint(v_base_lng + v_lng_offset + 0.018, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset + 0.018),
                    ST_MakePoint(v_base_lng + v_lng_offset, v_base_lat + v_lat_offset)
                ])
            ),
            4326
        )::geography;
        
        v_centroid := ST_SetSRID(
            ST_MakePoint(v_base_lng + v_lng_offset + 0.009, v_base_lat + v_lat_offset + 0.009),
            4326
        )::geography;
        
        INSERT INTO public.wards (id, name, city_id, polygon, centroid, population)
        VALUES (
            uuid_generate_v4(),
            'Ward ' || v_ward_num,
            v_city_id,
            v_polygon,
            v_centroid,
            22000 + (random() * 10000)::INTEGER
        );
    END LOOP;
END $$;

-- ============================================================================
-- CREATE ZONES (CRC) - Cluster 2-3 wards per zone
-- ============================================================================

-- Ranchi Zones (55 wards → ~20 zones)
DO $$
DECLARE
    v_city_id UUID := '11111111-1111-1111-1111-111111111111'::UUID;
    v_ward_ids UUID[];
    v_zone_num INTEGER := 1;
    v_ward_record RECORD;
    v_counter INTEGER := 0;
    v_zone_polygon GEOGRAPHY;
BEGIN
    v_ward_ids := ARRAY[]::UUID[];
    
    FOR v_ward_record IN 
        SELECT id, polygon FROM public.wards WHERE city_id = v_city_id ORDER BY name
    LOOP
        v_ward_ids := array_append(v_ward_ids, v_ward_record.id);
        v_counter := v_counter + 1;
        
        -- Create zone every 3 wards (or 2 for last zone)
        IF v_counter >= 3 OR (v_counter >= 2 AND array_length(v_ward_ids, 1) >= 53) THEN
            -- Create union polygon for zone
            SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
            FROM public.wards
            WHERE id = ANY(v_ward_ids);
            
            INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
            VALUES (
                uuid_generate_v4(),
                'Ranchi CRC Zone ' || v_zone_num,
                v_city_id,
                v_ward_ids,
                v_zone_polygon
            );
            
            v_zone_num := v_zone_num + 1;
            v_ward_ids := ARRAY[]::UUID[];
            v_counter := 0;
        END IF;
    END LOOP;
    
    -- Handle remaining wards
    IF array_length(v_ward_ids, 1) > 0 THEN
        SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
        FROM public.wards
        WHERE id = ANY(v_ward_ids);
        
        INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
        VALUES (
            uuid_generate_v4(),
            'Ranchi CRC Zone ' || v_zone_num,
            v_city_id,
            v_ward_ids,
            v_zone_polygon
        );
    END IF;
END $$;

-- Dhanbad Zones (53 wards → ~18 zones)
DO $$
DECLARE
    v_city_id UUID := '22222222-2222-2222-2222-222222222222'::UUID;
    v_ward_ids UUID[];
    v_zone_num INTEGER := 1;
    v_ward_record RECORD;
    v_counter INTEGER := 0;
    v_zone_polygon GEOGRAPHY;
BEGIN
    v_ward_ids := ARRAY[]::UUID[];
    
    FOR v_ward_record IN 
        SELECT id, polygon FROM public.wards WHERE city_id = v_city_id ORDER BY name
    LOOP
        v_ward_ids := array_append(v_ward_ids, v_ward_record.id);
        v_counter := v_counter + 1;
        
        IF v_counter >= 3 OR (v_counter >= 2 AND array_length(v_ward_ids, 1) >= 51) THEN
            SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
            FROM public.wards
            WHERE id = ANY(v_ward_ids);
            
            INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
            VALUES (
                uuid_generate_v4(),
                'Dhanbad CRC Zone ' || v_zone_num,
                v_city_id,
                v_ward_ids,
                v_zone_polygon
            );
            
            v_zone_num := v_zone_num + 1;
            v_ward_ids := ARRAY[]::UUID[];
            v_counter := 0;
        END IF;
    END LOOP;
    
    IF array_length(v_ward_ids, 1) > 0 THEN
        SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
        FROM public.wards
        WHERE id = ANY(v_ward_ids);
        
        INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
        VALUES (
            uuid_generate_v4(),
            'Dhanbad CRC Zone ' || v_zone_num,
            v_city_id,
            v_ward_ids,
            v_zone_polygon
        );
    END IF;
END $$;

-- Jamshedpur Zones (60 wards → ~20 zones)
DO $$
DECLARE
    v_city_id UUID := '33333333-3333-3333-3333-333333333333'::UUID;
    v_ward_ids UUID[];
    v_zone_num INTEGER := 1;
    v_ward_record RECORD;
    v_counter INTEGER := 0;
    v_zone_polygon GEOGRAPHY;
BEGIN
    v_ward_ids := ARRAY[]::UUID[];
    
    FOR v_ward_record IN 
        SELECT id, polygon FROM public.wards WHERE city_id = v_city_id ORDER BY name
    LOOP
        v_ward_ids := array_append(v_ward_ids, v_ward_record.id);
        v_counter := v_counter + 1;
        
        IF v_counter >= 3 OR (v_counter >= 2 AND array_length(v_ward_ids, 1) >= 58) THEN
            SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
            FROM public.wards
            WHERE id = ANY(v_ward_ids);
            
            INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
            VALUES (
                uuid_generate_v4(),
                'Jamshedpur CRC Zone ' || v_zone_num,
                v_city_id,
                v_ward_ids,
                v_zone_polygon
            );
            
            v_zone_num := v_zone_num + 1;
            v_ward_ids := ARRAY[]::UUID[];
            v_counter := 0;
        END IF;
    END LOOP;
    
    IF array_length(v_ward_ids, 1) > 0 THEN
        SELECT ST_Multi(ST_Union(polygon::geometry))::geography INTO v_zone_polygon
        FROM public.wards
        WHERE id = ANY(v_ward_ids);
        
        INSERT INTO public.zones (id, name, city_id, ward_ids, polygon)
        VALUES (
            uuid_generate_v4(),
            'Jamshedpur CRC Zone ' || v_zone_num,
            v_city_id,
            v_ward_ids,
            v_zone_polygon
        );
    END IF;
END $$;
