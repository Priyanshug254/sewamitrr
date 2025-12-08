
'use client'

import { Download } from 'lucide-react'
import { useState } from 'react'

interface DownloadReportsButtonProps {
    scope: 'city' | 'ward' | 'zone' | 'state'
    id?: string
    className?: string
}

export default function DownloadReportsButton({ scope, id, className }: DownloadReportsButtonProps) {
    const [loading, setLoading] = useState(false)

    const handleDownload = async () => {
        try {
            setLoading(true)
            const queryParams = new URLSearchParams({
                scope,
                format: 'csv'
            })

            if (id) queryParams.append('id', id)

            const response = await fetch(`/api/reports/export?${queryParams.toString()}`)

            if (!response.ok) {
                const error = await response.json()
                throw new Error(error.error || 'Failed to download reports')
            }

            // Trigger download from blob
            const blob = await response.blob()
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url

            // Try to get filename from header
            const contentDisposition = response.headers.get('Content-Disposition')
            let filename = `reports_${scope}.csv`
            if (contentDisposition) {
                const matches = /filename="([^"]*)"/.exec(contentDisposition)
                if (matches && matches[1]) filename = matches[1]
            }

            a.download = filename
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(url)
            document.body.removeChild(a)

        } catch (error: any) {
            alert('Error downloading reports: ' + error.message)
            console.error(error)
        } finally {
            setLoading(false)
        }
    }

    return (
        <button
            onClick={handleDownload}
            disabled={loading}
            className={`flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition disabled:opacity-50 ${className || ''}`}
        >
            <Download className="h-4 w-4" />
            {loading ? 'Downloading...' : 'Export Reports'}
        </button>
    )
}
