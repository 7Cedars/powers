'use client'

import React, { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { usePrivy, useWallets } from '@privy-io/react-auth' 
import { usePowers } from '@/hooks/usePowers'
import { PowersOverview } from '@/components/PowersOverview'
import { useParams } from 'next/navigation'
import { LoadingBox } from '@/components/LoadingBox'
import { Law, Powers, Checks } from '@/context/types'
import { useChecks } from '@/hooks/useChecks'
import { useActionStore } from '@/context/store'

interface FlowLayoutProps {
  children: React.ReactNode
}

export default function FlowLayout({ children }: FlowLayoutProps) {
  const router = useRouter()
  const action = useActionStore()
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
  const law = powers?.laws?.find(law => law.index == BigInt(action.lawId))

  const { 
    chainChecks,
    fetchChecks,
    setChainChecks,
    status: checksStatus,
    error: checksError
  } = useChecks(powers as Powers)

  // console.log("@FlowLayout: ", {chainChecks, checksStatus, checksError, law, action, wallets, powers, powersAddress})

  // Fetch powers on mount
  useEffect(() => {
    if (powersAddress && !powers) {
      fetchPowers(powersAddress as `0x${string}`)
    }
  }, [powersAddress, powers, fetchPowers])

  // Fetch checks for all laws when powers is loaded
  useEffect(() => {
    if (powers && wallets.length > 0) {
      const fetchAllChecks = async () => {
        const checksMap = new Map<string, Checks>()
        
        // Fetch checks for all active laws
        if (powers.activeLaws) {
          for (const activeLaw of powers.activeLaws) {
            try {
              // Use default calldata and nonce for general checks
              const checks = await fetchChecks(
                activeLaw, 
                '0x0' as `0x${string}`, 
                0n, 
                wallets, 
                powers
              )
              if (checks) {
                checksMap.set(String(activeLaw.index), checks)
              }
            } catch (error) {
              console.warn(`Failed to fetch checks for law ${activeLaw.index}:`, error)
            }
          }
        }
        
        // Update chainChecks with the new map
        setChainChecks(checksMap)
      }
      
      fetchAllChecks()
    }
  }, [powers, wallets, fetchChecks, setChainChecks])

  // Handle authentication
useEffect(() => {
    if (ready && !authenticated) {
      router.push('/')
    }
  }, [ready, authenticated, router])

  // Show loading while authentication is checking
  if (!ready) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="text-center">
          <LoadingBox />
          <p className="text-slate-600 mt-4">Checking authentication...</p>
        </div>
      </div>
    )
  }

  // Redirect if not authenticated
  if (!authenticated) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="text-center">
          <LoadingBox />
          <p className="text-slate-600 mt-4">Redirecting...</p>
        </div>
      </div>
    )
  }

  // Show loading while powers is being fetched
  if (powersStatus === 'pending' || !powers) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
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
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
          <div className="text-center">
            <div className="text-red-500 text-6xl mb-4">⚠️</div>
            <h1 className="text-xl font-semibold text-gray-900 mb-2">
              Error Loading Protocol
            </h1>
            <p className="text-gray-600 mb-4">
              {typeof powersError === 'string' ? powersError : 'Failed to load protocol data'}
            </p>
            <div className="flex gap-2 justify-center">
              <button
                onClick={() => {
                  if (powersAddress) {
                    fetchPowers(powersAddress as `0x${string}`)
                  }
                }}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Retry
              </button>
              <button
                onClick={() => router.back()}
                className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
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
      <PowersOverview powers={powers} wallets={wallets} chainChecks={chainChecks}>
        {children}
      </PowersOverview>
    </div>
  )
} 