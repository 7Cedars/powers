'use client'

import React from 'react'
import { useRouter } from 'next/navigation'
import { usePrivy, useWallets } from '@privy-io/react-auth' 
import { usePowers } from '@/hooks/usePowers'
import { PowersOverview } from '@/components/PowersOverview'
import { useParams } from 'next/navigation'
import { LoadingBox } from '@/components/LoadingBox'

export default function FlowPage() {
  const router = useRouter()
  const { ready, authenticated } = usePrivy()
  const { wallets } = useWallets()
  const { chainId, powers: powersAddress } = useParams<{
    chainId: string
    powers: string
  }>()

  const {
    powers,
    status: powersStatus,
    error: powersError,
    fetchPowers
  } = usePowers()

  // Fetch powers on mount
  React.useEffect(() => {
    if (powersAddress && !powers) {
      fetchPowers(powersAddress as `0x${string}`)
    }
  }, [powersAddress, powers, fetchPowers])

  // Handle authentication
  React.useEffect(() => {
    if (ready && !authenticated) {
      router.push('/')
    }
  }, [ready, authenticated, router])

  if (!ready || !authenticated) {
    return <LoadingBox />
  }

  if (powersStatus === 'pending') {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <LoadingBox />
      </div>
    )
  }

  if (powersError) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
          <div className="text-center">
            <div className="text-red-500 text-6xl mb-4">⚠️</div>
            <h1 className="text-xl font-semibold text-gray-900 mb-2">
              Error Loading Protocol
            </h1>
            <p className="text-gray-600 mb-4">
              {powersError}
            </p>
            <button
              onClick={() => router.back()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Go Back
            </button>
          </div>
        </div>
      </div>
    )
  }

  if (!powers) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
          <div className="text-center">
            <div className="text-gray-400 text-6xl mb-4">🏛️</div>
            <h1 className="text-xl font-semibold text-gray-900 mb-2">
              Protocol Not Found
            </h1>
            <p className="text-gray-600 mb-4">
              Could not find Powers protocol at address {powersAddress}
            </p>
            <button
              onClick={() => router.back()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Go Back
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <PowersOverview powers={powers} wallets={wallets} />
    </div>
  )
} 