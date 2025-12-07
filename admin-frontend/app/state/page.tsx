import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { formatDate } from '@/lib/utils'
import MapWrapper from '@/components/maps/MapWrapper'
import StatusChart from '@/components/charts/StatusChart'
import CategoryChart from '@/components/charts/CategoryChart'

export default async function StateDashboard() {
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Get user role
    const { data: userData } = await supabase
        .from('users')
        .select('role, full_name')
        .eq('id', user.id)
        .single()

    if (!userData || userData.role !== 'state_admin') {
        redirect('/login')
    }

    // Fetch state analytics
    const { data: stateAnalytics } = await supabase
        .from('analytics_state_overview')
        .select('*')
        .single()

    // Fetch city analytics
    const { data: cityAnalytics } = await supabase
        .from('analytics_by_city')
        .select('*')
        .order('total_issues', { ascending: false })

    // Fetch recent issues
    const { data: recentIssues } = await supabase
        .from('issues')
        .select('id, category, description, status, priority, created_at, city_id, cities(name)')
        .order('created_at', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(10)

    // Fetch all active issues for map
    const { data: mapIssues } = await supabase
        .from('issues')
        .select('id, latitude, longitude, category, status, priority')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)

    // Prepare chart data
    const { data: issuesByStatus } = await supabase
        .from('issues')
        .select('status')

    const statusCounts = {
        submitted: issuesByStatus?.filter(i => i.status === 'submitted').length || 0,
        crc_verified: issuesByStatus?.filter(i => i.status === 'crc_verified').length || 0,
        forwarded_to_ward: issuesByStatus?.filter(i => i.status === 'forwarded_to_ward').length || 0,
        in_progress: issuesByStatus?.filter(i => i.status === 'in_progress').length || 0,
        resolved: issuesByStatus?.filter(i => i.status === 'resolved').length || 0,
        rejected: issuesByStatus?.filter(i => i.status === 'rejected').length || 0,
    }

    const { data: issuesByCategory } = await supabase
        .from('issues')
        .select('category, status')

    // Define the 5 valid categories from mobile app
    const VALID_CATEGORIES = ['road', 'water', 'electricity', 'garbage', 'others'];
    const CATEGORY_LABELS: Record<string, string> = {
        road: 'Road',
        water: 'Water',
        electricity: 'Electricity',
        garbage: 'Garbage',
        others: 'Others'
    };

    // Initialize category counts
    const categoryCounts: Record<string, { total: number, resolved: number, open: number }> = {
        road: { total: 0, resolved: 0, open: 0 },
        water: { total: 0, resolved: 0, open: 0 },
        electricity: { total: 0, resolved: 0, open: 0 },
        garbage: { total: 0, resolved: 0, open: 0 },
        others: { total: 0, resolved: 0, open: 0 }
    };

    // Count issues by category
    issuesByCategory?.forEach((issue) => {
        const cat = VALID_CATEGORIES.includes(issue.category) ? issue.category : 'others';
        categoryCounts[cat].total++;
        if (issue.status === 'resolved') categoryCounts[cat].resolved++;
        else categoryCounts[cat].open++;
    });

    // Convert to array format for chart
    const categoryData = VALID_CATEGORIES.map(cat => ({
        category: CATEGORY_LABELS[cat],
        total_issues: categoryCounts[cat].total,
        resolved_issues: categoryCounts[cat].resolved,
        open_issues: categoryCounts[cat].open,
    }))

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <div className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center">
                                <span className="text-xl font-bold text-white">S</span>
                            </div>
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">State Dashboard</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">Jharkhand Civic Issues Overview</p>
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
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{stateAnalytics?.total_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">All time</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Open Issues</h3>
                            <div className="h-8 w-8 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-yellow-600 dark:text-yellow-400">⚠️</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{stateAnalytics?.open_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Pending resolution</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Resolved</h3>
                            <div className="h-8 w-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-green-600 dark:text-green-400">✓</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{stateAnalytics?.resolved_issues || 0}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Completed</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">SLA Compliance</h3>
                            <div className="h-8 w-8 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-purple-600 dark:text-purple-400">⏱️</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{stateAnalytics?.sla_compliance_rate || 0}%</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">On-time resolution</p>
                    </div>
                </div>

                {/* Map Section */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8 p-6">
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Issue Heatmap</h2>
                    <MapWrapper
                        center={[23.3441, 85.3096]} // Ranchi coordinates as default center
                        zoom={8}
                        issues={mapIssues || []}
                        className="h-[500px] w-full rounded-lg z-0"
                    />
                </div>

                {/* Analytics Charts */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                    <StatusChart data={statusCounts} />
                    <CategoryChart data={categoryData} />
                </div>

                {/* City Analytics Table */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8">
                    <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">City Overview</h2>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                            <thead className="bg-gray-50 dark:bg-gray-900">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">City</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Total Issues</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Open</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Resolved</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">SLA %</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                                {cityAnalytics?.map((city) => (
                                    <tr key={city.city_id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm font-medium text-gray-900 dark:text-white">{city.city_name}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm text-gray-900 dark:text-white">{city.total_issues}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm text-yellow-600 dark:text-yellow-400">{city.open_issues}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm text-green-600 dark:text-green-400">{city.resolved_issues}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm text-gray-900 dark:text-white">{city.sla_compliance_rate}%</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                                            <Link
                                                href={`/city/${city.city_id}`}
                                                className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-900 dark:hover:text-indigo-300 font-medium"
                                            >
                                                View Details →
                                            </Link>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
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
                                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${issue.priority === 'critical' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400' :
                                                issue.priority === 'high' ? 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400' :
                                                    'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                                                }`}>
                                                {issue.priority}
                                            </span>
                                        </div>
                                        <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-1">{issue.description}</p>
                                        <div className="flex items-center gap-4 mt-2 text-xs text-gray-500 dark:text-gray-400">
                                            <span>{issue.cities?.name}</span>
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
