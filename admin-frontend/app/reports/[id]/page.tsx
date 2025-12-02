import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { formatDateTime, getStatusColor, getPriorityColor, calculateSLAStatus } from '@/lib/utils'
import BackButton from '@/components/BackButton'

export default async function ReportDetails({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params
    const supabase = await createClient()

    // Check authentication
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    // Fetch issue details
    const { data: issue } = await supabase
        .from('issues')
        .select(`
      *,
      cities(name),
      wards(name),
      zones(name),
      users!issues_user_id_fkey(full_name, email),
      assigned_user:users!issues_assigned_to_fkey(full_name, email)
    `)
        .eq('id', id)
        .single()

    if (!issue) {
        return (
            <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
                <div className="text-center">
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Issue Not Found</h1>
                    <p className="text-gray-600 dark:text-gray-400 mb-4">The issue you're looking for doesn't exist.</p>
                    <Link href="/state" className="text-indigo-600 dark:text-indigo-400 hover:underline">
                        Go to Dashboard
                    </Link>
                </div>
            </div>
        )
    }

    // Fetch audit logs
    const { data: auditLogs } = await supabase
        .from('audit_logs')
        .select('*, users(full_name)')
        .eq('issue_id', id)
        .order('created_at', { ascending: false })

    // Calculate SLA status
    const slaStatus = calculateSLAStatus(issue.sla_due_at, issue.status)

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <BackButton />
                            <div>
                                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Issue Details</h1>
                                <p className="text-sm text-gray-600 dark:text-gray-400">ID: {id.slice(0, 8)}...</p>
                            </div>
                        </div>
                        <form action="/api/auth/signout" method="post">
                            <button className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                                Sign out
                            </button>
                        </form>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* Main Details */}
                    <div className="lg:col-span-2 space-y-6">
                        {/* Issue Info Card */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                            <div className="flex items-start justify-between mb-4">
                                <div>
                                    <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">{issue.category}</h2>
                                    <div className="flex items-center gap-2">
                                        <span className={`px-3 py-1 text-sm font-medium rounded-full ${getStatusColor(issue.status)}`}>
                                            {issue.status.replace('_', ' ')}
                                        </span>
                                        <span className={`px-3 py-1 text-sm font-medium rounded-full ${getPriorityColor(issue.priority)}`}>
                                            {issue.priority} priority
                                        </span>
                                    </div>
                                </div>
                                {issue.progress !== undefined && (
                                    <div className="text-right">
                                        <div className="text-3xl font-bold text-gray-900 dark:text-white">{issue.progress}%</div>
                                        <div className="text-xs text-gray-500 dark:text-gray-400">Complete</div>
                                    </div>
                                )}
                            </div>

                            <div className="prose dark:prose-invert max-w-none mb-6">
                                <p className="text-gray-700 dark:text-gray-300">{issue.description}</p>
                            </div>

                            <div className="grid grid-cols-2 gap-4 py-4 border-t border-gray-200 dark:border-gray-700">
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Location</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">{issue.address}</p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                        {issue.latitude.toFixed(6)}, {issue.longitude.toFixed(6)}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Area</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                                        {issue.cities?.name} • {issue.wards?.name || 'Unassigned'}
                                    </p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                        {issue.zones?.name || 'No zone assigned'}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Reported By</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">{issue.users?.full_name}</p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{issue.users?.email}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Reported On</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">{formatDateTime(issue.created_at)}</p>
                                </div>
                            </div>

                            {issue.assigned_to && (
                                <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Assigned To</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">{issue.assigned_user?.full_name}</p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{issue.assigned_user?.email}</p>
                                </div>
                            )}
                        </div>

                        {/* Media Gallery */}
                        {issue.media_urls && issue.media_urls.length > 0 && (
                            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                                    Photos ({issue.media_urls.length})
                                </h3>
                                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                                    {issue.media_urls.map((url: string, index: number) => (
                                        <div key={index} className="aspect-square bg-gray-100 dark:bg-gray-700 rounded-lg overflow-hidden">
                                            <img
                                                src={url}
                                                alt={`Issue photo ${index + 1}`}
                                                className="w-full h-full object-cover hover:scale-105 transition-transform cursor-pointer"
                                            />
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {/* Audio */}
                        {issue.audio_url && (
                            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Audio Description</h3>
                                <audio controls className="w-full">
                                    <source src={issue.audio_url} type="audio/mpeg" />
                                    Your browser does not support the audio element.
                                </audio>
                            </div>
                        )}

                        {/* Timeline */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Activity Timeline</h3>
                            <div className="space-y-4">
                                {auditLogs && auditLogs.length > 0 ? (
                                    auditLogs.map((log: any) => (
                                        <div key={log.id} className="flex gap-4">
                                            <div className="flex-shrink-0 w-2 h-2 mt-2 bg-indigo-600 rounded-full"></div>
                                            <div className="flex-1">
                                                <p className="text-sm font-medium text-gray-900 dark:text-white">{log.action}</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                                    {log.users?.full_name || 'System'} • {formatDateTime(log.created_at)}
                                                </p>
                                            </div>
                                        </div>
                                    ))
                                ) : (
                                    <p className="text-sm text-gray-500 dark:text-gray-400">No activity recorded</p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Sidebar */}
                    <div className="space-y-6">
                        {/* SLA Status */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">SLA Status</h3>
                            <div className="space-y-3">
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Allowed Time</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                                        {issue.sla_allowed_hours || 'N/A'} hours
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Due Date</p>
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                                        {issue.sla_due_at ? formatDateTime(issue.sla_due_at) : 'N/A'}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Status</p>
                                    <span className={`inline-block px-3 py-1 text-sm font-medium rounded-full ${slaStatus.status === 'breached' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400' :
                                        slaStatus.status === 'warning' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400' :
                                            slaStatus.status === 'resolved' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                                                'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                                        }`}>
                                        {slaStatus.status === 'breached' ? '⚠️ Breached' :
                                            slaStatus.status === 'warning' ? '⏰ Warning' :
                                                slaStatus.status === 'resolved' ? '✓ Resolved' :
                                                    '✓ On Track'}
                                    </span>
                                </div>
                                {slaStatus.hoursRemaining !== undefined && slaStatus.hoursRemaining > 0 && (
                                    <div>
                                        <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Time Remaining</p>
                                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                                            {Math.floor(slaStatus.hoursRemaining)} hours
                                        </p>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Stats */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Engagement</h3>
                            <div className="space-y-3">
                                <div className="flex items-center justify-between">
                                    <span className="text-sm text-gray-600 dark:text-gray-400">Upvotes</span>
                                    <span className="text-lg font-bold text-gray-900 dark:text-white">👍 {issue.upvotes || 0}</span>
                                </div>
                            </div>
                        </div>

                        {/* Actions */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Actions</h3>
                            <div className="space-y-2">
                                <button className="w-full px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition">
                                    Update Status
                                </button>
                                <button className="w-full px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition">
                                    Reassign
                                </button>
                                <button className="w-full px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition">
                                    Add Note
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    )
}
