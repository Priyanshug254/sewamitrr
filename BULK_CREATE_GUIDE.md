# Bulk Create Supervisor Accounts - Step by Step Guide

## Method 1: Using Supabase SQL Editor (Easiest)

### Step 1: Open Supabase SQL Editor
1. Go to your Supabase Dashboard
2. Click **"SQL Editor"** in the left sidebar
3. Click **"New query"**

### Step 2: Run the Bulk Creation Script
1. Copy the contents of `bulk_create_supervisors.sql`
2. Paste into the SQL Editor
3. Click **"Run"** (or press Ctrl+Enter)

### Step 3: Save the Credentials
The script will output NOTICE messages like:
```
NOTICE: Created CRC Supervisor: zone.1.crc@sewamitr.in / Password: CRC12ab34cd
NOTICE: Created Ward Supervisor: ward.1.ward@sewamitr.in / Password: WARD56ef78gh
```

**IMPORTANT**: Copy all these messages and save them to a secure file!

---

## Method 2: Using CSV Import (Alternative)

### Step 1: Create a CSV file with credentials

Create `supervisors.csv`:
```csv
email,password,full_name,role,zone_id,ward_id,city_id
zone1.crc@sewamitr.in,SecurePass123,Zone 1 CRC Supervisor,crc_supervisor,zone-uuid-here,,city-uuid-here
ward1.ward@sewamitr.in,SecurePass456,Ward 1 Supervisor,ward_supervisor,,ward-uuid-here,city-uuid-here
```

### Step 2: Use Supabase Auth Admin API

Create a Node.js script:
```javascript
const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const csv = require('csv-parser')

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY // Use service role key!
)

async function createUsers() {
  const users = []
  
  fs.createReadStream('supervisors.csv')
    .pipe(csv())
    .on('data', (row) => users.push(row))
    .on('end', async () => {
      for (const user of users) {
        // Create auth user
        const { data, error } = await supabase.auth.admin.createUser({
          email: user.email,
          password: user.password,
          email_confirm: true,
          user_metadata: {
            full_name: user.full_name,
            role: user.role
          }
        })
        
        if (error) {
          console.error(`Error creating ${user.email}:`, error)
          continue
        }
        
        // Create public.users entry
        await supabase.from('users').insert({
          id: data.user.id,
          email: user.email,
          full_name: user.full_name,
          role: user.role,
          zone_id: user.zone_id || null,
          ward_id: user.ward_id || null,
          city_id: user.city_id
        })
        
        console.log(`✓ Created: ${user.email}`)
      }
    })
}

createUsers()
```

---

## Method 3: Using Supabase Dashboard (Manual but Simple)

For smaller numbers (< 20 accounts):

1. **Go to**: Supabase Dashboard → Authentication → Users
2. **Click**: "Add user"
3. **Fill in**:
   - Email: `zone1.crc@sewamitr.in`
   - Password: Generate or set custom
   - Auto Confirm User: ✓ (check this)
4. **Click**: "Create user"
5. **Then run SQL** to update `public.users`:
   ```sql
   INSERT INTO public.users (id, email, full_name, role, zone_id, city_id)
   VALUES (
     'user-id-from-auth',
     'zone1.crc@sewamitr.in',
     'Zone 1 CRC Supervisor',
     'crc_supervisor',
     'zone-uuid',
     'city-uuid'
   );
   ```

---

## Recommended Approach

**For your case (many supervisors):**

1. ✅ **Use Method 1** (SQL script) - It's automated and creates both auth + public.users
2. ✅ **Save all passwords** from the NOTICE output
3. ✅ **Share credentials** securely with supervisors (use password manager or encrypted file)

**Password Pattern:**
- CRC Supervisors: `CRC` + 8 random characters (based on zone ID)
- Ward Supervisors: `WARD` + 8 random characters (based on ward ID)

**Email Pattern:**
- CRC: `zone.name.crc@sewamitr.in`
- Ward: `ward.name.ward@sewamitr.in`

---

## After Creation

### Option A: Let supervisors reset passwords
1. Send them their email
2. They click "Forgot Password" on login page
3. They set their own password

### Option B: Provide temporary passwords
1. Save all credentials from NOTICE output
2. Create a secure spreadsheet
3. Share with supervisors via secure channel
4. Ask them to change password on first login

---

## Security Best Practices

- ✅ Use strong, unique passwords
- ✅ Enable email confirmation
- ✅ Store credentials in password manager
- ✅ Force password change on first login
- ✅ Use HTTPS only
- ✅ Enable 2FA for admin accounts

---

## Troubleshooting

**Error: "User already exists"**
- Check if email is already in `auth.users`
- Use different email or delete existing user

**Error: "Invalid password"**
- Ensure password meets requirements (min 6 chars)
- Use stronger passwords for production

**Users can't login**
- Verify `email_confirmed_at` is set
- Check RLS policies allow access
- Verify role is correct in `public.users`
