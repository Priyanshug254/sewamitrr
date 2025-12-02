'use client'

import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet.markercluster'
import 'leaflet.markercluster/dist/MarkerCluster.css'
import 'leaflet.markercluster/dist/MarkerCluster.Default.css'

interface MapProps {
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
    wardBoundaries?: Array<{
        id: string
        name: string
        coordinates: [number, number][][]
    }>
    className?: string
}

export default function IssueMap({
    center,
    zoom = 13,
    issues = [],
    wardBoundaries = [],
    className = 'h-96 w-full rounded-lg'
}: MapProps) {
    const mapRef = useRef<L.Map | null>(null)
    const mapContainerRef = useRef<HTMLDivElement>(null)
    const markersRef = useRef<L.MarkerClusterGroup | null>(null)

    useEffect(() => {
        if (!mapContainerRef.current) return

        // Initialize map
        if (!mapRef.current) {
            mapRef.current = L.map(mapContainerRef.current).setView(center, zoom)

            L.tileLayer(process.env.NEXT_PUBLIC_MAP_TILES || 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors',
                maxZoom: 19,
            }).addTo(mapRef.current)
        }

        // Initialize marker cluster group if not exists
        if (!markersRef.current) {
            markersRef.current = L.markerClusterGroup()
            mapRef.current.addLayer(markersRef.current)
        }

        // Clear existing layers (except tiles)
        markersRef.current.clearLayers()

        // Remove existing polygons (ward boundaries)
        mapRef.current.eachLayer((layer) => {
            if (layer instanceof L.Polygon) {
                mapRef.current?.removeLayer(layer)
            }
        })

        // Add ward boundaries
        wardBoundaries.forEach((ward) => {
            if (ward.coordinates && ward.coordinates.length > 0) {
                const polygon = L.polygon(ward.coordinates as any, {
                    color: '#6366f1',
                    weight: 2,
                    fillColor: '#6366f1',
                    fillOpacity: 0.1,
                }).addTo(mapRef.current!)

                polygon.bindPopup(`<strong>${ward.name}</strong>`)
            }
        })

        // Add issue markers to cluster group
        issues.forEach((issue) => {
            const color =
                issue.status === 'resolved' ? '#10b981' :
                    issue.status === 'in_progress' ? '#f59e0b' :
                        issue.priority === 'critical' ? '#ef4444' :
                            issue.priority === 'high' ? '#f97316' :
                                '#6b7280'

            const icon = L.divIcon({
                className: 'custom-marker',
                html: `<div style="background-color: ${color}; width: 24px; height: 24px; border-radius: 50%; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>`,
                iconSize: [24, 24],
                iconAnchor: [12, 12],
            })

            const marker = L.marker([issue.latitude, issue.longitude], { icon })

            marker.bindPopup(`
        <div style="min-width: 200px;">
          <strong>${issue.category}</strong><br/>
          <span style="color: ${color}; font-size: 12px;">${issue.status.replace('_', ' ')}</span><br/>
          <span style="font-size: 12px; color: #666;">Priority: ${issue.priority}</span><br/>
          <a href="/reports/${issue.id}" style="color: #6366f1; font-size: 12px;">View Details →</a>
        </div>
      `)

            markersRef.current?.addLayer(marker)
        })

        // Cleanup on unmount
        return () => {
            if (mapRef.current) {
                mapRef.current.remove()
                mapRef.current = null
                markersRef.current = null
            }
        }
    }, [center, zoom, issues, wardBoundaries])

    return <div ref={mapContainerRef} className={className} />
}
