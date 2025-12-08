-- ============================================================================
-- FIX USER PROFILE NAME FIELD MISMATCH
-- User App expects 'name' but database has 'full_name'
-- ============================================================================

-- Option 1: Add 'name' column as alias to 'full_name'
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS name TEXT;

-- Copy full_name to name for existing users
UPDATE public.users 
SET name = full_name 
WHERE name IS NULL;

-- Create trigger to keep them in sync
CREATE OR REPLACE FUNCTION sync_user_name()
RETURNS TRIGGER AS $$
BEGIN
  -- If full_name is updated, update name
  IF NEW.full_name IS DISTINCT FROM OLD.full_name THEN
    NEW.name := NEW.full_name;
  END IF;
  -- If name is updated, update full_name
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    NEW.full_name := NEW.name;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_user_name_trigger ON public.users;
CREATE TRIGGER sync_user_name_trigger
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION sync_user_name();

-- Also update the handle_new_user function to set both fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_name TEXT;
BEGIN
  user_name := COALESCE(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'User');
  
  INSERT INTO public.users (id, email, full_name, name, role, language)
  VALUES (
    new.id, 
    new.email,
    user_name,
    user_name,
    COALESCE(new.raw_user_meta_data->>'role', 'citizen'),
    COALESCE(new.raw_user_meta_data->>'language', 'en')
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    name = EXCLUDED.name,
    updated_at = NOW();
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON COLUMN public.users.name IS 'Alias for full_name to maintain compatibility with Flutter apps';
