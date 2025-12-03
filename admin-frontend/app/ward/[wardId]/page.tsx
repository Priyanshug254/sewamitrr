import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { formatDate, getStatusColor, getPriorityColor } from '@/lib/utils'
import MapWrapper from '@/components/maps/MapWrapper'
import ContractorManagement from '@/components/ContractorManagement'

export default async function WardDashboard({ params }: { params: Promise<{ wardId: string }> }) {
    const { wardId } = await params
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Get user role and verify access
    const { data: userData } = await supabase
        .from('users')
        .select('role, full_name, ward_id')
        .eq('id', user.id)
        .single()

    if (!userData || (userData.role !== 'state_admin' && userData.role !== 'city_admin' && userData.role !== 'ward_supervisor')) {
        redirect('/login')
    }

    // Ward supervisors can only access their own ward
    if (userData.role === 'ward_supervisor' && userData.ward_id !== wardId) {
        redirect(`/ward/${userData.ward_id}`)
    }

    // Fetch ward details
    const { data: ward } = await supabase
        .from('wards')
        .select('*, cities(name)')
        .eq('id', wardId)
        .single()

    // Fetch ward analytics
    const { data: wardAnalytics } = await supabase
        .from('analytics_by_ward')
        .select('*')
        .eq('ward_id', wardId)
        .single()

    // Fetch issues forwarded to this ward (CRC-verified only)
    const { data: forwardedIssues } = await supabase
        .from('issues')
        .select('id, category, description, address, priority, status, created_at, assigned_to')
        .eq('ward_id', wardId)
        .eq('status', 'forwarded_to_ward') // Only CRC-verified issues
        .order('created_at', { ascending: false })
        .limit(20)

    // Fetch in-progress issues
    const { data: inProgressIssues } = await supabase
        .from('issues')
        .select('id, category, description, status, priority, progress, created_at, users!issues_assigned_to_fkey(full_name)')
        .eq('ward_id', wardId)
        .eq('status', 'in_progress')
        .order('created_at', { ascending: false })

    // Fetch contractors for this ward
    const { data: contractors } = await supabase
        .from('users')
        .select('id, full_name, email, contractor_profiles(specializations, rating, active_assignments, completed_assignments)')
        .eq('role', 'worker')
        .eq('city_id', ward?.city_id)
        .order('full_name')

    // Fetch all active issues for map
    const { data: mapIssues } = await supabase
        .from('issues')
        .select('id, latitude, longitude, category, status, priority')
        .eq('ward_id', wardId)
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
                                    href={`/city/${ward?.city_id}`}
                                    className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-700 transition"
                                >
                                    <span className="text-xl font-bold text-white">←</span>
                                </Link>
                            )}
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{ward?.name}</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">
                                    {ward?.cities?.name} • Ward Supervisor Dashboard
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
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Total Issues</h3>
                            <div className="h-8 w-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-blue-600 dark:text-blue-400">📊</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{wardAnalytics?.total_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Open Issues</h3>
                            <div className="h-8 w-8 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-yellow-600 dark:text-yellow-400">⚠️</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{wardAnalytics?.open_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">In Progress</h3>
                            <div className="h-8 w-8 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-purple-600 dark:text-purple-400">🔄</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{wardAnalytics?.in_progress_issues || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Resolved</h3>
                            <div className="h-8 w-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-green-600 dark:text-green-400">✓</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{wardAnalytics?.resolved_issues || 0}</p>
                    </div>
                </div>

                {/* Map Section */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8 p-6">
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Ward Issue Map</h2>
                    <MapWrapper
                        center={[23.3441, 85.3096]}
                        zoom={14}
                        issues={mapIssues || []}
                        className="h-[500px] w-full rounded-lg z-0"
                    />
                </div>

                {/* Forwarded Issues Queue */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 mb-8">
                    <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                            Forwarded Issues ({forwardedIssues?.length || 0})
                        </h2>
                        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                            Issues forwarded from CRC - assign to contractors
                        </p>
                    </div>
                    <div className="divide-y divide-gray-200 dark:divide-gray-700">
                        {forwardedIssues && forwardedIssues.length > 0 ? (
                            forwardedIssues.map((issue: any) => (
                                <div key={issue.id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-2">
                                                <span className="text-sm font-medium text-gray-900 dark:text-white">{issue.category}</span>
                                                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getPriorityColor(issue.priority)}`}>
                                                    {issue.priority}
                                                </span>
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
                                                View
                                            </Link>
                                            <button className="px-3 py-1.5 text-sm font-medium text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg transition">
                                                Assign Contractor
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))
                        ) : (
                            <div className="px-6 py-12 text-center">
                                <p className="text-gray-500 dark:text-gray-400">No forwarded issues pending assignment</p>
                            </div>
                        )}
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    {/* In Progress Issues */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                                In Progress ({inProgressIssues?.length || 0})
                            </h2>
                        </div>
                        <div className="divide-y divide-gray-200 dark:divide-gray-700 max-h-96 overflow-y-auto">
                            {inProgressIssues && inProgressIssues.length > 0 ? (
                                inProgressIssues.map((issue: any) => (
                                    <Link
                                        key={issue.id}
                                        href={`/reports/${issue.id}`}
                                        className="block px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
                                    >
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-sm font-medium text-gray-900 dark:text-white">{issue.category}</span>
                                            <span className="text-sm font-bold text-indigo-600 dark:text-indigo-400">{issue.progress}%</span>
                                        </div>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">
                                            Assigned to: {issue.users?.full_name || 'Unassigned'}
                                        </p>
                                        <div className="mt-2 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                            <div
                                                className="bg-indigo-600 h-2 rounded-full transition-all"
                                                style={{ width: `${issue.progress}%` }}
                                            ></div>
                                        </div>
                                    </Link>
                                ))
                            ) : (
                                <div className="px-6 py-12 text-center">
                                    <p className="text-gray-500 dark:text-gray-400">No issues in progress</p>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Contractor Management */}
                    <ContractorManagement
                        wardId={wardId}
                        cityId={ward?.city_id || ''}
                        contractors={contractors || []}
                    />
                </div>
            </main>
        </div>
    )
}
