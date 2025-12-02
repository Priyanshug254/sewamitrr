"use client"
import { Search, Bell, Settings } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

interface HeaderProps {
  onSearch: (query: string) => void
}

export function Header({ onSearch }: HeaderProps) {
  return (
    <header className="sticky top-0 z-40 border-b border-border bg-card shadow-sm">
      <div className="flex items-center justify-between gap-4 px-6 py-4">
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground font-bold text-sm">
            S
          </div>
          <h1 className="text-xl font-bold text-foreground">CRC Dashboard — Zone Overview</h1>
        </div>

        <div className="flex items-center gap-4 flex-1 max-w-md">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search issues..."
              className="pl-10 h-9 text-sm"
              onChange={(e) => onSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" className="h-9 w-9">
            <Bell className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon" className="h-9 w-9">
            <Settings className="h-4 w-4" />
          </Button>
          <div className="flex items-center gap-2 ml-2 pl-2 border-l border-border">
            <div className="h-8 w-8 rounded-full bg-accent"></div>
            <span className="text-sm font-medium text-foreground">CRC Lead</span>
          </div>
        </div>
      </div>
    </header>
  )
}
