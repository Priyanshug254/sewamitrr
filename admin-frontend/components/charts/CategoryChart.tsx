'use client'

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

interface CategoryChartProps {
    data: Array<{
        category: string
        total_issues: number
        resolved_issues: number
        open_issues: number
    }>
}

export default function CategoryChart({ data }: CategoryChartProps) {
    return (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Issues by Category</h3>
            <ResponsiveContainer width="100%" height={300}>
                <BarChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                    <XAxis
                        dataKey="category"
                        stroke="#9ca3af"
                        tick={{ fill: '#9ca3af', fontSize: 12 }}
                        angle={-45}
                        textAnchor="end"
                        height={80}
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
                    <Bar dataKey="total_issues" fill="#6366f1" name="Total" />
                    <Bar dataKey="resolved_issues" fill="#10b981" name="Resolved" />
                    <Bar dataKey="open_issues" fill="#f59e0b" name="Open" />
                </BarChart>
            </ResponsiveContainer>
        </div>
    )
}
