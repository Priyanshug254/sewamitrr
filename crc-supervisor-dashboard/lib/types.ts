export interface Ward {
  id: string
  name: string
  boundaries: [number, number][]
}

export interface Zone {
  id: string
  name: string
  centerLat: number
  centerLng: number
  wards: Ward[]
  boundaries: [number, number][]
}

export interface Issue {
  id: string
  category: string
  description: string
  priority: "high" | "medium" | "low"
  status: "submitted" | "verified" | "forwarded" | "rejected"
  latitude: number
  longitude: number
  ward: string
  reportedAt: Date
  photos: string[]
}
