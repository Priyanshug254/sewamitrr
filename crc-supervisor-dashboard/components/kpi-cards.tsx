"use client"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts"
import { AlertCircle, CheckCircle2, Forward, XCircle } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { Zone, Issue } from "@/lib/types"

interface KPICardsProps {
  zone: Zone
  issues: Issue[]
}

export function KPICards({ zone, issues }: KPICardsProps) {
  const unverified = issues.filter((i) => i.status === "submitted").length
  const forwarded = issues.filter((i) => i.status === "forwarded").length
  const rejected = issues.filter((i) => i.status === "rejected").length

  const sparklineData = [
    { name: "Mon", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Tue", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Wed", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Thu", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Fri", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Sat", value: Math.floor(Math.random() * 20) + 10 },
    { name: "Sun", value: Math.floor(Math.random() * 20) + 10 },
  ]

  const kpiData = [
    {
      title: "Total Issues",
      value: issues.length,
      icon: AlertCircle,
      color: "text-info",
      bgColor: "bg-info/10",
      data: sparklineData,
    },
    {
      title: "Unverified Issues",
      value: unverified,
      icon: CheckCircle2,
      color: "text-warning",
      bgColor: "bg-warning/10",
      data: sparklineData,
    },
    {
      title: "Forwarded to Ward",
      value: forwarded,
      icon: Forward,
      color: "text-success",
      bgColor: "bg-success/10",
      data: sparklineData,
    },
    {
      title: "Rejected",
      value: rejected,
      icon: XCircle,
      color: "text-destructive",
      bgColor: "bg-destructive/10",
      data: sparklineData,
    },
  ]

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {kpiData.map((kpi, idx) => {
        const Icon = kpi.icon
        return (
          <Card key={idx} className="shadow-sm border-border/50">
            <CardHeader className="flex flex-row items-start justify-between space-y-0 pb-3">
              <CardTitle className="text-sm font-medium text-muted-foreground">{kpi.title}</CardTitle>
              <div className={`${kpi.bgColor} rounded-lg p-2`}>
                <Icon className={`${kpi.color} h-4 w-4`} />
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="text-3xl font-bold text-foreground">{kpi.value}</div>
              <ResponsiveContainer width="100%" height={40}>
                <BarChart data={kpi.data} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="transparent" />
                  <XAxis dataKey="name" hide={true} />
                  <YAxis hide={true} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "var(--color-card)",
                      border: "1px solid var(--color-border)",
                      borderRadius: "0.5rem",
                    }}
                    cursor={false}
                  />
                  <Bar dataKey="value" fill={`var(--color-${kpi.color.split("-")[1]})`} radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}
