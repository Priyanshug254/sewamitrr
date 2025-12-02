"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { X, MapPin, Clock, AlertCircle, CheckCircle2, Forward } from "lucide-react"
import type { Issue } from "@/lib/types"

interface IssueDetailsDrawerProps {
  issue: Issue
  onClose: () => void
  onForward: () => void
}

export function IssueDetailsDrawer({ issue, onClose, onForward }: IssueDetailsDrawerProps) {
  const [isVerifying, setIsVerifying] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)

  const statusColor = {
    submitted: "text-red-600",
    verified: "text-green-600",
    forwarded: "text-blue-600",
    rejected: "text-gray-600",
  }

  const statusBgColor = {
    submitted: "bg-red-50",
    verified: "bg-green-50",
    forwarded: "bg-blue-50",
    rejected: "bg-gray-50",
  }

  const formatDate = (date: Date) => {
    return new Date(date).toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm" onClick={onClose} />

      {/* Drawer */}
      <div className="fixed right-0 top-0 z-50 h-full w-full max-w-md overflow-y-auto bg-card shadow-xl flex flex-col">
        {/* Header */}
        <div className="sticky top-0 border-b border-border bg-card px-6 py-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-foreground">Issue Details</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground transition-colors">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-6">
          {/* Issue ID and Status */}
          <div className="space-y-2">
            <p className="text-xs font-semibold text-muted-foreground uppercase">Issue ID</p>
            <p className="text-2xl font-bold text-foreground">{issue.id}</p>
            <Badge
              className={`${statusBgColor[issue.status as keyof typeof statusBgColor]} ${statusColor[issue.status as keyof typeof statusColor]} text-sm`}
            >
              {issue.status.charAt(0).toUpperCase() + issue.status.slice(1)}
            </Badge>
          </div>

          {/* Category and Priority */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <p className="text-xs font-semibold text-muted-foreground uppercase">Category</p>
              <p className="text-sm font-medium text-foreground">{issue.category}</p>
            </div>
            <div className="space-y-2">
              <p className="text-xs font-semibold text-muted-foreground uppercase">Priority</p>
              <Badge
                className={
                  issue.priority === "high"
                    ? "bg-red-100 text-red-800"
                    : issue.priority === "medium"
                      ? "bg-yellow-100 text-yellow-800"
                      : "bg-blue-100 text-blue-800"
                }
              >
                {issue.priority.charAt(0).toUpperCase() + issue.priority.slice(1)}
              </Badge>
            </div>
          </div>

          {/* Description */}
          <div className="space-y-2">
            <p className="text-xs font-semibold text-muted-foreground uppercase">Description</p>
            <p className="text-sm text-foreground leading-relaxed">{issue.description}</p>
          </div>

          {/* Location */}
          <div className="space-y-3 rounded-lg bg-muted/50 p-4">
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4 text-primary" />
              <p className="text-xs font-semibold text-muted-foreground uppercase">Location</p>
            </div>
            <div className="space-y-1 text-sm">
              <p className="text-foreground">
                <strong>Coordinates:</strong> {issue.latitude.toFixed(6)}, {issue.longitude.toFixed(6)}
              </p>
              <p className="text-foreground">
                <strong>Ward:</strong> {issue.ward}
              </p>
            </div>
          </div>

          {/* Timeline */}
          <div className="space-y-3">
            <p className="text-xs font-semibold text-muted-foreground uppercase">Timeline</p>
            <div className="space-y-2">
              <div className="flex gap-3">
                <div className="relative">
                  <div className="h-8 w-8 rounded-full bg-destructive/20 flex items-center justify-center">
                    <AlertCircle className="h-4 w-4 text-destructive" />
                  </div>
                </div>
                <div className="pt-1">
                  <p className="text-sm font-medium text-foreground">Submitted</p>
                  <p className="text-xs text-muted-foreground">{formatDate(issue.reportedAt)}</p>
                </div>
              </div>
              {issue.status !== "submitted" && (
                <div className="flex gap-3">
                  <div className="relative">
                    <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center">
                      <CheckCircle2 className="h-4 w-4 text-primary" />
                    </div>
                  </div>
                  <div className="pt-1">
                    <p className="text-sm font-medium text-foreground">
                      {issue.status === "verified"
                        ? "Verified"
                        : issue.status === "forwarded"
                          ? "Forwarded"
                          : "Rejected"}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {formatDate(new Date(issue.reportedAt.getTime() + 3600000))}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* SLA Countdown */}
          <div className="space-y-2 rounded-lg bg-warning/10 border border-warning/30 p-4">
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 text-warning" />
              <p className="text-xs font-semibold text-warning uppercase">SLA Countdown</p>
            </div>
            <p className="text-sm font-medium text-warning">2 days 14 hours remaining</p>
          </div>

          {/* Photos */}
          <div className="space-y-3">
            <p className="text-xs font-semibold text-muted-foreground uppercase">Photos</p>
            <div className="grid grid-cols-2 gap-2">
              <div className="h-24 rounded-lg bg-muted flex items-center justify-center text-muted-foreground text-xs">
                Photo 1
              </div>
              <div className="h-24 rounded-lg bg-muted flex items-center justify-center text-muted-foreground text-xs">
                Photo 2
              </div>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="sticky bottom-0 border-t border-border bg-card px-6 py-4 space-y-2">
          <Button
            className="w-full bg-success hover:bg-success/90 text-success-foreground"
            disabled={issue.status !== "submitted" || isVerifying}
            onClick={() => setIsVerifying(true)}
          >
            {isVerifying ? "Verifying..." : "Verify Issue"}
          </Button>
          <Button
            className="w-full bg-primary hover:bg-primary/90"
            disabled={issue.status !== "submitted" || isVerifying}
            onClick={onForward}
          >
            <Forward className="h-4 w-4 mr-2" />
            Forward to Ward
          </Button>
          <Button
            variant="destructive"
            className="w-full"
            disabled={issue.status !== "submitted" || isRejecting}
            onClick={() => setIsRejecting(true)}
          >
            {isRejecting ? "Rejecting..." : "Reject Issue"}
          </Button>
        </div>
      </div>
    </>
  )
}
