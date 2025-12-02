'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface Analytics {
    total_issues: number
    open_issues: number
    resolved_issues: number
    sla_compliance_rate: number
    [key: string]: any
}

export function useAnalytics(type: 'state' | 'city' | 'ward' | 'zone', id?: string) {
    const [analytics, setAnalytics] = useState<Analytics | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const supabase = createClient()

    useEffect(() => {
        fetchAnalytics()

        // Refresh analytics every 30 seconds
        const interval = setInterval(fetchAnalytics, 30000)

        return () => clearInterval(interval)
    }, [type, id])

    async function fetchAnalytics() {
        try {
            setLoading(true)
            let data = null

            if (type === 'state') {
                const { data: stateData, error: stateError } = await supabase
                    .from('analytics_state_overview')
                    .select('*')
                    .single()

                if (stateError) throw stateError
                data = stateData
            } else if (type === 'city' && id) {
                const { data: cityData, error: cityError } = await supabase
                    .from('analytics_by_city')
                    .select('*')
                    .eq('city_id', id)
                    .single()

                if (cityError) throw cityError
                data = cityData
            } else if (type === 'ward' && id) {
                const { data: wardData, error: wardError } = await supabase
                    .from('analytics_by_ward')
                    .select('*')
                    .eq('ward_id', id)
                    .single()

                if (wardError) throw wardError
                data = wardData
            } else if (type === 'zone' && id) {
                const { data: zoneData, error: zoneError } = await supabase
                    .from('analytics_by_zone')
                    .select('*')
                    .eq('zone_id', id)
                    .single()

                if (zoneError) throw zoneError
                data = zoneData
            }

            setAnalytics(data)
            setError(null)
        } catch (err: any) {
            setError(err.message)
            console.error('Error fetching analytics:', err)
        } finally {
            setLoading(false)
        }
    }

    return { analytics, loading, error, refetch: fetchAnalytics }
}
