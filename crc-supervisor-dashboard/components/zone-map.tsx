"use client"

import { useEffect, useRef } from "react"
import L from "leaflet"
import "leaflet/dist/leaflet.css"
import "leaflet.markercluster/dist/MarkerCluster.css"
import "leaflet.markercluster/dist/MarkerCluster.Default.css"
import MarkerClusterGroup from "leaflet.markercluster"
import type { Zone, Issue } from "@/lib/types"

interface ZoneMapProps {
  zone: Zone
  issues: Issue[]
  onMarkerClick: (issueId: string) => void
}

export function ZoneMap({ zone, issues, onMarkerClick }: ZoneMapProps) {
  const mapContainer = useRef<HTMLDivElement>(null)
  const map = useRef<L.Map | null>(null)

  useEffect(() => {
    if (!mapContainer.current) return

    // Initialize map
    map.current = L.map(mapContainer.current).setView([zone.centerLat, zone.centerLng], 13)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "© OpenStreetMap contributors",
      maxZoom: 19,
    }).addTo(map.current)

    // Draw zone polygon
    const zonePolygon = L.polygon(zone.boundaries, {
      color: "#3b82f6",
      weight: 2,
      opacity: 0.6,
      fillColor: "#3b82f6",
      fillOpacity: 0.1,
    }).addTo(map.current)

    // Draw ward boundaries
    zone.wards.forEach((ward) => {
      const wardColors = ["#22c55e", "#f59e0b", "#ef4444"]
      const color = wardColors[(Math.random() * wardColors.length) | 0]

      L.polyline(ward.boundaries, {
        color: color,
        weight: 1.5,
        opacity: 0.5,
        dashArray: "5, 5",
      }).addTo(map.current!)
    })

    // Add markers with clustering
    const markerClusterGroup = new MarkerClusterGroup({
      maxClusterRadius: 50,
      iconCreateFunction: (cluster) => {
        const count = cluster.getChildCount()
        return L.divIcon({
          html: `<div style="background-color: #3b82f6; color: white; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; cursor: pointer;">${count}</div>`,
          iconSize: [40, 40],
          className: "",
        })
      },
    })

    issues.forEach((issue) => {
      const statusColor = {
        submitted: "#ef4444",
        verified: "#22c55e",
        forwarded: "#3b82f6",
        rejected: "#6b7280",
      }[issue.status]

      const marker = L.circleMarker([issue.latitude, issue.longitude], {
        radius: 6,
        fillColor: statusColor,
        color: "#fff",
        weight: 2,
        opacity: 1,
        fillOpacity: 0.9,
      })

      marker.bindPopup(`
        <div style="font-size: 12px; width: 150px;">
          <strong>${issue.id}</strong><br/>
          ${issue.category}<br/>
          <small>${issue.description.substring(0, 50)}...</small>
        </div>
      `)

      marker.on("click", () => {
        onMarkerClick(issue.id)
      })

      markerClusterGroup.addLayer(marker)
    })

    map.current.addLayer(markerClusterGroup)

    return () => {
      // Cleanup handled by component unmount
    }
  }, [zone, issues, onMarkerClick])

  return (
    <div className="space-y-2">
      <div className="px-6 pt-6 pb-2">
        <h2 className="text-lg font-semibold text-foreground">{zone.name} — Zone Overview</h2>
        <p className="text-sm text-muted-foreground">Wards: {zone.wards.map((w) => w.name).join(", ")}</p>
      </div>
      <div ref={mapContainer} className="h-96 rounded-md mx-6 mb-6" style={{ background: "#f3f4f6" }} />
    </div>
  )
}
