import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { formatDate, getStatusColor, getPriorityColor } from '@/lib/utils'
import MapWrapper from '@/components/maps/MapWrapper'

export default async function CRCDashboard({ params }: { params: Promise<{ zoneId: string }> }) {
    const { zoneId } = await params
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Get user role and verify access
    const { data: userData } = await supabase
        .from('users')
        .select('role, full_name, zone_id')
        .eq('id', user.id)
        .single()

    if (!userData || (userData.role !== 'state_admin' && userData.role !== 'city_admin' && userData.role !== 'crc_supervisor')) {
        redirect('/login')
    }

    // CRC supervisors can only access their own zone
    if (userData.role === 'crc_supervisor' && userData.zone_id !== zoneId) {
        redirect(`/crc/${userData.zone_id}`)
    }

    // Fetch zone details
    const { data: zone } = await supabase
        .from('zones')
        .select('*, cities(name)')
        .eq('id', zoneId)
        .single()

    // Fetch zone analytics
    const { data: zoneAnalytics } = await supabase
        .from('analytics_by_zone')
        .select('*')
        .eq('zone_id', zoneId)
        .single()

    // Fetch unverified issues (submitted status)
    const { data: unverifiedIssues } = await supabase
        .from('issues')
        .select('id, category, description, address, priority, created_at, latitude, longitude, media_urls')
        .eq('zone_id', zoneId)
        .eq('status', 'submitted')
        .order('created_at', { ascending: false })
        .limit(20)

    // Fetch all issues for this zone
    const { data: allIssues } = await supabase
        .from('issues')
        .select('id, category, description, status, priority, created_at')
        .eq('zone_id', zoneId)
        .order('created_at', { ascending: false })
        .limit(10)

    // Fetch wards in this zone
    const { data: wards } = await supabase
        .from('wards')
        .select('id, name')
        .in('id', zone?.ward_ids || [])
        .order('name')

    // Fetch all active issues for map
    const { data: mapIssues } = await supabase
        .from('issues')
        .select('id, latitude, longitude, category, status, priority')
        .eq('zone_id', zoneId)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            {(userData.role === 'state_admin' || userData.role === 'city_admin') && (
                                <Link
                                    href={`/city/${zone?.city_id}`}
                                    className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-700 transition"
                                >
                                    <span className="text-xl font-bold text-white">←</span>
                                </Link>
                            )}
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{zone?.name}</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">
                                    {zone?.cities?.name} • CRC Supervisor Dashboard
                                </p>
                            </div>
                        </div>
                        <div className="flex items-center gap-4">
                            <span className="text-sm text-gray-600 dark:text-gray-400">Welcome, {userData.full_name}</span>
                            <form action="/api/auth/signout" method="post">
                                <button className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                                    Sign out
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* KPI Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Unverified</h3>
                            <div className="h-8 w-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-blue-600 dark:text-blue-400">📋</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{zoneAnalytics?.unverified_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Pending verification</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Verified</h3>
                            <div className="h-8 w-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-green-600 dark:text-green-400">✓</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{zoneAnalytics?.verified_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Approved by CRC</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Forwarded</h3>
                            <div className="h-8 w-8 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-purple-600 dark:text-purple-400">→</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{zoneAnalytics?.forwarded_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Sent to wards</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Rejected</h3>
                            <div className="h-8 w-8 bg-red-100 dark:bg-red-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-red-600 dark:text-red-400">✕</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{zoneAnalytics?.rejected_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Not approved</p>
                    </div>
                </div>

                {/* Map Section */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8 p-6">
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Zone Issue Map</h2>
                    <MapWrapper
                        center={[23.3441, 85.3096]}
                        zoom={13}
                        issues={mapIssues || []}
                        className="h-[500px] w-full rounded-lg z-0"
                    />
                </div>

                {/* Unverified Issues Queue */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8">
                    <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                            Unverified Issues Queue ({unverifiedIssues?.length || 0})
                        </h2>
                        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                            Review and verify citizen-reported issues
                        </p>
                    </div>
                    <div className="divide-y divide-gray-200 dark:divide-gray-700">
                        {unverifiedIssues && unverifiedIssues.length > 0 ? (
                            unverifiedIssues.map((issue: any) => (
                                <div key={issue.id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-2">
                                                <span className="text-sm font-medium text-gray-900 dark:text-white">{issue.category}</span>
                                                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPriorityColor(issue.priority)}`}>
                                                    {issue.priority}
                                                </span>
                                                {issue.media_urls && issue.media_urls.length > 0 && (
                                                    <span className="text-xs text-gray-500 dark:text-gray-400">
                                                        📷 {issue.media_urls.length} photo{issue.media_urls.length > 1 ? 's' : ''}
                                                    </span>
                                                )}
                                            </div>
                                            <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">{issue.description}</p>
                                            <div className="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
                                                <span>📍 {issue.address}</span>
                                                <span>•</span>
                                                <span>{formatDate(issue.created_at)}</span>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 ml-4">
                                            <Link
                                                href={`/reports/${issue.id}`}
                                                className="px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg transition"
                                            >
                                                View Details
                                            </Link>
                                            <button className="px-3 py-1.5 text-sm font-medium text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg transition">
                                                ✓ Verify
                                            </button>
                                            <button className="px-3 py-1.5 text-sm font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition">
                                                ✕ Reject
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))
                        ) : (
                            <div className="px-6 py-12 text-center">
                                <p className="text-gray-500 dark:text-gray-400">No unverified issues in queue</p>
                            </div>
                        )}
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    {/* Wards in Zone */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                                Wards in Zone ({wards?.length || 0})
                            </h2>
                        </div>
                        <div className="p-6">
                            <div className="grid grid-cols-1 gap-2">
                                {wards?.map((ward) => (
                                    <div key={ward.id} className="p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                                        <span className="text-sm font-medium text-gray-900 dark:text-white">{ward.name}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* Recent Activity */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Activity</h2>
                        </div>
                        <div className="divide-y divide-gray-200 dark:divide-gray-700">
                            {allIssues?.map((issue: any) => (
                                <Link
                                    key={issue.id}
                                    href={`/reports/${issue.id}`}
                                    className="block px-6 py-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
                                >
                                    <div className="flex items-center justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2">
                                                <span className="text-sm font-medium text-gray-900 dark:text-white">{issue.category}</span>
                                                <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${getStatusColor(issue.status)}`}>
                                                    {issue.status.replace('_', ' ')}
                                                </span>
                                            </div>
                                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{formatDate(issue.created_at)}</p>
                                        </div>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </div>
                </div>
            </main >
        </div >
    )
}
