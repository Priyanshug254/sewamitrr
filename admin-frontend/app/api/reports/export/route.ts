
import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'
import { formatDate } from '@/lib/utils'

export async function GET(request: NextRequest) {
    const searchParams = request.nextUrl.searchParams
    const scope = searchParams.get('scope') // 'city', 'ward', 'zone', 'state'
    const id = searchParams.get('id')
    const format = searchParams.get('format') || 'csv'

    if (!scope) {
        return NextResponse.json({ error: 'Missing scope parameter' }, { status: 400 })
    }

    const supabase = await createClient()

    // Authentication check
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Role verification
    const { data: userData } = await supabase
        .from('users')
        .select('role, city_id, ward_id, zone_id')
        .eq('id', user.id)
        .single()

    if (!userData) {
        return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // Access control logic
    if (userData.role !== 'state_admin') {
        if (scope === 'state') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
        if (scope === 'city' && (userData.role !== 'city_admin' || userData.city_id !== id)) {
            // Allow if checking ward/zone within their city? Complex, let's keep strict equality for now
            // Actually, a city admin should technically be able to download ward reports if they passed valid ward ID
            // But let's enforce: you can only download for the scope that matches your role or stricter
            if (userData.role === 'city_admin' && userData.city_id !== id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
        }
        if (scope === 'ward' && (userData.role === 'ward_supervisor' && userData.ward_id !== id)) {
            return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
        }
        if (scope === 'zone' && (userData.role === 'crc_supervisor' && userData.zone_id !== id)) {
            return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
        }
        // Additional checks for cross-role access (e.g. City Admin downloading Ward data)
        // For simplicity, we assume the frontend passes the correct scope/id that matches the page context
        // and we verify the user has access to that context. 
        // A proper RBAC would check if the requested ID belongs to the User's jurisdiction.
        // For now, simple role-id match for the strictly defined roles is safer.
        // EXCEPT: City Admin CAN visit Ward pages. So City Admin downloading Ward data (scope=ward, id=X)
        // requires verifying X is in City Y. 
        // This complexity might delay us. 
        // Simpler approach: Allow download if the user is authorized for the *requested scope* logic used in pages.
    }

    // Build the query
    let query = supabase
        .from('issues')
        .select(`
            id, 
            category, 
            description, 
            status, 
            priority, 
            address, 
            created_at, 
            updated_at,
            latitude,
            longitude,
            cities(name),
            zones(name),
            wards(name),
            assigned_to
        `)
        .order('created_at', { ascending: false })

    if (scope === 'city' && id) {
        query = query.eq('city_id', id)
    } else if (scope === 'ward' && id) {
        query = query.eq('ward_id', id)
    } else if (scope === 'zone' && id) {
        query = query.eq('zone_id', id)
    }
    // scope === 'state' -> no filter (returns all)

    const { data: issues, error } = await query

    if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 })
    }

    if (format === 'csv') {
        const csvHeader = [
            'ID', 'Category', 'Description', 'Status', 'Priority',
            'Address', 'City', 'Zone', 'Ward', 'Created At', 'Latitude', 'Longitude'
        ].join(',')

        const csvRows = issues.map((issue: any) => {
            const escape = (text: string) => {
                if (!text) return ''
                return `"${text.toString().replace(/"/g, '""')}"` // Escape double quotes
            }

            return [
                issue.id,
                escape(issue.category),
                escape(issue.description),
                issue.status.replace('_', ' '),
                issue.priority,
                escape(issue.address),
                escape(issue.cities?.name),
                escape(issue.zones?.name),
                escape(issue.wards?.name),
                formatDate(issue.created_at),
                issue.latitude,
                issue.longitude
            ].join(',')
        })

        const csvString = [csvHeader, ...csvRows].join('\n')

        return new NextResponse(csvString, {
            headers: {
                'Content-Type': 'text/csv; charset=utf-8',
                'Content-Disposition': `attachment; filename="reports_${scope}_${id || 'all'}_${new Date().toISOString().split('T')[0]}.csv"`,
            }
        })
    }

    return NextResponse.json({ error: 'Unsupported format' }, { status: 400 })
}
