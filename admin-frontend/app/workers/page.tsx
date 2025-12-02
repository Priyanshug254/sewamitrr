import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function WorkersPage() {
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Get user role
    const { data: userData } = await supabase
        .from('users')
        .select('role, full_name, city_id')
        .eq('id', user.id)
        .single()

    // Fetch contractors based on role
    let contractorsQuery = supabase
        .from('users')
        .select(`
      id, 
      full_name, 
      email, 
      phone,
      cities(name),
      contractor_profiles(
        specializations, 
        rating, 
        active_assignments, 
        completed_assignments,
        metadata
      )
    `)
        .eq('role', 'worker')
        .order('full_name')

    // City admins and ward supervisors see only their city's contractors
    if (userData?.role === 'city_admin' || userData?.role === 'ward_supervisor') {
        contractorsQuery = contractorsQuery.eq('city_id', userData.city_id)
    }

    const { data: contractors } = await contractorsQuery

    // Fetch contractor performance analytics
    const { data: performanceData } = await supabase
        .from('analytics_contractor_performance')
        .select('*')
        .order('completed_count', { ascending: false })

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <Link
                                href="/state"
                                className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-700 transition"
                            >
                                <span className="text-xl font-bold text-white">←</span>
                            </Link>
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Workers Management</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">Manage contractors and their assignments</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-4">
                            <span className="text-sm text-gray-600 dark:text-gray-400">Welcome, {userData?.full_name}</span>
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
                {/* Summary Cards */}
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Total Contractors</h3>
                            <div className="h-8 w-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-blue-600 dark:text-blue-400">👷</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{contractors?.length || 0}</p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Active Assignments</h3>
                            <div className="h-8 w-8 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-yellow-600 dark:text-yellow-400">🔄</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">
                            {contractors?.reduce((sum: number, c: any) => sum + (c.contractor_profiles?.active_assignments || 0), 0) || 0}
                        </p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Completed</h3>
                            <div className="h-8 w-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-green-600 dark:text-green-400">✓</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">
                            {contractors?.reduce((sum: number, c: any) => sum + (c.contractor_profiles?.completed_assignments || 0), 0) || 0}
                        </p>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400">Avg Rating</h3>
                            <div className="h-8 w-8 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <span className="text-purple-600 dark:text-purple-400">⭐</span>
                            </div>
                        </div>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">
                            {contractors && contractors.length > 0
                                ? (contractors.reduce((sum: number, c: any) => sum + (c.contractor_profiles?.rating || 0), 0) / contractors.length).toFixed(1)
                                : '0.0'}
                        </p>
                    </div>
                </div>

                {/* Contractors Table */}
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                    <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
                        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">All Contractors</h2>
                        <button className="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition">
                            + Add Contractor
                        </button>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                            <thead className="bg-gray-50 dark:bg-gray-900">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Name
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Contact
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        City
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Specializations
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Rating
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Active
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Completed
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                                {contractors && contractors.length > 0 ? (
                                    contractors.map((contractor: any) => (
                                        <tr key={contractor.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition">
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm font-medium text-gray-900 dark:text-white">{contractor.full_name}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-600 dark:text-gray-400">{contractor.email}</div>
                                                <div className="text-xs text-gray-500 dark:text-gray-400">{contractor.phone || 'N/A'}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-900 dark:text-white">{contractor.cities?.name || 'N/A'}</div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex flex-wrap gap-1">
                                                    {contractor.contractor_profiles?.specializations?.slice(0, 2).map((spec: string, idx: number) => (
                                                        <span key={idx} className="px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 rounded">
                                                            {spec}
                                                        </span>
                                                    ))}
                                                    {contractor.contractor_profiles?.specializations?.length > 2 && (
                                                        <span className="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded">
                                                            +{contractor.contractor_profiles.specializations.length - 2}
                                                        </span>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="flex items-center gap-1">
                                                    <span className="text-yellow-500">⭐</span>
                                                    <span className="text-sm font-medium text-gray-900 dark:text-white">
                                                        {contractor.contractor_profiles?.rating?.toFixed(1) || 'N/A'}
                                                    </span>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-900 dark:text-white">
                                                    {contractor.contractor_profiles?.active_assignments || 0}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-900 dark:text-white">
                                                    {contractor.contractor_profiles?.completed_assignments || 0}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm">
                                                <button className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-900 dark:hover:text-indigo-300 font-medium">
                                                    View Profile
                                                </button>
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td colSpan={8} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                                            No contractors found
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    )
}
