-- Check the current city_id for the user
SELECT id, email, role, city_id FROM public.users WHERE email = 'ranchi.admin@sewamitr.in';

-- Update the city_id for Ranchi Admin
-- First get Ranchi's ID
DO $$
DECLARE
    v_ranchi_id UUID;
BEGIN
    SELECT id INTO v_ranchi_id FROM cities WHERE name = 'Ranchi';
    
    UPDATE public.users 
    SET city_id = v_ranchi_id
    WHERE email = 'ranchi.admin@sewamitr.in';
END $$;
