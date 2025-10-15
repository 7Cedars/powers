'use client'

import React, { useEffect } from 'react'
import { usePowers } from '@/hooks/usePowers'
import { PowersOverview } from '@/components/PowersOverview'
import { useParams } from 'next/navigation'
import { LoadingBox } from '@/components/LoadingBox'
import { ProtocolNavigation } from '@/components/ProtocolNavigation'

interface ProtocolLayoutProps {
  children: React.ReactNode
}

export default function ProtocolLayout({ children }: ProtocolLayoutProps) {

  return (
    <div className="min-h-screen bg-slate-100">
      <ProtocolNavigation>
        <PowersOverview >
          {children}
        </PowersOverview>
      </ProtocolNavigation>
    </div>
  )
} 