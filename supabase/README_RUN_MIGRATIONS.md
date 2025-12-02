# SewaMitr Supabase Migrations

This directory contains all SQL migration files for the SewaMitr database. The migrations must be run in order to set up the complete backend.

## Prerequisites

1. **Supabase Project**: Create a new Supabase project at [supabase.com](https://supabase.com)
2. **PostGIS Extension**: Will be enabled automatically by migration 01
3. **Database Access**: You'll need your Supabase project URL and database password

## Migration Files (Run in Order)

| File | Description | Dependencies |
|------|-------------|--------------|
| `01_schema.sql` | Core tables with PostGIS support | None |
| `02_triggers.sql` | Automation triggers | 01 |
| `03_rpc_functions.sql` | Business logic functions | 01, 02 |
| `04_rls_policies.sql` | Row Level Security policies | 01 |
| `05_seed_cities_wards_zones.sql` | Jharkhand geography data | 01 |
| `06_seed_users_roles.sql` | User accounts (public.users only) | 01, 05 |
| `07_seed_demo_issues.sql` | Demo issues and assignments | 01, 05, 06 |
| `08_materialized_views_analytics.sql` | Analytics views | 01, 07 |
| `09_cleanup_and_indexes.sql` | Performance indexes | 01 |

## How to Run Migrations

### Option 1: Supabase SQL Editor (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Create a new query
4. Copy the contents of `01_schema.sql`
5. Click **Run** (or press Ctrl+Enter)
6. Repeat for each migration file in order (02, 03, 04, etc.)

### Option 2: psql Command Line

```bash
# Set your Supabase connection string
export DB_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run migrations in order
psql $DB_URL -f 01_schema.sql
psql $DB_URL -f 02_triggers.sql
psql $DB_URL -f 03_rpc_functions.sql
psql $DB_URL -f 04_rls_policies.sql
psql $DB_URL -f 05_seed_cities_wards_zones.sql
psql $DB_URL -f 06_seed_users_roles.sql
psql $DB_URL -f 07_seed_demo_issues.sql
psql $DB_URL -f 08_materialized_views_analytics.sql
psql $DB_URL -f 09_cleanup_and_indexes.sql
```

### Option 3: Copy-Paste All (Quick Setup)

If you want to run all migrations at once:

1. Open Supabase SQL Editor
2. Copy and paste the contents of each file in order, separated by a comment line
3. Run all at once

**Note**: This method may take 2-3 minutes to complete due to the seed data generation.

## Post-Migration Steps

### 1. Create Storage Bucket

```sql
-- Run this in SQL Editor
INSERT INTO storage.buckets (id, name, public)
VALUES ('sewamitr', 'sewamitr', true);
```

### 2. Set Storage Policies

```sql
-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'sewamitr');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'sewamitr' 
    AND auth.role() = 'authenticated'
);

-- Allow users to update their own uploads
CREATE POLICY "Users can update own uploads"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'sewamitr' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 3. Create Auth Users

The migration `06_seed_users_roles.sql` creates entries in `public.users` but **NOT** in `auth.users`. You must create auth users manually.

**Option A: Via Supabase Dashboard**

1. Go to **Authentication** → **Users**
2. Click **Add user**
3. Enter email and password
4. The user will automatically sync to `public.users` via trigger

**Option B: Via SQL (requires service_role key)**

See `CREDENTIALS.md` for the complete list of users to create.

Example:
```sql
-- Create state admin (run with service_role key)
SELECT auth.admin_create_user(
    email := 'state.admin@sewamitr.in',
    password := 'Admin@123',
    email_confirm := true,
    user_metadata := jsonb_build_object(
        'full_name', 'Rajesh Kumar',
        'role', 'state_admin'
    )
);
```

### 4. Verify Installation

```sql
-- Check table counts
SELECT 
    (SELECT COUNT(*) FROM public.cities) as cities,
    (SELECT COUNT(*) FROM public.wards) as wards,
    (SELECT COUNT(*) FROM public.zones) as zones,
    (SELECT COUNT(*) FROM public.users) as users,
    (SELECT COUNT(*) FROM public.issues) as issues,
    (SELECT COUNT(*) FROM public.assignments) as assignments;

-- Expected output:
-- cities: 3
-- wards: 168 (55 + 53 + 60)
-- zones: ~58
-- users: ~134 (1 state + 3 city + ~60 CRC + 30 ward + 50 workers + 50 citizens)
-- issues: ~200
-- assignments: ~80-100
```

## Troubleshooting

### Error: "extension postgis does not exist"

**Solution**: PostGIS should be enabled automatically. If not, run:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Error: "permission denied for schema public"

**Solution**: Ensure you're running migrations as the `postgres` user or with sufficient privileges.

### Error: "duplicate key value violates unique constraint"

**Solution**: The migrations are idempotent for most tables. If you need to re-run, drop all tables first:
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

### Slow Performance on Seed Files

**Normal**: Seed files (05, 06, 07) generate data procedurally and may take 30-60 seconds each. This is expected.

## What Gets Created

- **9 core tables**: users, cities, wards, zones, issues, assignments, audit_logs, votes, contractor_profiles
- **6 materialized views**: Analytics for state, city, ward, zone, category, and contractor performance
- **20+ RPC functions**: Business logic for issue management and analytics
- **50+ RLS policies**: Role-based access control
- **30+ indexes**: Performance optimization
- **10+ triggers**: Automation (location, SLA, audit logging)
- **3 cities**: Ranchi (55 wards), Dhanbad (53 wards), Jamshedpur (60 wards)
- **~58 CRC zones**: 2-3 wards per zone
- **~134 users**: Across all roles
- **~200 demo issues**: With assignments and votes

## Next Steps

After running migrations:

1. Create auth users (see `CREDENTIALS.md`)
2. Set up storage bucket and policies (see above)
3. Configure admin frontend with Supabase URL and anon key
4. Test login with seeded credentials
5. Verify RLS policies work correctly

## Support

If you encounter issues:

1. Check the Supabase logs in Dashboard → Logs
2. Verify PostGIS is enabled: `SELECT PostGIS_version();`
3. Check RLS is enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';`
4. Review the implementation plan in `../implementation_plan.md`
