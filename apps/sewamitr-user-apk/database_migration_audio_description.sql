-- Add audio_description column to issues table
-- This column stores the transcribed text from voice recordings

ALTER TABLE issues 
ADD COLUMN IF NOT EXISTS audio_description TEXT;

-- Add comment to document the column
COMMENT ON COLUMN issues.audio_description IS 'Transcribed text from audio recording using speech-to-text';
