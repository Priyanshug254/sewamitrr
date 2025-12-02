-- Check active policies on users table
SELECT * FROM pg_policies WHERE tablename = 'users';
