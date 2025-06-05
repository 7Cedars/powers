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

  // Re-fetch checks for specific law when action changes
  useEffect(() => {
    if (action.lawId && action.lawId !== 0n && powers && wallets.length > 0) {
      const refetchConnectedChecks = async () => {
        // Find all connected nodes in the dependency chain
        const selectedLawId = String(action.lawId)
        let connectedNodes: Set<string> = new Set()
        
        if (powers.activeLaws) {
          // Build dependency maps
          const dependencies = new Map<string, Set<string>>()
          const dependents = new Map<string, Set<string>>()
          
          powers.activeLaws.forEach(law => {
            const lawId = String(law.index)
            dependencies.set(lawId, new Set())
            dependents.set(lawId, new Set())
          })
          
          // Populate dependency relationships
          powers.activeLaws.forEach(law => {
            const lawId = String(law.index)
            if (law.conditions) {
              if (law.conditions.needCompleted !== 0n) {
                const targetId = String(law.conditions.needCompleted)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
              if (law.conditions.needNotCompleted !== 0n) {
                const targetId = String(law.conditions.needNotCompleted)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
              if (law.conditions.readStateFrom !== 0n) {
                const targetId = String(law.conditions.readStateFrom)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
            }
          })
          
          // Find all connected nodes using traversal
          const visited = new Set<string>()
          const traverse = (nodeId: string) => {
            if (visited.has(nodeId)) return
            visited.add(nodeId)
            connectedNodes.add(nodeId)
            
            // Add all dependencies
            const deps = dependencies.get(nodeId) || new Set()
            deps.forEach(depId => traverse(depId))
            
            // Add all dependents  
            const dependentNodes = dependents.get(nodeId) || new Set()
            dependentNodes.forEach(depId => traverse(depId))
          }
          
          traverse(selectedLawId)
        }
        
        // Update checks for all connected laws
        for (const lawIdStr of connectedNodes) {
          const targetLaw = powers.activeLaws?.find(law => law.index === BigInt(lawIdStr))
          if (targetLaw) {
            try {
              // Use current action's calldata and nonce for all connected laws
              const checks = await fetchChecks(
                targetLaw,
                action.callData,
                BigInt(action.nonce),
                wallets,
                powers
              )
              if (checks) {
                // Update this law's checks in the map
                setChainChecks(prevChecks => {
                  const newChecks = new Map(prevChecks)
                  newChecks.set(lawIdStr, checks)
                  return newChecks
                })
              }
            } catch (error) {
              console.warn(`Failed to re-fetch checks for connected law ${lawIdStr}:`, error)
            }
          }
        }
        
        console.log(`Updated checks for ${connectedNodes.size} connected laws: ${Array.from(connectedNodes).join(', ')}`)
      }
      
      refetchConnectedChecks()
    }
  }, [action.lawId, action.callData, action.nonce, action.upToDate, powers, wallets, fetchChecks, setChainChecks])

  // Re-fetch all checks when usePowers status changes to 'success'
  useEffect(() => {
    if (powersStatus === 'success' && powers && wallets.length > 0) {
      const refreshAllChecks = async () => {
        const checksMap = new Map<string, Checks>()
        
        // Find all connected nodes if there's a selected law
        let connectedNodes: Set<string> = new Set()
        const hasSelectedAction = action.lawId && action.lawId !== 0n
        
        if (hasSelectedAction && powers.activeLaws) {
          // Use the same logic as PowersFlow to find connected nodes
          const selectedLawId = String(action.lawId)
          
          // Build dependency maps
          const dependencies = new Map<string, Set<string>>()
          const dependents = new Map<string, Set<string>>()
          
          powers.activeLaws.forEach(law => {
            const lawId = String(law.index)
            dependencies.set(lawId, new Set())
            dependents.set(lawId, new Set())
          })
          
          // Populate dependency relationships
          powers.activeLaws.forEach(law => {
            const lawId = String(law.index)
            if (law.conditions) {
              if (law.conditions.needCompleted !== 0n) {
                const targetId = String(law.conditions.needCompleted)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
              if (law.conditions.needNotCompleted !== 0n) {
                const targetId = String(law.conditions.needNotCompleted)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
              if (law.conditions.readStateFrom !== 0n) {
                const targetId = String(law.conditions.readStateFrom)
                if (dependencies.has(targetId)) {
                  dependencies.get(lawId)?.add(targetId)
                  dependents.get(targetId)?.add(lawId)
                }
              }
            }
          })
          
          // Find all connected nodes using traversal
          const visited = new Set<string>()
          const traverse = (nodeId: string) => {
            if (visited.has(nodeId)) return
            visited.add(nodeId)
            connectedNodes.add(nodeId)
            
            // Add all dependencies
            const deps = dependencies.get(nodeId) || new Set()
            deps.forEach(depId => traverse(depId))
            
            // Add all dependents  
            const dependentNodes = dependents.get(nodeId) || new Set()
            dependentNodes.forEach(depId => traverse(depId))
          }
          
          traverse(selectedLawId)
        }
        
        // Determine which laws to fetch checks for
        const lawsToFetch = hasSelectedAction 
          ? powers.activeLaws?.filter(law => connectedNodes.has(String(law.index))) || []
          : powers.activeLaws || []
        
        // Fetch checks for the determined laws
        for (const activeLaw of lawsToFetch) {
          try {
            // Use current action data if this law is in the connected dependency chain
            const useActionData = connectedNodes.has(String(activeLaw.index))
            const checks = await fetchChecks(
              activeLaw, 
              useActionData ? action.callData : '0x0' as `0x${string}`, 
              useActionData ? BigInt(action.nonce) : 0n, 
              wallets, 
              powers
            )
            if (checks) {
              checksMap.set(String(activeLaw.index), checks)
            }
          } catch (error) {
            console.warn(`Failed to refresh checks for law ${activeLaw.index}:`, error)
          }
        }
        
        // Update chainChecks with the refreshed map (preserving existing checks for non-fetched laws)
        setChainChecks(prevChecks => {
          const newChecks = new Map(prevChecks)
          checksMap.forEach((checks, lawId) => {
            newChecks.set(lawId, checks)
          })
          return newChecks
        })
        
        if (hasSelectedAction) {
          console.log(`Refreshed checks for ${connectedNodes.size} connected laws: ${Array.from(connectedNodes).join(', ')}`)
        } else {
          console.log(`Refreshed checks for all ${lawsToFetch.length} laws`)
        }
      }
      
      refreshAllChecks()
    }
  }, [powersStatus, powers, wallets, action.lawId, action.callData, action.nonce, fetchChecks, setChainChecks])

  // Show loading while authentication is checking
  if (!ready) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
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