'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { Issue } from '@/lib/types'

export function useIssues(filters?: {
    cityId?: string
    wardId?: string
    zoneId?: string
    status?: string
}) {
    const [issues, setIssues] = useState<Issue[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const supabase = createClient()

    useEffect(() => {
        fetchIssues()

        // Set up realtime subscription
        const channel = supabase
            .channel('issues-changes')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'issues',
                    filter: filters?.cityId ? `city_id=eq.${filters.cityId}` : undefined,
                },
                (payload) => {
                    console.log('Issue change received:', payload)

                    if (payload.eventType === 'INSERT') {
                        setIssues((current) => [payload.new as Issue, ...current])
                    } else if (payload.eventType === 'UPDATE') {
                        setIssues((current) =>
                            current.map((issue) =>
                                issue.id === payload.new.id ? (payload.new as Issue) : issue
                            )
                        )
                    } else if (payload.eventType === 'DELETE') {
                        setIssues((current) =>
                            current.filter((issue) => issue.id !== payload.old.id)
                        )
                    }
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [filters?.cityId, filters?.wardId, filters?.zoneId, filters?.status])

    async function fetchIssues() {
        try {
            setLoading(true)
            let query = supabase
                .from('issues')
                .select('*')
                .order('created_at', { ascending: false })

            if (filters?.cityId) query = query.eq('city_id', filters.cityId)
            if (filters?.wardId) query = query.eq('ward_id', filters.wardId)
            if (filters?.zoneId) query = query.eq('zone_id', filters.zoneId)
            if (filters?.status) query = query.eq('status', filters.status)

            const { data, error: fetchError } = await query

            if (fetchError) throw fetchError
            setIssues(data || [])
            setError(null)
        } catch (err: any) {
            setError(err.message)
            console.error('Error fetching issues:', err)
        } finally {
            setLoading(false)
        }
    }

    return { issues, loading, error, refetch: fetchIssues }
}
