'use client'

import dynamic from 'next/dynamic'

const IssueMap = dynamic(() => import('./IssueMap'), { ssr: false })

interface MapWrapperProps {
    center: [number, number]
    zoom?: number
    issues?: Array<{
        id: string
        latitude: number
        longitude: number
        category: string
        status: string
        priority: string
    }>
    className?: string
}

export default function MapWrapper(props: MapWrapperProps) {
    return <IssueMap {...props} />
}
