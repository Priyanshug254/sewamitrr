'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

interface TrendChartProps {
    data: Array<{
        date: string
        submitted: number
        resolved: number
        in_progress: number
    }>
}

export default function TrendChart({ data }: TrendChartProps) {
    return (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Issue Trends (Last 30 Days)</h3>
            <ResponsiveContainer width="100%" height={300}>
                <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                    <XAxis
                        dataKey="date"
                        stroke="#9ca3af"
                        tick={{ fill: '#9ca3af', fontSize: 12 }}
                    />
                    <YAxis stroke="#9ca3af" tick={{ fill: '#9ca3af' }} />
                    <Tooltip
                        contentStyle={{
                            backgroundColor: '#1f2937',
                            border: '1px solid #374151',
                            borderRadius: '8px',
                            color: '#fff'
                        }}
                    />
                    <Legend />
                    <Line
                        type="monotone"
                        dataKey="submitted"
                        stroke="#3b82f6"
                        strokeWidth={2}
                        name="Submitted"
                    />
                    <Line
                        type="monotone"
                        dataKey="in_progress"
                        stroke="#f59e0b"
                        strokeWidth={2}
                        name="In Progress"
                    />
                    <Line
                        type="monotone"
                        dataKey="resolved"
                        stroke="#10b981"
                        strokeWidth={2}
                        name="Resolved"
                    />
                </LineChart>
            </ResponsiveContainer>
        </div>
    )
}
