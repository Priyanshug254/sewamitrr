# Enhanced Features Implementation Guide

## Overview

This guide explains how to use the enhanced features (realtime subscriptions, maps, and charts) in your dashboards.

---

## 1. Realtime Subscriptions

### useIssues Hook

Automatically subscribes to issue changes and updates the UI in real-time.

**Usage:**
```typescript
import { useIssues } from '@/hooks/useIssues'

function MyComponent() {
  const { issues, loading, error, refetch } = useIssues({
    cityId: 'uuid',  // Optional filter
    wardId: 'uuid',  // Optional filter
    zoneId: 'uuid',  // Optional filter
    status: 'submitted'  // Optional filter
  })

  if (loading) return <div>Loading...</div>
  if (error) return <div>Error: {error}</div>

  return (
    <div>
      {issues.map(issue => (
        <div key={issue.id}>{issue.description}</div>
      ))}
    </div>
  )
}
```

**Features:**
- Auto-subscribes to INSERT, UPDATE, DELETE events
- Filters by city, ward, zone, or status
- Auto-cleanup on unmount
- Manual refetch available

---

### useAnalytics Hook

Fetches analytics with auto-refresh every 30 seconds.

**Usage:**
```typescript
import { useAnalytics } from '@/hooks/useAnalytics'

function StateAnalytics() {
  const { analytics, loading, error, refetch } = useAnalytics('state')
  
  return (
    <div>
      <p>Total Issues: {analytics?.total_issues}</p>
      <p>SLA Compliance: {analytics?.sla_compliance_rate}%</p>
    </div>
  )
}

// For city/ward/zone analytics
const { analytics } = useAnalytics('city', cityId)
const { analytics } = useAnalytics('ward', wardId)
const { analytics } = useAnalytics('zone', zoneId)
```

**Features:**
- Auto-refresh every 30 seconds
- Fetches from materialized views
- Manual refetch available

---

## 2. Maps Integration

### IssueMap Component

Displays issues on an interactive map with ward boundaries.

**Usage:**
```typescript
import IssueMap from '@/components/maps/IssueMap'

function CityDashboard() {
  const issues = [
    {
      id: 'uuid',
      latitude: 23.3441,
      longitude: 85.3096,
      category: 'Pothole',
      status: 'submitted',
      priority: 'high'
    }
  ]

  const wardBoundaries = [
    {
      id: 'uuid',
      name: 'Ward 1',
      coordinates: [
        [[23.34, 85.30], [23.35, 85.30], [23.35, 85.31], [23.34, 85.31]]
      ]
    }
  ]

  return (
    <IssueMap
      center={[23.3441, 85.3096]}
      zoom={13}
      issues={issues}
      wardBoundaries={wardBoundaries}
      className="h-96 w-full rounded-lg"
    />
  )
}
```

**Features:**
- Color-coded markers (status/priority)
- Ward boundary polygons
- Clickable markers with popups
- Link to issue details
- Responsive container

**Marker Colors:**
- Green: Resolved
- Orange: In Progress
- Red: Critical priority
- Orange: High priority
- Gray: Medium/Low priority

---

## 3. Charts

### CategoryChart

Bar chart showing issues by category.

**Usage:**
```typescript
import CategoryChart from '@/components/charts/CategoryChart'

function Analytics() {
  const data = [
    {
      category: 'Pothole',
      total_issues: 45,
      resolved_issues: 30,
      open_issues: 15
    },
    {
      category: 'Drainage',
      total_issues: 32,
      resolved_issues: 20,
      open_issues: 12
    }
  ]

  return <CategoryChart data={data} />
}
```

**Data Source:**
```sql
SELECT * FROM analytics_by_category;
```

---

### StatusChart

Pie chart showing issue status distribution.

**Usage:**
```typescript
import StatusChart from '@/components/charts/StatusChart'

function Analytics() {
  const data = {
    submitted: 45,
    crc_verified: 20,
    forwarded_to_ward: 15,
    in_progress: 30,
    resolved: 120,
    rejected: 5
  }

  return <StatusChart data={data} />
}
```

**Data Calculation:**
```typescript
const statusData = {
  submitted: issues.filter(i => i.status === 'submitted').length,
  crc_verified: issues.filter(i => i.status === 'crc_verified').length,
  // ... etc
}
```

---

### TrendChart

Line chart showing issue trends over time.

**Usage:**
```typescript
import TrendChart from '@/components/charts/TrendChart'

function Analytics() {
  const data = [
    {
      date: '2025-11-01',
      submitted: 12,
      in_progress: 8,
      resolved: 15
    },
    {
      date: '2025-11-02',
      submitted: 15,
      in_progress: 10,
      resolved: 12
    }
  ]

  return <TrendChart data={data} />
}
```

**Data Calculation:**
```typescript
// Group issues by date
const trendData = issues.reduce((acc, issue) => {
  const date = new Date(issue.created_at).toISOString().split('T')[0]
  if (!acc[date]) {
    acc[date] = { date, submitted: 0, in_progress: 0, resolved: 0 }
  }
  if (issue.status === 'submitted') acc[date].submitted++
  if (issue.status === 'in_progress') acc[date].in_progress++
  if (issue.status === 'resolved') acc[date].resolved++
  return acc
}, {})
```

---

## 4. Complete Example: Enhanced State Dashboard

```typescript
import { useAnalytics } from '@/hooks/useAnalytics'
import { useIssues } from '@/hooks/useIssues'
import CategoryChart from '@/components/charts/CategoryChart'
import StatusChart from '@/components/charts/StatusChart'
import TrendChart from '@/components/charts/TrendChart'

export default function EnhancedStateDashboard() {
  const { analytics } = useAnalytics('state')
  const { issues } = useIssues()

  // Fetch category data
  const { data: categoryData } = await supabase
    .from('analytics_by_category')
    .select('*')

  // Calculate status distribution
  const statusData = {
    submitted: issues.filter(i => i.status === 'submitted').length,
    crc_verified: issues.filter(i => i.status === 'crc_verified').length,
    forwarded_to_ward: issues.filter(i => i.status === 'forwarded_to_ward').length,
    in_progress: issues.filter(i => i.status === 'in_progress').length,
    resolved: issues.filter(i => i.status === 'resolved').length,
    rejected: issues.filter(i => i.status === 'rejected').length,
  }

  return (
    <div className="space-y-8">
      {/* KPI Cards */}
      <div className="grid grid-cols-4 gap-6">
        {/* ... KPI cards ... */}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <CategoryChart data={categoryData} />
        <StatusChart data={statusData} />
      </div>

      {/* Trend Chart */}
      <TrendChart data={trendData} />
    </div>
  )
}
```

---

## 5. Enabling Realtime in Supabase

### Enable Realtime for Tables

In Supabase Dashboard → Database → Replication:

1. Enable realtime for `issues` table
2. Enable realtime for `assignments` table (optional)
3. Enable realtime for `audit_logs` table (optional)

### Or via SQL:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE issues;
ALTER PUBLICATION supabase_realtime ADD TABLE assignments;
ALTER PUBLICATION supabase_realtime ADD TABLE audit_logs;
```

---

## 6. Performance Considerations

### Realtime Subscriptions
- Subscriptions auto-cleanup on component unmount
- Filters reduce unnecessary updates
- Use specific filters (cityId, wardId, zoneId) to minimize data transfer

### Maps
- Limit number of markers (use clustering for >100 markers)
- Ward boundaries are rendered as polygons (lightweight)
- Popups are lazy-loaded on click

### Charts
- Data is pre-aggregated from materialized views
- Charts use ResponsiveContainer for responsive sizing
- Dark mode compatible

---

## 7. Troubleshooting

### Realtime Not Working
1. Check Supabase Dashboard → Database → Replication
2. Verify table is added to `supabase_realtime` publication
3. Check browser console for WebSocket errors
4. Verify RLS policies allow SELECT on subscribed tables

### Maps Not Displaying
1. Ensure Leaflet CSS is imported in layout
2. Check coordinates are valid (latitude, longitude)
3. Verify ward boundaries have correct format
4. Check browser console for errors

### Charts Not Rendering
1. Verify data format matches component props
2. Check ResponsiveContainer has height
3. Ensure parent container has defined height
4. Check browser console for Recharts errors

---

## 8. Next Steps

### Optional Enhancements
- Add marker clustering for large datasets
- Implement heatmaps for issue density
- Add custom chart tooltips
- Create dashboard export (PDF/CSV)
- Add date range filters for trends

---

**All enhanced features are now ready to use!** 🎉
