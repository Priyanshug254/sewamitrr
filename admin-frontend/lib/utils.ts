import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date): string {
    return new Date(date).toLocaleDateString('en-IN', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
    })
}

export function formatDateTime(date: string | Date): string {
    return new Date(date).toLocaleString('en-IN', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    })
}

export function formatRelativeTime(date: string | Date): string {
    const now = new Date()
    const then = new Date(date)
    const diffMs = now.getTime() - then.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    if (diffDays < 7) return `${diffDays}d ago`
    return formatDate(date)
}

export function getStatusColor(status: string): string {
    const colors: Record<string, string> = {
        submitted: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
        crc_verified: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
        forwarded_to_ward: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200',
        in_progress: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
        resolved: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
        rejected: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    }
    return colors[status] || 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
}

export function getPriorityColor(priority: string): string {
    const colors: Record<string, string> = {
        low: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
        medium: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
        high: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
        critical: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    }
    return colors[priority] || 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
}

export function calculateSLAStatus(sla_due_at?: string, status?: string): {
    status: 'compliant' | 'warning' | 'breached' | 'resolved'
    hoursRemaining?: number
} {
    if (!sla_due_at) return { status: 'compliant' }
    if (status === 'resolved') return { status: 'resolved' }

    const now = new Date()
    const due = new Date(sla_due_at)
    const diffMs = due.getTime() - now.getTime()
    const hoursRemaining = diffMs / 3600000

    if (hoursRemaining < 0) return { status: 'breached', hoursRemaining: 0 }
    if (hoursRemaining < 6) return { status: 'warning', hoursRemaining }
    return { status: 'compliant', hoursRemaining }
}
