import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { formatDate } from '@/lib/utils'
import MapWrapper from '@/components/maps/MapWrapper'

export default async function CityDashboard({ params }: { params: Promise<{ cityId: string }> }) {
    const { cityId } = await params
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Get user role and verify access
    const { data: userData } = await supabase
        .from('users')
        .select('role, full_name, city_id')
        .eq('id', user.id)
        .single()

    if (!userData || (userData.role !== 'state_admin' && userData.role !== 'city_admin')) {
        redirect('/login')
    }

    // City admins can only access their own city
    if (userData.role === 'city_admin' && userData.city_id !== cityId) {
        redirect(`/city/${userData.city_id}`)
    }

    // Fetch city details
    const { data: city } = await supabase
        .from('cities')
        .select('*')
        .eq('id', cityId)
        .single()

    // Fetch city analytics
    const { data: cityAnalytics } = await supabase
        .from('analytics_by_city')
        .select('*')
        .eq('city_id', cityId)
        .single()

    // Fetch wards for this city
    const { data: wards } = await supabase
        .from('wards')
        .select('id, name')
        .eq('city_id', cityId)
        .order('name')

    // Fetch zones for this city
    const { data: zones } = await supabase
        .from('zones')
        .select('id, name, supervisor_user_id, supervisor:users!zones_supervisor_user_id_fkey(full_name)')
        .eq('city_id', cityId)
        .order('name')

    // Fetch recent issues for this city
    const { data: recentIssues } = await supabase
        .from('issues')
        .select('id, category, description, status, priority, created_at, ward_id, wards(name)')
        .eq('city_id', cityId)
        .order('created_at', { ascending: false })
        .limit(10)

    // Fetch all active issues for map
    const { data: mapIssues } = await supabase
        .from('issues')
        .select('id, latitude, longitude, category, status, priority')
        .eq('city_id', cityId)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            {userData.role === 'state_admin' && (
                                <Link href="/state" className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-700 transition">
                                    <span className="text-xl font-bold text-white">←</span>
                                </Link>
                            )}
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{city?.name} Dashboard</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">City-level Overview</p>
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
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Total Issues</h3>
                            <div className="h-8 w-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-blue-600 dark:text-blue-400">📊</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{cityAnalytics?.total_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Open Issues</h3>
                            <div className="h-8 w-8 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-yellow-600 dark:text-yellow-400">⚠️</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{cityAnalytics?.open_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Resolved</h3>
                            <div className="h-8 w-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-green-600 dark:text-green-400">✓</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{cityAnalytics?.resolved_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">SLA Compliance</h3>
                            <div className="h-8 w-8 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-purple-600 dark:text-purple-400">⏱️</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{cityAnalytics?.sla_compliance_rate || 0}%</p>
                    </div>
                </div>

                {/* Map Section */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8 p-6">
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">City Issue Map</h2>
                    <MapWrapper
                        center={[city?.latitude || 23.3441, city?.longitude || 85.3096]}
                        zoom={12}
                        issues={mapIssues || []}
                        className="h-[500px] w-full rounded-lg z-0"
                    />
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                    {/* Wards List */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Wards ({wards?.length || 0})</h2>
                        </div>
                        <div className="p-6">
                            <div className="grid grid-cols-2 gap-3 max-h-96 overflow-y-auto">
                                {wards?.map((ward) => (
                                    <Link
                                        key={ward.id}
                                        href={`/ward/${ward.id}`}
                                        className="block p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                                    >
                                        <span className="text-sm font-medium text-gray-900 dark:text-white">{ward.name}</span>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* Zones (CRC) List */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">CRC Zones ({zones?.length || 0})</h2>
                        </div>
                        <div className="divide-y divide-gray-200 dark:divide-gray-700 max-h-96 overflow-y-auto">
                            {zones?.map((zone: any) => (
                                <Link
                                    key={zone.id}
                                    href={`/crc/${zone.id}`}
                                    className="block px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
                                >
                                    <div className="flex items-center justify-between">
                                        <div>
                                            <p className="text-sm font-medium text-gray-900 dark:text-white">{zone.name}</p>
                                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                                Supervisor: {zone.supervisor?.full_name || 'Unassigned'}
                                            </p>
                                        </div>
                                        <span className="text-indigo-600 dark:text-indigo-400">→</span>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Recent Issues */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                    <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Issues</h2>
                    </div>
                    <div className="divide-y divide-gray-200 dark:divide-gray-700">
                        {recentIssues?.map((issue: any) => (
                            <Link
                                key={issue.id}
                                href={`/reports/${issue.id}`}
                                className="block px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
                            >
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <div className="flex items-center gap-2 mb-1">
                                            <span className="text-sm font-medium text-gray-900 dark:text-white">{issue.category}</span>
                                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${issue.status === 'resolved' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                                                issue.status === 'in_progress' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400' :
                                                    'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                                                }`}>
                                                {issue.status.replace('_', ' ')}
                                            </span>
                                        </div>
                                        <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-1">{issue.description}</p>
                                        <div className="flex items-center gap-4 mt-2 text-xs text-gray-500 dark:text-gray-400">
                                            <span>{issue.wards?.name || 'Unassigned'}</span>
                                            <span>•</span>
                                            <span>{formatDate(issue.created_at)}</span>
                                        </div>
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                </div>
            </main>
        </div>
    )
}
