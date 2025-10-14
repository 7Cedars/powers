'use client'

import React, { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { usePrivy, useWallets } from '@privy-io/react-auth' 
import { usePowers } from '@/hooks/usePowers'
import { PowersOverview } from '@/components/PowersOverview'
import { useParams } from 'next/navigation'
import { LoadingBox } from '@/components/LoadingBox'
import { ProtocolNavigation } from '@/components/ProtocolNavigation'
import { useActionStore } from '@/context/store'

interface FlowLayoutProps {
  children: React.ReactNode
}

export default function FlowLayout({ children }: FlowLayoutProps) {
  const router = useRouter()
  const { ready } = usePrivy()
  const { powers: powersAddress } = useParams<{
    chainId: string
    powers: string
  }>()
  const { wallets } = useWallets()
  const action = useActionStore()
  const {
    powers,
    status: powersStatus,
    error: powersError,
    fetchPowers,
    fetchActions,
    fetchLawsAndRoles
  } = usePowers()

  // console.log("@FlowLayout: ", {wallets, powers, powersAddress})

  // Fetch powers on mount
  useEffect(() => {
    if (powersAddress && !powers) {
      fetchPowers(powersAddress as `0x${string}`)
    }
  }, [powersAddress, powers, fetchPowers ])

  // Show loading while authentication is checking
  if (!ready) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4 fixed inset-0 z-50">
        <div className="text-center">
          <LoadingBox />
          <p className="text-slate-600 mt-4">Loading...</p>
        </div>
      </div>
    )
  }

  // Show loading while powers is being fetched
  if (powersStatus === 'pending' || !powers) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4 fixed inset-0 z-50">
        <div className="text-center">
          <LoadingBox />
          <p className="text-slate-600 mt-4">Loading protocol data...</p>
        </div>
      </div>
    )
  }

  // Only show error after multiple failed attempts and user interaction
  if (powersError && powersStatus === 'error') {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4 fixed inset-0 z-50">
        <div className="max-w-md w-full bg-white rounded-lg shadow-lg border border-slate-200 overflow-hidden">
          {/* Error Header */}
          <div className="px-6 py-4 border-b border-slate-200 bg-slate-50">
            <div className="flex items-center justify-center">
              {/* <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center mb-2">
                <div className="text-red-600 text-2xl">⚠️</div>
              </div> */}
            </div>
            <h1 className="text-lg font-semibold text-red-600 text-center">
              Error Loading Protocol
            </h1>
          </div>
          
          {/* Error Content */}
          <div className="px-6 py-4">
            <p className="text-slate-600 text-center mb-6 leading-relaxed">
              {typeof powersError === 'string' ? powersError : 'Failed to load protocol data'}
            </p>
            
            {/* Action Buttons */}
            <div className="flex flex-col gap-3">
              <button
                onClick={() => {
                  if (powersAddress) {
                    fetchPowers(powersAddress as `0x${string}`)
                  }
                }}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium text-sm"
              >
                Retry
              </button>
              <button
                onClick={() => router.back()}
                className="w-full px-4 py-2 bg-slate-200 text-slate-700 rounded-md hover:bg-slate-300 transition-colors font-medium text-sm"
              >
                Go Back
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-100">
      <ProtocolNavigation>
        <PowersOverview powers={powers} wallets={wallets} fetchLawsAndRoles={fetchLawsAndRoles} fetchActions={fetchActions}>
          {children}
        </PowersOverview>
      </ProtocolNavigation>
    </div>
  )
} 