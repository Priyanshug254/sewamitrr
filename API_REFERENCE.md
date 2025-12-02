# SewaMitr API Reference

Complete reference for all Supabase RPC functions and database operations.

---

## Table of Contents

1. [Spatial Queries](#spatial-queries)
2. [Issue Management](#issue-management)
3. [Analytics](#analytics)
4. [Flutter Compatible](#flutter-compatible)
5. [Materialized Views](#materialized-views)

---

## Spatial Queries

### find_nearest_ward

Find the nearest ward to given coordinates.

**Signature:**
```sql
find_nearest_ward(lat NUMERIC, lng NUMERIC) RETURNS UUID
```

**Parameters:**
- `lat`: Latitude (numeric)
- `lng`: Longitude (numeric)

**Returns:** Ward UUID

**Example:**
```typescript
const { data, error } = await supabase.rpc('find_nearest_ward', {
  lat: 23.3441,
  lng: 85.3096
})
// Returns: "uuid-of-nearest-ward"
```

---

### find_nearest_zone

Find the nearest CRC zone to given coordinates.

**Signature:**
```sql
find_nearest_zone(lat NUMERIC, lng NUMERIC) RETURNS UUID
```

**Parameters:**
- `lat`: Latitude (numeric)
- `lng`: Longitude (numeric)

**Returns:** Zone UUID

**Example:**
```typescript
const { data, error } = await supabase.rpc('find_nearest_zone', {
  lat: 23.3441,
  lng: 85.3096
})
```

---

### get_nearby_issues

Get issues within a radius (Flutter compatible).

**Signature:**
```sql
get_nearby_issues(lat NUMERIC, lng NUMERIC, radius_km NUMERIC) RETURNS TABLE
```

**Parameters:**
- `lat`: Latitude (numeric)
- `lng`: Longitude (numeric)
- `radius_km`: Search radius in kilometers (numeric)

**Returns:** Array of issues with distance

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_nearby_issues', {
  lat: 23.3441,
  lng: 85.3096,
  radius_km: 5
})
```

---

## Issue Management

### verify_issue

CRC supervisor verifies a submitted issue.

**Signature:**
```sql
verify_issue(issue_uuid UUID, verifier_uuid UUID) RETURNS VOID
```

**Parameters:**
- `issue_uuid`: Issue ID to verify
- `verifier_uuid`: CRC supervisor's user ID

**Side Effects:**
- Updates issue status to `crc_verified`
- Creates audit log entry

**Example:**
```typescript
const { error } = await supabase.rpc('verify_issue', {
  issue_uuid: 'issue-id',
  verifier_uuid: user.id
})
```

---

### forward_to_ward

Forward verified issue to a ward.

**Signature:**
```sql
forward_to_ward(
  issue_uuid UUID,
  ward_uuid UUID,
  forwarded_by UUID
) RETURNS VOID
```

**Parameters:**
- `issue_uuid`: Issue ID
- `ward_uuid`: Target ward ID
- `forwarded_by`: CRC supervisor's user ID

**Side Effects:**
- Updates issue status to `forwarded_to_ward`
- Updates issue ward_id
- Creates audit log entry

**Example:**
```typescript
const { error } = await supabase.rpc('forward_to_ward', {
  issue_uuid: 'issue-id',
  ward_uuid: 'ward-id',
  forwarded_by: user.id
})
```

---

### assign_issue_to_contractor

Ward supervisor assigns issue to contractor.

**Signature:**
```sql
assign_issue_to_contractor(
  issue_uuid UUID,
  contractor_uuid UUID,
  assigned_by UUID,
  eta TIMESTAMP DEFAULT NULL
) RETURNS VOID
```

**Parameters:**
- `issue_uuid`: Issue ID
- `contractor_uuid`: Contractor's user ID
- `assigned_by`: Ward supervisor's user ID
- `eta`: Estimated completion time (optional)

**Side Effects:**
- Updates issue status to `in_progress`
- Sets issue assigned_to
- Creates assignment record
- Increments contractor active_assignments
- Creates audit log entry

**Example:**
```typescript
const { error } = await supabase.rpc('assign_issue_to_contractor', {
  issue_uuid: 'issue-id',
  contractor_uuid: 'contractor-id',
  assigned_by: user.id,
  eta: '2025-12-15T10:00:00Z'
})
```

---

### close_issue

Close/resolve an issue.

**Signature:**
```sql
close_issue(
  issue_uuid UUID,
  closed_by UUID,
  resolution_notes TEXT DEFAULT NULL
) RETURNS VOID
```

**Parameters:**
- `issue_uuid`: Issue ID
- `closed_by`: User ID closing the issue
- `resolution_notes`: Optional resolution notes

**Side Effects:**
- Updates issue status to `resolved`
- Sets progress to 100
- Updates contractor stats (if assigned)
- Creates audit log entry

**Example:**
```typescript
const { error } = await supabase.rpc('close_issue', {
  issue_uuid: 'issue-id',
  closed_by: user.id,
  resolution_notes: 'Pothole filled successfully'
})
```

---

## Analytics

### get_state_analytics

Get state-level analytics.

**Signature:**
```sql
get_state_analytics() RETURNS JSONB
```

**Returns:**
```json
{
  "total_issues": 200,
  "open_issues": 80,
  "resolved_issues": 120,
  "sla_compliance_rate": 85.5,
  "total_reporters": 50,
  "active_workers": 30,
  "avg_resolution_time_hours": 48.5
}
```

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_state_analytics')
```

---

### get_city_analytics

Get city-level analytics.

**Signature:**
```sql
get_city_analytics(city_uuid UUID) RETURNS JSONB
```

**Parameters:**
- `city_uuid`: City ID

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_city_analytics', {
  city_uuid: 'city-id'
})
```

---

### get_ward_analytics

Get ward-level analytics.

**Signature:**
```sql
get_ward_analytics(ward_uuid UUID) RETURNS JSONB
```

**Parameters:**
- `ward_uuid`: Ward ID

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_ward_analytics', {
  ward_uuid: 'ward-id'
})
```

---

### get_zone_analytics

Get zone-level analytics.

**Signature:**
```sql
get_zone_analytics(zone_uuid UUID) RETURNS JSONB
```

**Parameters:**
- `zone_uuid`: Zone ID

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_zone_analytics', {
  zone_uuid: 'zone-id'
})
```

---

### get_contractor_performance

Get contractor performance metrics.

**Signature:**
```sql
get_contractor_performance(contractor_uuid UUID) RETURNS JSONB
```

**Parameters:**
- `contractor_uuid`: Contractor's user ID

**Returns:**
```json
{
  "contractor_id": "uuid",
  "total_assignments": 45,
  "completed_assignments": 40,
  "active_assignments": 5,
  "avg_completion_time_hours": 36.5,
  "rating": 4.5,
  "on_time_completion_rate": 90.5
}
```

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_contractor_performance', {
  contractor_uuid: 'contractor-id'
})
```

---

## Flutter Compatible

### upvote_issue

Citizen upvotes an issue (Flutter app).

**Signature:**
```sql
upvote_issue(issue_uuid UUID) RETURNS VOID
```

**Parameters:**
- `issue_uuid`: Issue ID

**Side Effects:**
- Creates vote record (if not already voted)
- Increments issue upvotes count
- Prevents duplicate votes

**Example:**
```typescript
const { error } = await supabase.rpc('upvote_issue', {
  issue_uuid: 'issue-id'
})
```

---

### get_community_stats

Get community statistics (Flutter app).

**Signature:**
```sql
get_community_stats() RETURNS JSONB
```

**Returns:**
```json
{
  "total_users": 134,
  "total_issues": 200,
  "resolved_issues": 120
}
```

**Example:**
```typescript
const { data, error } = await supabase.rpc('get_community_stats')
```

---

## Materialized Views

### analytics_state_overview

State-level KPIs (refreshed periodically).

**Columns:**
- `total_issues` (bigint)
- `open_issues` (bigint)
- `resolved_issues` (bigint)
- `sla_compliance_rate` (numeric)
- `total_reporters` (bigint)
- `active_workers` (bigint)
- `avg_resolution_time_hours` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_state_overview')
  .select('*')
  .single()
```

---

### analytics_by_city

Per-city analytics.

**Columns:**
- `city_id` (uuid)
- `city_name` (text)
- `total_issues` (bigint)
- `open_issues` (bigint)
- `resolved_issues` (bigint)
- `critical_issues` (bigint)
- `high_priority_issues` (bigint)
- `sla_compliance_rate` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_by_city')
  .select('*')
  .order('total_issues', { ascending: false })
```

---

### analytics_by_ward

Per-ward analytics.

**Columns:**
- `ward_id` (uuid)
- `ward_name` (text)
- `city_id` (uuid)
- `total_issues` (bigint)
- `open_issues` (bigint)
- `in_progress_issues` (bigint)
- `resolved_issues` (bigint)
- `assigned_issues` (bigint)
- `active_workers` (bigint)
- `avg_resolution_time_hours` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_by_ward')
  .select('*')
  .eq('ward_id', wardId)
  .single()
```

---

### analytics_by_zone

Per-zone (CRC) analytics.

**Columns:**
- `zone_id` (uuid)
- `zone_name` (text)
- `city_id` (uuid)
- `unverified_issues` (bigint)
- `verified_issues` (bigint)
- `forwarded_issues` (bigint)
- `rejected_issues` (bigint)
- `avg_verification_time_hours` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_by_zone')
  .select('*')
  .eq('zone_id', zoneId)
  .single()
```

---

### analytics_by_category

Per-category metrics.

**Columns:**
- `category` (text)
- `total_issues` (bigint)
- `resolved_issues` (bigint)
- `open_issues` (bigint)
- `avg_resolution_time_hours` (numeric)
- `sla_compliance_rate` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_by_category')
  .select('*')
  .order('total_issues', { ascending: false })
```

---

### analytics_contractor_performance

Per-contractor performance.

**Columns:**
- `contractor_id` (uuid)
- `contractor_name` (text)
- `total_count` (bigint)
- `completed_count` (bigint)
- `active_count` (bigint)
- `avg_completion_hours` (numeric)
- `on_time_rate` (numeric)
- `refreshed_at` (timestamp)

**Query:**
```typescript
const { data } = await supabase
  .from('analytics_contractor_performance')
  .select('*')
  .order('completed_count', { ascending: false })
```

---

### refresh_all_analytics

Manually refresh all materialized views.

**Signature:**
```sql
refresh_all_analytics() RETURNS VOID
```

**Example:**
```typescript
const { error } = await supabase.rpc('refresh_all_analytics')
```

**Note:** Views auto-refresh via cron job, manual refresh only needed for immediate updates.

---

## Error Handling

All RPC functions may throw errors. Always handle them:

```typescript
const { data, error } = await supabase.rpc('function_name', { params })

if (error) {
  console.error('RPC Error:', error.message)
  // Handle error appropriately
}
```

Common errors:
- Permission denied (RLS policy violation)
- Invalid UUID format
- Record not found
- Constraint violations

---

**For more examples, see the dashboard implementations in `admin-frontend/app/`**
