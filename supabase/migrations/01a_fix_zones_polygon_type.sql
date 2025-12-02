-- Fix for zones polygon type
-- This migration updates the zones table to accept MULTIPOLYGON instead of POLYGON
-- Required because ST_Union can create MultiPolygon geometries

ALTER TABLE public.zones 
ALTER COLUMN polygon TYPE GEOGRAPHY(MULTIPOLYGON, 4326);

-- Verify the change
COMMENT ON COLUMN public.zones.polygon IS 'Zone boundary (can be Polygon or MultiPolygon from ST_Union)';
