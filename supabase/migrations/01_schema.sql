-- SewaMitr Database Schema
-- Migration 01: Core Tables with PostGIS Support
-- Compatible with Flutter citizen and worker apps

-- Enable PostGIS extension for geography support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
-- Mirrors auth.users and adds role-based fields
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('citizen', 'worker', 'ward_supervisor', 'crc_supervisor', 'city_admin', 'state_admin')),
    city_id UUID,
    ward_id UUID,
    zone_id UUID,
    phone TEXT,
    photo_url TEXT,
    language TEXT DEFAULT 'en',
    total_reports INTEGER DEFAULT 0,
    resolved_issues INTEGER DEFAULT 0,
    community_rank INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_city_id ON public.users(city_id);
CREATE INDEX idx_users_ward_id ON public.users(ward_id);
CREATE INDEX idx_users_zone_id ON public.users(zone_id);

-- ============================================================================
-- CITIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    state TEXT DEFAULT 'Jharkhand',
    center GEOGRAPHY(POINT, 4326),
    population INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cities_name ON public.cities(name);
CREATE INDEX idx_cities_center ON public.cities USING GIST(center);

-- ============================================================================
-- WARDS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.wards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    city_id UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
    polygon GEOGRAPHY(POLYGON, 4326),
    centroid GEOGRAPHY(POINT, 4326),
    population INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wards_city_id ON public.wards(city_id);
CREATE INDEX idx_wards_polygon ON public.wards USING GIST(polygon);
CREATE INDEX idx_wards_centroid ON public.wards USING GIST(centroid);

-- ============================================================================
-- ZONES TABLE (CRC Zones - cluster of 2-3 wards)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    city_id UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
    ward_ids UUID[] NOT NULL,
    polygon GEOGRAPHY(MULTIPOLYGON, 4326),
    supervisor_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_zones_city_id ON public.zones(city_id);
CREATE INDEX idx_zones_supervisor ON public.zones(supervisor_user_id);
CREATE INDEX idx_zones_polygon ON public.zones USING GIST(polygon);

-- ============================================================================
-- ISSUES TABLE
-- ============================================================================
-- Compatible with Flutter apps: preserves latitude, longitude, media_urls, audio_url, status, progress, assigned_to
CREATE TABLE IF NOT EXISTS public.issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    city_id UUID REFERENCES public.cities(id) ON DELETE SET NULL,
    ward_id UUID REFERENCES public.wards(id) ON DELETE SET NULL,
    zone_id UUID REFERENCES public.zones(id) ON DELETE SET NULL,
    
    -- Issue details
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    
    -- Location (Flutter compatibility)
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    location GEOGRAPHY(POINT, 4326), -- Auto-populated by trigger
    
    -- Media (Flutter compatibility)
    media_urls TEXT[] DEFAULT '{}',
    audio_url TEXT,
    
    -- Status and priority
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'crc_verified', 'forwarded_to_ward', 'in_progress', 'resolved', 'rejected')),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    
    -- Assignment (Flutter compatibility)
    assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    -- SLA tracking
    sla_allowed_hours INTEGER,
    sla_due_at TIMESTAMPTZ,
    
    -- Upvotes (Flutter compatibility)
    upvotes INTEGER DEFAULT 0,
    
    -- Update logs (Flutter worker app compatibility)
    update_logs JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_issues_user_id ON public.issues(user_id);
CREATE INDEX idx_issues_city_id ON public.issues(city_id);
CREATE INDEX idx_issues_ward_id ON public.issues(ward_id);
CREATE INDEX idx_issues_zone_id ON public.issues(zone_id);
CREATE INDEX idx_issues_status ON public.issues(status);
CREATE INDEX idx_issues_category ON public.issues(category);
CREATE INDEX idx_issues_priority ON public.issues(priority);
CREATE INDEX idx_issues_assigned_to ON public.issues(assigned_to);
CREATE INDEX idx_issues_location ON public.issues USING GIST(location);
CREATE INDEX idx_issues_created_at ON public.issues(created_at DESC);
CREATE INDEX idx_issues_sla_due_at ON public.issues(sla_due_at);

-- ============================================================================
-- ASSIGNMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
    assigned_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    eta TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    history JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_assignments_issue_id ON public.assignments(issue_id);
CREATE INDEX idx_assignments_assigned_to ON public.assignments(assigned_to);
CREATE INDEX idx_assignments_assigned_by ON public.assignments(assigned_by);
CREATE INDEX idx_assignments_status ON public.assignments(status);

-- ============================================================================
-- AUDIT LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID REFERENCES public.issues(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    performed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    old_data JSONB,
    new_data JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_issue_id ON public.audit_logs(issue_id);
CREATE INDEX idx_audit_logs_performed_by ON public.audit_logs(performed_by);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- ============================================================================
-- VOTES TABLE (Flutter citizen app compatibility)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(issue_id, user_id)
);

CREATE INDEX idx_votes_issue_id ON public.votes(issue_id);
CREATE INDEX idx_votes_user_id ON public.votes(user_id);

-- ============================================================================
-- CONTRACTOR PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.contractor_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    specializations TEXT[] DEFAULT '{}',
    active_assignments INTEGER DEFAULT 0,
    completed_assignments INTEGER DEFAULT 0,
    rating NUMERIC(3, 2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_contractor_profiles_user_id ON public.contractor_profiles(user_id);
CREATE INDEX idx_contractor_profiles_rating ON public.contractor_profiles(rating DESC);

-- ============================================================================
-- ADD FOREIGN KEY CONSTRAINTS TO USERS TABLE
-- ============================================================================
-- (Must be added after cities, wards, zones are created)
ALTER TABLE public.users ADD CONSTRAINT fk_users_city_id FOREIGN KEY (city_id) REFERENCES public.cities(id) ON DELETE SET NULL;
ALTER TABLE public.users ADD CONSTRAINT fk_users_ward_id FOREIGN KEY (ward_id) REFERENCES public.wards(id) ON DELETE SET NULL;
ALTER TABLE public.users ADD CONSTRAINT fk_users_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contractor_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE public.users IS 'User profiles with role-based access';
COMMENT ON TABLE public.cities IS 'Cities in Jharkhand';
COMMENT ON TABLE public.wards IS 'Wards within cities';
COMMENT ON TABLE public.zones IS 'CRC zones (clusters of 2-3 wards)';
COMMENT ON TABLE public.issues IS 'Civic issues reported by citizens';
COMMENT ON TABLE public.assignments IS 'Issue assignments to contractors';
COMMENT ON TABLE public.audit_logs IS 'Audit trail for issue changes';
COMMENT ON TABLE public.votes IS 'Citizen upvotes for issues';
COMMENT ON TABLE public.contractor_profiles IS 'Contractor/worker profiles';
