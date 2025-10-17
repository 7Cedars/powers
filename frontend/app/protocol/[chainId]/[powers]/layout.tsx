'use client'

import React from 'react' 
import { ProtocolNavigation } from '@/app/protocol/[chainId]/[powers]/ProtocolNavigation'

interface ProtocolLayoutProps {
  children: React.ReactNode
}

export default function ProtocolLayout({ children }: ProtocolLayoutProps) {
  return (
    <div className="min-h-screen bg-slate-100">
      <ProtocolNavigation>
        {children}
      </ProtocolNavigation>
    </div>
  )
} 

     