'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { PortalItem } from './PortalItem'
import { Law, Powers, LawExecutions, Action } from '@/context/types'
import { useLaw } from '@/hooks/useLaw'
import { readContract } from 'wagmi/actions'
import { lawAbi } from '@/context/abi'
import { wagmiConfig } from '@/context/wagmiConfig'
import { usePowers } from '@/hooks/usePowers'
import { useAction } from '@/hooks/useAction'
import { StaticForm } from '@/components/StaticForm'
import { setAction } from '@/context/store'
import { ArrowLeftIcon, ArrowPathIcon } from '@heroicons/react/24/outline'

type ExecutionWithLaw = {
  law: Law
  execution: bigint
  actionId: bigint
}

export default function Fulfilled({hasRoles, powers: powersProp}: {hasRoles: {role: bigint, since: bigint}[], powers: Powers}) {
  const { chainId } = useParams<{ chainId: string }>()
  const { authenticated } = usePrivy()
  const { fetchPowers, checkLaws, status: statusPowers, fetchLawsAndRoles, fetchExecutedActions, fetchProposals, powers } = usePowers()
  const { fetchActionData } = useAction()
  
  // Use powers from hook if available, otherwise fall back to prop
  const currentPowers = powers || powersProp
  const [executionsWithLaws, setExecutionsWithLaws] = useState<ExecutionWithLaw[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [selectedItem, setSelectedItem] = useState<ExecutionWithLaw | null>(null)
  const [actionData, setActionData] = useState<Action | null>(null)
  const [loadingActionData, setLoadingActionData] = useState(false)
  const [reloading, setReloading] = useState(false)

  console.log("@Fulfilled, powers", currentPowers)

  // Handle reload button click
  const handleReload = useCallback(async () => {
    if (!currentPowers) return
    
    setReloading(true)
    setError(null)
    
    try {
      console.log("@Fulfilled: Starting reload of executed actions")
      // Fetch the latest executed actions
      const updatedPowers = await fetchExecutedActions(currentPowers)
      if (updatedPowers) {
        console.log("@Fulfilled: Successfully reloaded executed actions", {executedActionsCount: updatedPowers.executedActions?.length})
      }
    } catch (error) {
      console.error("Error reloading fulfilled actions:", error)
      setError("Failed to reload fulfilled actions")
    } finally {
      setReloading(false)
    }
  }, [currentPowers, fetchExecutedActions])

  // Handle item click and fetch action data
  const handleItemClick = useCallback(async (executionData: ExecutionWithLaw) => {
    setSelectedItem(executionData)
    setLoadingActionData(true)
    setActionData(null)
    
    try {
      const action = await fetchActionData(executionData.actionId, currentPowers)
      if (action) {
        setActionData(action)
        // Set the action in the store so StaticForm can access it
        setAction(action)
      }
    } catch (error) {
      console.error("Error fetching action data:", error)
      setError("Failed to load action details")
    } finally {
      setLoadingActionData(false)
    }
  }, [fetchActionData, currentPowers])

  // Process executed actions similar to Logs.tsx
  useEffect(() => {
    console.log("@Fulfilled: Processing executed actions", {executedActions: currentPowers?.executedActions?.length, laws: currentPowers?.laws?.length})
    
    if (currentPowers?.executedActions && currentPowers?.laws) {
      const actionArray = currentPowers.executedActions.map((lawActions: LawExecutions, i) => {
        return lawActions.actionsIds.map((actionId, j) => {
          const law = currentPowers.laws?.[i]
          if (law) {
            return {
              law,
              execution: lawActions.executions[j],
              actionId
            }
          }
          return null
        })
      }).flat().filter((item): item is ExecutionWithLaw => item !== null)
      
      // Sort by execution time (most recent first)
      const sortedExecutions = actionArray.sort((a, b) => Number(b.execution) - Number(a.execution))
      console.log("@Fulfilled: Setting executions with laws", {count: sortedExecutions.length})
      setExecutionsWithLaws(sortedExecutions)
    }
  }, [currentPowers?.executedActions, currentPowers?.laws])

  // If an item is selected, show the details inline
  if (selectedItem) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  setSelectedItem(null)
                  setActionData(null)
                }}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to fulfilled actions
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] overflow-y-auto">
            {/* Static Form with Action Data - Matching DynamicForm layout */}
            <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600`}>
              {/* Header section with PortalItem - matching DynamicForm */}
              <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                <PortalItem
                  powers={currentPowers as Powers}
                  law={selectedItem.law}
                  chainId={chainId as string}
                  actionId={selectedItem.actionId}
                  showLowerSection={false}
                />
              </div>

              {/* Form content */}
              <div className="p-6">
                {loadingActionData ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-slate-500">Loading action data...</div>
                  </div>
                ) : actionData ? (
                  <StaticForm law={selectedItem.law} />
                ) : (
                  <div className="text-slate-500 italic">No action data available</div>
                )}
              </div>
            </section>
          </div>
        </div>
      </div>
    )
  }

  if (!authenticated) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              Please connect your wallet to view fulfilled actions
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              Loading fulfilled actions...
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-red-500 italic">
              {error}
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (executionsWithLaws.length === 0) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              No fulfilled actions found for your roles
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full mx-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
              <p className="text-sm text-slate-600">Completed actions and proposals</p>
            </div>
            <button 
              onClick={handleReload}
              disabled={reloading}
              className="p-2 text-slate-500 hover:text-slate-700 transition-colors disabled:opacity-50"
            >
              <ArrowPathIcon className={`w-5 h-5 ${reloading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
        
        {/* Render PortalItem components for each execution */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {reloading ? (
            <div className="p-4">
              <div className="flex items-center justify-center py-8">
                <div className="text-sm text-slate-500">Reloading fulfilled actions...</div>
              </div>
            </div>
          ) : (
            executionsWithLaws.map((executionData, index) => (
              <div 
                key={`${executionData.law.lawAddress}-${executionData.law.index}-${executionData.actionId}-${index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(executionData)}
              >
                <PortalItem
                  powers={currentPowers as Powers}
                  law={executionData.law}
                  chainId={chainId as string}
                  actionId={executionData.actionId}
                  showLowerSection={false}
                />
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
