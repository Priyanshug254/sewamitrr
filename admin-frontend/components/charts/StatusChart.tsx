'use client'

import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'

interface StatusChartProps {
    data: {
        submitted: number
        crc_verified: number
        forwarded_to_ward: number
        in_progress: number
        resolved: number
        rejected: number
    }
}

const COLORS = {
    submitted: '#3b82f6',
    crc_verified: '#8b5cf6',
    forwarded_to_ward: '#6366f1',
    in_progress: '#f59e0b',
    resolved: '#10b981',
    rejected: '#ef4444',
}

const STATUS_LABELS = {
    submitted: 'Submitted',
    crc_verified: 'CRC Verified',
    forwarded_to_ward: 'Forwarded to Ward',
    in_progress: 'In Progress',
    resolved: 'Resolved',
    rejected: 'Rejected',
}

export default function StatusChart({ data }: StatusChartProps) {
    const chartData = Object.entries(data).map(([key, value]) => ({
        name: STATUS_LABELS[key as keyof typeof STATUS_LABELS],
        value,
        color: COLORS[key as keyof typeof COLORS],
    }))

    return (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Issues by Status</h3>
            <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                    <Pie
                        data={chartData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => `${name}: ${((percent || 0) * 100).toFixed(0)}%`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                    >
                        {chartData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                    </Pie>
                    <Tooltip
                        contentStyle={{
                            backgroundColor: '#1f2937',
                            border: '1px solid #374151',
                            borderRadius: '8px',
                            color: '#fff'
                        }}
                    />
                    <Legend />
                </PieChart>
            </ResponsiveContainer>
        </div>
    )
}
