# Supabase Configuration Guide

Complete setup guide for SewaMitr backend.

## Quick Start (5 minutes)

1. Create project at [supabase.com](https://supabase.com)
2. Run SQL from `db.sql`
3. Create storage bucket: "sewamitr" (public)
4. Copy credentials to `.env`

## Detailed Setup

### 1. Create Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/Login
3. Click "New Project"
4. Fill in:
   - Name: SewaMitr
   - Database Password: (save securely)
   - Region: Closest to users
5. Wait 2-3 minutes

### 2. Database Setup

Go to **SQL Editor** and run all commands from `db.sql` file.

This creates:
- `users` table with RLS
- `issues` table with RLS
- `votes` table with RLS
- `notifications` table with RLS
- Helper functions (upvote, nearby issues, community stats)
- Auto-triggers (points system, user stats auto-update)
- Storage policies

### 3. Storage Setup

#### Create Bucket
1. Go to **Storage**
2. Click "Create Bucket"
3. Name: `sewamitr`
4. Set to **Public**
5. Click "Create"

#### Storage Policies

Go to **Storage** > **Policies**:

```sql
-- View files
CREATE POLICY "Anyone can view files" ON storage.objects
  FOR SELECT USING (bucket_id = 'sewamitr');

-- Upload files
CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'sewamitr' AND 
    auth.role() = 'authenticated'
  );

-- Update own files
CREATE POLICY "Users can update own files" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'sewamitr' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Delete own files
CREATE POLICY "Users can delete own files" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'sewamitr' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

### 4. Authentication

1. Go to **Authentication** > **Providers**
2. Enable **Email** provider
3. For testing: Disable email confirmation
   - **Authentication** > **Settings**
   - Uncheck "Enable email confirmations"
4. For production: Configure email templates

### 5. Get Credentials

1. Go to **Settings** > **API**
2. Copy:
   - **Project URL**
   - **anon public** key

### 6. Configure App

Create `.env`:
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## Storage Structure

```
sewamitr/
├── issues/
│   └── {user_id}/
│       ├── 1234567890_image.jpg
│       └── ...
├── audio/
│   └── {user_id}/
│       ├── audio_1234567890.m4a
│       └── ...
└── profiles/
    ├── {user_id}_timestamp.jpg
    └── ...
```

## Testing

### Test 1: Authentication
1. Run app
2. Create account
3. Check **Authentication** > **Users**
4. User should appear

### Test 2: User Profile
1. After signup
2. Check **Table Editor** > **users**
3. Profile auto-created

### Test 3: Storage
1. Report issue with photo
2. Check **Storage** > **sewamitr**
3. File in `issues/{user_id}/`

### Test 4: Issues
1. Report issue
2. Check **Table Editor** > **issues**
3. Verify all fields

### Test 5: Voting
1. Upvote in Community Feed
2. Check **Table Editor** > **votes**
3. Entry created

### Test 6: Notifications
1. Update issue progress to 25%
2. Check **Table Editor** > **notifications**
3. Notification created

## Security

### Implemented
- ✅ RLS on all tables
- ✅ Users can only modify own data
- ✅ Public issue viewing
- ✅ User-based storage organization
- ✅ Anon key safe for mobile

### Never Expose
- ❌ service_role key
- ❌ Database password
- ❌ JWT secret

## Common Issues

### "Row violates RLS policy"
- Run all SQL from `db.sql`
- Check user authenticated
- Verify `user_id` = `auth.uid()`

### "Relation does not exist"
- Run SQL in correct order
- Check table names
- Refresh dashboard

### Storage upload fails
- Bucket name: "sewamitr"
- Set to Public
- Create storage policies
- User authenticated

### Can't see files
- Path: `issues/{user_id}/filename.jpg`
- Storage policies allow SELECT
- Bucket is public

## Production Checklist

- [ ] All tables created
- [ ] RLS policies enabled
- [ ] Storage bucket public
- [ ] Storage policies set
- [ ] Email auth enabled
- [ ] Test signup flow
- [ ] Test issue creation
- [ ] Test photo upload
- [ ] Test audio recording
- [ ] Test upvoting
- [ ] Test notifications
- [ ] Verify RLS works
- [ ] Email templates (optional)

## Performance

- Indexes auto-created on foreign keys
- Geospatial queries optimized
- CDN for storage files
- Efficient RLS policies

## Monitoring

Dashboard shows:
- Database query performance
- Storage usage
- Auth activity
- API request logs

## Cost (Free Tier)

- 500MB database
- 1GB storage
- 50K monthly active users
- Unlimited API requests

Perfect for development!

## Support

- [Supabase Docs](https://supabase.com/docs)
- [Discord](https://discord.supabase.com)
- [Flutter Package](https://pub.dev/packages/supabase_flutter)

## Setup Time

- Account: 2 min
- Database: 5 min
- Storage: 3 min
- Testing: 5 min
- **Total: ~15 min**
