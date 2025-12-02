# SewaMitr Admin Frontend - Quick Start Guide

## ✅ What's Ready

The admin frontend is now functional with:
- ✅ Login page with authentication
- ✅ State Admin dashboard
- ✅ City Admin dashboard
- ✅ Role-based routing
- ✅ Supabase integration

## 🚀 How to Run

### 1. Ensure Migrations Are Run

First, make sure you've run all Supabase migrations (see `../supabase/README_RUN_MIGRATIONS.md`).

### 2. Create Auth Users

Create at least these test accounts in Supabase Dashboard → Authentication → Users:

| Email | Password | Role |
|-------|----------|------|
| state.admin@sewamitr.in | SewaMitr@2024 | State Admin |
| ranchi.admin@sewamitr.in | SewaMitr@2024 | City Admin |

**Important**: After creating auth users, they will automatically sync to `public.users` via trigger.

### 3. Start the Dev Server

```bash
cd admin-frontend
npm run dev
```

### 4. Login

1. Open http://localhost:3000
2. You'll be redirected to `/login`
3. Login with `state.admin@sewamitr.in` / `SewaMitr@2024`
4. You'll be redirected to `/state` dashboard

## 📊 Available Dashboards

### State Admin (`/state`)
- View state-level KPIs
- See all cities with analytics
- Click on any city to drill down

### City Admin (`/city/[cityId]`)
- View city-level KPIs
- See all wards in the city
- See all CRC zones
- Click on a zone to drill down (coming soon)

## 🔧 Still To Be Built

The following pages need to be created:
- CRC Supervisor dashboard (`/crc/[zoneId]`)
- Ward Supervisor dashboard (`/ward/[wardId]`)
- Report details page (`/reports/[id]`)
- Workers management page (`/workers`)

These follow the same pattern as State and City dashboards.

## 🎨 UI Pattern

All dashboards follow this structure:

```typescript
// 1. Server Component (default)
export default async function Dashboard({ params }) {
  const supabase = await createClient()
  
  // 2. Check auth
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  
  // 3. Get user role
  const { data: userData } = await supabase
    .from('users')
    .select('role, ...')
    .eq('id', user.id)
    .single()
  
  // 4. Verify role access
  if (userData.role !== 'expected_role') redirect('/login')
  
  // 5. Fetch data
  const { data } = await supabase.from('table').select('*')
  
  // 6. Render UI
  return <div>...</div>
}
```

## 🐛 Troubleshooting

### "User not found" error on login

**Solution**: Create the auth user in Supabase Dashboard → Authentication → Users

### Dashboard shows no data

**Solution**: 
1. Verify migrations are run: Check Supabase Dashboard → Database → Tables
2. Verify seed data exists: Run `SELECT COUNT(*) FROM issues;` in SQL Editor
3. Check browser console for errors

### "Access denied" or redirect loop

**Solution**: 
1. Verify user has correct role in `public.users` table
2. Check RLS policies are enabled
3. Verify user's `city_id`/`ward_id`/`zone_id` matches the dashboard they're accessing

## 📝 Next Steps

To complete the admin frontend:

1. **Add CRC Dashboard** - Copy `app/city/[cityId]/page.tsx` pattern
2. **Add Ward Dashboard** - Similar pattern with ward-specific data
3. **Add Report Details** - Show full issue details with timeline
4. **Add Workers Page** - List and manage contractors
5. **Add Realtime** - Subscribe to issue changes
6. **Add Maps** - Integrate Leaflet for ward/zone visualization
7. **Add Charts** - Use Recharts for analytics

## 🎯 Testing Checklist

- [ ] Login as state admin
- [ ] View state dashboard KPIs
- [ ] Click on a city (e.g., Ranchi)
- [ ] View city dashboard
- [ ] Verify wards list shows correct count
- [ ] Verify zones list shows CRC zones
- [ ] Click on a recent issue
- [ ] Sign out
- [ ] Login as city admin (ranchi.admin@sewamitr.in)
- [ ] Verify can only access their city
- [ ] Try to access another city (should redirect)

## 💡 Tips

- All dashboards use **Server Components** for better performance and SEO
- Data is fetched server-side, reducing client-side JavaScript
- RLS policies enforce access control automatically
- Use `createClient()` from `@/lib/supabase/server` in server components
- Use `createClient()` from `@/lib/supabase/client` in client components

## 📚 Resources

- Supabase Docs: https://supabase.com/docs
- Next.js App Router: https://nextjs.org/docs/app
- Tailwind CSS: https://tailwindcss.com/docs

---

**Status**: Core dashboards functional ✅ | Additional pages needed 🚧
