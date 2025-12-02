-- Delete the existing Ranchi admin from public.users so you can create the auth user
DELETE FROM public.users WHERE email = 'ranchi.admin@sewamitr.in';
