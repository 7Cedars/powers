'use client'

import React from 'react'
import { PortalNavigation } from '@/components/PortalNavigation'

interface PortalLayoutProps {
  children: React.ReactNode
}

export default function PortalLayout({ children }: PortalLayoutProps) {
  return (
    <div className="min-h-screen bg-slate-100">
      <PortalNavigation>
        {children}
      </PortalNavigation>
    </div>
  )
}
