"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { X } from "lucide-react"
import type { Issue } from "@/lib/types"

interface ForwardToWardModalProps {
  issue: Issue
  onClose: () => void
}

export function ForwardToWardModal({ issue, onClose }: ForwardToWardModalProps) {
  const [selectedWard, setSelectedWard] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const wards = ["Ward 12 - East", "Ward 13 - West", "Ward 14 - North", "Ward 15 - South"]

  const handleForward = async () => {
    if (!selectedWard) return
    setIsSubmitting(true)
    await new Promise((resolve) => setTimeout(resolve, 500))
    setIsSubmitting(false)
    onClose()
  }

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm" onClick={onClose} />

      {/* Modal */}
      <div className="fixed left-1/2 top-1/2 z-50 w-full max-w-md -translate-x-1/2 -translate-y-1/2 rounded-lg border border-border bg-card shadow-lg">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold text-foreground">Forward to Ward</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground transition-colors">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Content */}
        <div className="px-6 py-4 space-y-4">
          <div>
            <p className="text-sm text-muted-foreground mb-2">Issue ID</p>
            <p className="text-sm font-medium text-foreground bg-muted/50 rounded px-3 py-2">{issue.id}</p>
          </div>

          <div>
            <label className="text-sm font-medium text-foreground block mb-2">Select Ward</label>
            <select
              value={selectedWard}
              onChange={(e) => setSelectedWard(e.target.value)}
              className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-primary/50"
            >
              <option value="">Choose a ward...</option>
              {wards.map((ward) => (
                <option key={ward} value={ward}>
                  {ward}
                </option>
              ))}
            </select>
          </div>

          <div className="rounded-lg bg-info/10 border border-info/30 p-3">
            <p className="text-xs text-info font-medium">
              This issue will be marked as "Forwarded" and sent to the selected ward for processing.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="flex gap-2 border-t border-border bg-muted/50 px-6 py-3">
          <Button variant="outline" className="flex-1 bg-transparent" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button
            className="flex-1 bg-primary hover:bg-primary/90"
            disabled={!selectedWard || isSubmitting}
            onClick={handleForward}
          >
            {isSubmitting ? "Forwarding..." : "Forward"}
          </Button>
        </div>
      </div>
    </>
  )
}
