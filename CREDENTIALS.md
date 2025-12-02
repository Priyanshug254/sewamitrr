# SewaMitr Admin Credentials

This document lists all seeded user accounts for the SewaMitr system. These users exist in `public.users` table but **must be created manually** in `auth.users` via Supabase Dashboard.

## Important Notes

1. **Auth Users Must Be Created Manually**: The seed migration `06_seed_users_roles.sql` only creates entries in `public.users`. You must create corresponding auth users via:
   - Supabase Dashboard → Authentication → Users → Add user
   - Or use the Admin Manual Onboarding UI in the admin frontend

2. **Default Password**: For testing purposes, use `SewaMitr@2024` for all accounts (change in production)

3. **Email Format**: All emails follow the pattern `role.location.number@sewamitr.in`

---

## State Admin (1 user)

| Email | Full Name | Role | Password | City | Ward | Zone |
|-------|-----------|------|----------|------|------|------|
| state.admin@sewamitr.in | Rajesh Kumar | state_admin | SewaMitr@2024 | - | - | - |

**Access**: Full access to all data across all cities, wards, and zones.

---

## City Admins (3 users)

| Email | Full Name | Role | Password | City | Ward | Zone |
|-------|-----------|------|----------|------|------|------|
| ranchi.admin@sewamitr.in | Priya Sharma | city_admin | SewaMitr@2024 | Ranchi | - | - |
| dhanbad.admin@sewamitr.in | Amit Singh | city_admin | SewaMitr@2024 | Dhanbad | - | - |
| jamshedpur.admin@sewamitr.in | Sunita Devi | city_admin | SewaMitr@2024 | Jamshedpur | - | - |

**Access**: Limited to their assigned city only.

---

## CRC Supervisors (~60 users)

CRC supervisors are automatically assigned to zones. Each zone has one supervisor.

### Ranchi CRC Supervisors (~20)

| Email | Full Name | Role | Password | City | Zone |
|-------|-----------|------|----------|------|------|
| crc.ranchi.1@sewamitr.in | CRC Supervisor Ranchi 1 | crc_supervisor | SewaMitr@2024 | Ranchi | Ranchi CRC Zone 1 |
| crc.ranchi.2@sewamitr.in | CRC Supervisor Ranchi 2 | crc_supervisor | SewaMitr@2024 | Ranchi | Ranchi CRC Zone 2 |
| ... | ... | ... | ... | ... | ... |
| crc.ranchi.20@sewamitr.in | CRC Supervisor Ranchi 20 | crc_supervisor | SewaMitr@2024 | Ranchi | Ranchi CRC Zone 20 |

### Dhanbad CRC Supervisors (~18)

| Email | Full Name | Role | Password | City | Zone |
|-------|-----------|------|----------|------|------|
| crc.dhanbad.1@sewamitr.in | CRC Supervisor Dhanbad 1 | crc_supervisor | SewaMitr@2024 | Dhanbad | Dhanbad CRC Zone 1 |
| crc.dhanbad.2@sewamitr.in | CRC Supervisor Dhanbad 2 | crc_supervisor | SewaMitr@2024 | Dhanbad | Dhanbad CRC Zone 2 |
| ... | ... | ... | ... | ... | ... |
| crc.dhanbad.18@sewamitr.in | CRC Supervisor Dhanbad 18 | crc_supervisor | SewaMitr@2024 | Dhanbad | Dhanbad CRC Zone 18 |

### Jamshedpur CRC Supervisors (~20)

| Email | Full Name | Role | Password | City | Zone |
|-------|-----------|------|----------|------|------|
| crc.jamshedpur.1@sewamitr.in | CRC Supervisor Jamshedpur 1 | crc_supervisor | SewaMitr@2024 | Jamshedpur | Jamshedpur CRC Zone 1 |
| crc.jamshedpur.2@sewamitr.in | CRC Supervisor Jamshedpur 2 | crc_supervisor | SewaMitr@2024 | Jamshedpur | Jamshedpur CRC Zone 2 |
| ... | ... | ... | ... | ... | ... |
| crc.jamshedpur.20@sewamitr.in | CRC Supervisor Jamshedpur 20 | crc_supervisor | SewaMitr@2024 | Jamshedpur | Jamshedpur CRC Zone 20 |

**Access**: Limited to their assigned zone only. Can verify, reject, or forward issues.

---

## Ward Supervisors (30 users)

Ward supervisors are assigned to specific wards (10 per city for demo purposes).

### Ranchi Ward Supervisors (10)

| Email | Full Name | Role | Password | City | Ward |
|-------|-----------|------|----------|------|------|
| ward.ranchi.1@sewamitr.in | Ward Supervisor Ranchi 1 | ward_supervisor | SewaMitr@2024 | Ranchi | Ward 1 |
| ward.ranchi.2@sewamitr.in | Ward Supervisor Ranchi 2 | ward_supervisor | SewaMitr@2024 | Ranchi | Ward 2 |
| ... | ... | ... | ... | ... | ... |
| ward.ranchi.10@sewamitr.in | Ward Supervisor Ranchi 10 | ward_supervisor | SewaMitr@2024 | Ranchi | Ward 10 |

### Dhanbad Ward Supervisors (10)

| Email | Full Name | Role | Password | City | Ward |
|-------|-----------|------|----------|------|------|
| ward.dhanbad.1@sewamitr.in | Ward Supervisor Dhanbad 1 | ward_supervisor | SewaMitr@2024 | Dhanbad | Ward 1 |
| ward.dhanbad.2@sewamitr.in | Ward Supervisor Dhanbad 2 | ward_supervisor | SewaMitr@2024 | Dhanbad | Ward 2 |
| ... | ... | ... | ... | ... | ... |
| ward.dhanbad.10@sewamitr.in | Ward Supervisor Dhanbad 10 | ward_supervisor | SewaMitr@2024 | Dhanbad | Ward 10 |

### Jamshedpur Ward Supervisors (10)

| Email | Full Name | Role | Password | City | Ward |
|-------|-----------|------|----------|------|------|
| ward.jamshedpur.1@sewamitr.in | Ward Supervisor Jamshedpur 1 | ward_supervisor | SewaMitr@2024 | Jamshedpur | Ward 1 |
| ward.jamshedpur.2@sewamitr.in | Ward Supervisor Jamshedpur 2 | ward_supervisor | SewaMitr@2024 | Jamshedpur | Ward 2 |
| ... | ... | ... | ... | ... | ... |
| ward.jamshedpur.10@sewamitr.in | Ward Supervisor Jamshedpur 10 | ward_supervisor | SewaMitr@2024 | Jamshedpur | Ward 10 |

**Access**: Limited to their assigned ward only. Can assign issues to contractors.

---

## Workers/Contractors (50 users)

Workers are distributed across all 3 cities.

| Email | Full Name | Role | Password | City | Specializations |
|-------|-----------|------|----------|------|-----------------|
| worker.Ranchi.1@sewamitr.in | Worker Ranchi 1 | worker | SewaMitr@2024 | Ranchi | Pothole Repair, Drainage |
| worker.Dhanbad.2@sewamitr.in | Worker Dhanbad 2 | worker | SewaMitr@2024 | Dhanbad | Streetlight, Waste Management |
| worker.Jamshedpur.3@sewamitr.in | Worker Jamshedpur 3 | worker | SewaMitr@2024 | Jamshedpur | Water Supply, Sanitation |
| ... | ... | ... | ... | ... | ... |
| worker.Jamshedpur.50@sewamitr.in | Worker Jamshedpur 50 | worker | SewaMitr@2024 | Jamshedpur | Road Repair, Tree Maintenance |

**Access**: Can only view and update issues assigned to them.

---

## Citizens (50 users)

Citizens can report issues and view their own reports.

| Email | Full Name | Role | Password | City | Language |
|-------|-----------|------|----------|------|----------|
| citizen.Ranchi.1@sewamitr.in | Citizen Ranchi 1 | citizen | SewaMitr@2024 | Ranchi | en |
| citizen.Dhanbad.2@sewamitr.in | Citizen Dhanbad 2 | citizen | SewaMitr@2024 | Dhanbad | hi |
| citizen.Jamshedpur.3@sewamitr.in | Citizen Jamshedpur 3 | citizen | SewaMitr@2024 | Jamshedpur | en |
| ... | ... | ... | ... | ... | ... |
| citizen.Jamshedpur.50@sewamitr.in | Citizen Jamshedpur 50 | citizen | SewaMitr@2024 | Jamshedpur | hi |

**Access**: Can create issues and view only their own issues.

---

## How to Create Auth Users

### Option 1: Supabase Dashboard (Recommended for Testing)

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Users**
3. Click **Add user** → **Create new user**
4. Enter:
   - **Email**: (from table above)
   - **Password**: `SewaMitr@2024`
   - **Auto Confirm User**: ✅ (check this)
5. Click **Create user**
6. The user will automatically sync to `public.users` via trigger

**Note**: You don't need to create all 134 users for testing. Start with:
- 1 state admin
- 1 city admin (e.g., Ranchi)
- 1 CRC supervisor (e.g., crc.ranchi.1)
- 1 ward supervisor (e.g., ward.ranchi.1)
- 1 worker (e.g., worker.Ranchi.1)
- 1 citizen (e.g., citizen.Ranchi.1)

### Option 2: Bulk Create via SQL (Requires Service Role Key)

**⚠️ WARNING**: This requires your Supabase service_role key. Never expose this key in client code or commit it to version control.

```sql
-- Example: Create state admin
SELECT auth.admin_create_user(
    email := 'state.admin@sewamitr.in',
    password := 'SewaMitr@2024',
    email_confirm := true,
    user_metadata := jsonb_build_object(
        'full_name', 'Rajesh Kumar',
        'role', 'state_admin'
    )
);

-- Example: Create city admin
SELECT auth.admin_create_user(
    email := 'ranchi.admin@sewamitr.in',
    password := 'SewaMitr@2024',
    email_confirm := true,
    user_metadata := jsonb_build_object(
        'full_name', 'Priya Sharma',
        'role', 'city_admin'
    )
);
```

### Option 3: Admin Manual Onboarding UI (Coming Soon)

The admin frontend will include an Admin Manual Onboarding page where you can create users directly from the UI.

---

## Quick Test Accounts

For quick testing, create these 6 accounts:

| Email | Password | Role | Purpose |
|-------|----------|------|---------|
| state.admin@sewamitr.in | SewaMitr@2024 | state_admin | Test state dashboard |
| ranchi.admin@sewamitr.in | SewaMitr@2024 | city_admin | Test city dashboard |
| crc.ranchi.1@sewamitr.in | SewaMitr@2024 | crc_supervisor | Test CRC dashboard |
| ward.ranchi.1@sewamitr.in | SewaMitr@2024 | ward_supervisor | Test ward dashboard |
| worker.Ranchi.1@sewamitr.in | SewaMitr@2024 | worker | Test worker mobile app |
| citizen.Ranchi.1@sewamitr.in | SewaMitr@2024 | citizen | Test citizen mobile app |

---

## Troubleshooting

### User exists in public.users but can't login

**Solution**: The user doesn't exist in `auth.users`. Create them via Supabase Dashboard.

### User can login but has no role/permissions

**Solution**: Check that the trigger `on_auth_user_created` fired correctly. Verify:
```sql
SELECT id, email, role, city_id, ward_id, zone_id 
FROM public.users 
WHERE email = 'your.email@sewamitr.in';
```

### User has wrong role or city assignment

**Solution**: Update `public.users` directly:
```sql
UPDATE public.users 
SET role = 'city_admin', city_id = '11111111-1111-1111-1111-111111111111'::UUID
WHERE email = 'your.email@sewamitr.in';
```

---

## Security Recommendations for Production

1. **Change all passwords** from `SewaMitr@2024` to strong, unique passwords
2. **Enable MFA** for admin accounts (state_admin, city_admin)
3. **Use email verification** for all new users
4. **Rotate credentials** every 90 days
5. **Audit user access** regularly via `audit_logs` table
6. **Disable unused accounts** after 30 days of inactivity

---

## Summary

- **Total Users**: ~134
  - 1 State Admin
  - 3 City Admins
  - ~60 CRC Supervisors
  - 30 Ward Supervisors
  - 50 Workers
  - 50 Citizens

- **Default Password**: `SewaMitr@2024` (change in production)
- **Auth Creation**: Manual via Supabase Dashboard or Admin UI
- **Quick Test**: Create 6 accounts (one per role)
