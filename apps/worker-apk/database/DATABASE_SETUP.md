# Worker Database Setup Guide

## Overview
The worker system uses the **same database** as the main SewaMitr app. This SQL file adds worker-specific columns, policies, and functions to the existing database.

## Setup Steps

### 1. Run Main Database Setup (If Not Already Done)
```sql
-- First, run the main db.sql from sewamitr - main folder
-- This creates the base tables: users, issues, votes, notifications
```

### 2. Run Worker Setup
```sql
-- Copy the entire contents of database/setup.sql
-- Paste into Supabase SQL Editor
-- Click "Run" to execute
```

## What Gets Added

### New Columns

#### `users` table:
- `role` (TEXT) - Values: 'user', 'worker', 'admin'

#### `issues` table:
- `assigned_to` (UUID) - Worker user ID
- `update_logs` (JSONB) - Array of worker updates

### New Indexes
- `idx_issues_assigned_to` - Fast queries for assigned issues
- `idx_users_role` - Fast filtering by user role
- `idx_issues_status` - Fast filtering by issue status

### New Functions

#### `get_workers()`
Returns all workers with their assigned issue count.

```sql
SELECT * FROM get_workers();
```

#### `get_worker_issues(worker_id)`
Returns all issues assigned to a specific worker.

```sql
SELECT * FROM get_worker_issues('worker-uuid-here');
```

#### `get_unassigned_issues()`
Returns all issues that haven't been assigned yet.

```sql
SELECT * FROM get_unassigned_issues();
```

#### `assign_issue_to_worker(issue_id, worker_id)`
Assigns an issue to a worker.

```sql
SELECT assign_issue_to_worker('issue-uuid', 'worker-uuid');
```

### New Views

#### `worker_workload`
Shows each worker's workload statistics.

```sql
SELECT * FROM worker_workload;
```

#### `unassigned_by_category`
Shows unassigned issues grouped by category.

```sql
SELECT * FROM unassigned_by_category;
```

## Common Operations

### Create a Worker Account

**Option 1: Via Supabase Dashboard**
1. Go to Authentication → Users
2. Click "Add User"
3. Enter email and password
4. After creation, mark as worker:

```sql
UPDATE users 
SET role = 'worker' 
WHERE email = 'worker@example.com';
```

### Assign Issue to Worker

```sql
-- Method 1: Direct update
UPDATE issues 
SET assigned_to = 'worker-uuid-here'
WHERE id = 'issue-uuid-here';

-- Method 2: Using function
SELECT assign_issue_to_worker('issue-uuid', 'worker-uuid');
```

### View Worker's Assigned Issues

```sql
SELECT * FROM issues 
WHERE assigned_to = 'worker-uuid-here'
ORDER BY created_at DESC;
```

## Security (RLS Policies)

- ✅ Workers can only view and update issues assigned to them
- ✅ Users can view all issues (public)
- ✅ Users can only update their own reported issues
- ✅ Authenticated users can assign issues (admin panel)

## Verification

After running the SQL, verify setup:

```sql
-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'issues' 
AND column_name IN ('assigned_to', 'update_logs');
```
