"use client"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Eye } from "lucide-react"
import type { Issue } from "@/lib/types"

interface IssuesTableProps {
  issues: Issue[]
  selectedIssueId: string | null
  onSelectIssue: (id: string) => void
}

export function IssuesTable({ issues, selectedIssueId, onSelectIssue }: IssuesTableProps) {
  const statusBadgeVariant = (status: string) => {
    switch (status) {
      case "submitted":
        return "bg-red-100 text-red-800"
      case "verified":
        return "bg-green-100 text-green-800"
      case "forwarded":
        return "bg-blue-100 text-blue-800"
      case "rejected":
        return "bg-gray-100 text-gray-800"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  const priorityColor = (priority: string) => {
    switch (priority) {
      case "high":
        return "bg-red-100 text-red-800"
      case "medium":
        return "bg-yellow-100 text-yellow-800"
      case "low":
        return "bg-blue-100 text-blue-800"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  const formatDate = (date: Date) => {
    return new Date(date).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border bg-muted/50">
            <th className="px-6 py-3 text-left font-semibold text-foreground">Issue ID</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Category</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Description</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Priority</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Status</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Location</th>
            <th className="px-6 py-3 text-left font-semibold text-foreground">Reported</th>
            <th className="px-6 py-3 text-right font-semibold text-foreground">Actions</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) => (
            <tr
              key={issue.id}
              className={`border-b border-border transition-colors hover:bg-muted/50 ${
                selectedIssueId === issue.id ? "bg-secondary/50" : ""
              }`}
            >
              <td className="px-6 py-3">
                <span className="font-medium text-foreground">{issue.id}</span>
              </td>
              <td className="px-6 py-3">
                <span className="text-foreground">{issue.category}</span>
              </td>
              <td className="px-6 py-3">
                <span className="text-muted-foreground truncate max-w-xs">{issue.description}</span>
              </td>
              <td className="px-6 py-3">
                <Badge className={`${priorityColor(issue.priority)} text-xs`}>{issue.priority}</Badge>
              </td>
              <td className="px-6 py-3">
                <Badge className={`${statusBadgeVariant(issue.status)} text-xs`}>
                  {issue.status.charAt(0).toUpperCase() + issue.status.slice(1)}
                </Badge>
              </td>
              <td className="px-6 py-3">
                <span className="text-muted-foreground text-xs">
                  {issue.latitude.toFixed(4)}, {issue.longitude.toFixed(4)}
                </span>
              </td>
              <td className="px-6 py-3">
                <span className="text-muted-foreground text-xs">{formatDate(issue.reportedAt)}</span>
              </td>
              <td className="px-6 py-3 text-right">
                <Button variant="ghost" size="sm" onClick={() => onSelectIssue(issue.id)} className="h-8 w-8 p-0">
                  <Eye className="h-4 w-4" />
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {issues.length === 0 && <div className="text-center py-12 text-muted-foreground">No issues found.</div>}
    </div>
  )
}
