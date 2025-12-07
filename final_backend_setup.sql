-- ============================================================================
-- FINAL BACKEND SETUP SCRIPT
-- Run this in your Supabase SQL Editor to ensure everything works!
-- ============================================================================

-- 1. Ensure Storage Bucket Exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('sewamitr', 'sewamitr', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS on Objects (Skipped to avoid permission errors - typically enabled by default)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Allow Public Access to 'sewamitr' bucket
-- (This allows anyone to read/write, you can tighten this later if needed)
CREATE POLICY "Public Access"
ON storage.objects FOR ALL
USING ( bucket_id = 'sewamitr' )
WITH CHECK ( bucket_id = 'sewamitr' );

-- 4. Add Missing 'audio_description' Column
-- (Required for User App voice notes)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'issues' AND column_name = 'audio_description') THEN
        ALTER TABLE public.issues ADD COLUMN audio_description TEXT;
        COMMENT ON COLUMN public.issues.audio_description IS 'Transcribed text from audio recording';
    END IF;
END $$;

-- 5. Verify Priority Column (Should already exist, but safe check)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'issues' AND column_name = 'priority') THEN
        ALTER TABLE public.issues ADD COLUMN priority TEXT DEFAULT 'medium';
    END IF;
END $$;

-- 6. Verify Update Logs Column (Should already exist, but safe check)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'issues' AND column_name = 'update_logs') THEN
        ALTER TABLE public.issues ADD COLUMN update_logs JSONB DEFAULT '[]';
    END IF;
END $$;
