// Database types
export interface User {
    id: string
    email: string
    full_name: string
    role: 'citizen' | 'worker' | 'ward_supervisor' | 'crc_supervisor' | 'city_admin' | 'state_admin'
    city_id?: string
    ward_id?: string
    zone_id?: string
    phone?: string
    photo_url?: string
    language: string
    total_reports: number
    resolved_issues: number
    community_rank: number
    points: number
    metadata?: Record<string, any>
    created_at: string
    updated_at: string
}

export interface City {
    id: string
    name: string
    state: string
    population?: number
    metadata?: Record<string, any>
    created_at: string
}

export interface Ward {
    id: string
    name: string
    city_id: string
    population?: number
    metadata?: Record<string, any>
    created_at: string
}

export interface Zone {
    id: string
    name: string
    city_id: string
    ward_ids: string[]
    supervisor_user_id?: string
    metadata?: Record<string, any>
    created_at: string
}

export interface Issue {
    id: string
    user_id: string
    city_id?: string
    ward_id?: string
    zone_id?: string
    category: string
    description: string
    address: string
    latitude: number
    longitude: number
    media_urls: string[]
    audio_url?: string
    priority: 'low' | 'medium' | 'high' | 'critical'
    status: 'submitted' | 'crc_verified' | 'forwarded_to_ward' | 'in_progress' | 'resolved' | 'rejected'
    progress: number
    assigned_to?: string
    sla_allowed_hours?: number
    sla_due_at?: string
    upvotes: number
    update_logs?: any[]
    created_at: string
    updated_at: string
}

export interface Assignment {
    id: string
    issue_id: string
    assigned_by: string
    assigned_to: string
    eta?: string
    status: 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
    notes?: string
    history?: any[]
    created_at: string
    updated_at: string
}

export interface AuditLog {
    id: string
    issue_id?: string
    action: string
    performed_by?: string
    old_data?: Record<string, any>
    new_data?: Record<string, any>
    metadata?: Record<string, any>
    created_at: string
}

export interface ContractorProfile {
    id: string
    user_id: string
    specializations: string[]
    active_assignments: number
    completed_assignments: number
    rating: number
    metadata?: Record<string, any>
    created_at: string
    updated_at: string
}

// Analytics types
export interface StateAnalytics {
    total_issues: number
    open_issues: number
    resolved_issues: number
    rejected_issues: number
    unverified_issues: number
    in_progress_issues: number
    sla_compliance_rate: number
    sla_breached: number
    total_reporters: number
    active_workers: number
    avg_resolution_time_hours: number
    refreshed_at: string
}

export interface CityAnalytics {
    city_id: string
    city_name: string
    total_issues: number
    open_issues: number
    resolved_issues: number
    unverified_issues: number
    in_progress_issues: number
    sla_compliance_rate: number
    critical_issues: number
    high_priority_issues: number
    avg_resolution_time_hours: number
    refreshed_at: string
}

export interface WardAnalytics {
    ward_id: string
    ward_name: string
    city_id: string
    city_name: string
    total_issues: number
    open_issues: number
    resolved_issues: number
    in_progress_issues: number
    assigned_issues: number
    avg_resolution_time_hours: number
    active_workers: number
    refreshed_at: string
}

export interface ZoneAnalytics {
    zone_id: string
    zone_name: string
    city_id: string
    city_name: string
    supervisor_user_id?: string
    supervisor_name?: string
    total_issues: number
    unverified_issues: number
    verified_issues: number
    forwarded_issues: number
    rejected_issues: number
    resolved_issues: number
    avg_verification_time_hours: number
    refreshed_at: string
}
