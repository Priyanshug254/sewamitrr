"use client"

import { useState } from "react"
import { Header } from "@/components/header"
import { KPICards } from "@/components/kpi-cards"
import { ZoneMap } from "@/components/zone-map"
import { IssuesTable } from "@/components/issues-table"
import { IssueDetailsDrawer } from "@/components/issue-details-drawer"
import { ForwardToWardModal } from "@/components/forward-to-ward-modal"
import { dummyIssues, dummyZones } from "@/lib/dummy-data"

export default function CRCDashboard() {
  const [selectedIssueId, setSelectedIssueId] = useState<string | null>(null)
  const [showForwardModal, setShowForwardModal] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")

  const currentZone = dummyZones[0]
  const filteredIssues = dummyIssues.filter(
    (issue) =>
      issue.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      issue.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      issue.category.toLowerCase().includes(searchQuery.toLowerCase()),
  )

  const selectedIssue = filteredIssues.find((i) => i.id === selectedIssueId)

  return (
    <div className="min-h-screen bg-background">
      <Header onSearch={setSearchQuery} />
      <main className="flex flex-col gap-6 p-6">
        <KPICards zone={currentZone} issues={filteredIssues} />
        <div className="rounded-lg border border-border bg-card shadow-sm">
          <ZoneMap zone={currentZone} issues={filteredIssues} onMarkerClick={setSelectedIssueId} />
        </div>
        <div className="rounded-lg border border-border bg-card shadow-sm">
          <IssuesTable issues={filteredIssues} selectedIssueId={selectedIssueId} onSelectIssue={setSelectedIssueId} />
        </div>
      </main>

      {selectedIssue && (
        <IssueDetailsDrawer
          issue={selectedIssue}
          onClose={() => setSelectedIssueId(null)}
          onForward={() => setShowForwardModal(true)}
        />
      )}

      {showForwardModal && selectedIssue && (
        <ForwardToWardModal issue={selectedIssue} onClose={() => setShowForwardModal(false)} />
      )}
    </div>
  )
}
