'use client'

import React from 'react'
import { UserNavigation } from '@/app/user/UserNavigation'

interface UserLayoutProps {
  children: React.ReactNode
}

export default function UserLayout({ children }: UserLayoutProps) {
  return (
    <div className="min-h-screen bg-slate-100">
      <UserNavigation>
        {children}
      </UserNavigation>
    </div>
  )
}
