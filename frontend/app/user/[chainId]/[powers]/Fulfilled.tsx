'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { UserItem } from './UserItem'
import { Action, Powers } from '@/context/types' 
import { StaticForm } from '@/components/StaticForm'
import { setAction, usePowersStore } from '@/context/store'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { useChecks } from '@/hooks/useChecks'

export default function Fulfilled() {
  const { chainId } = useParams<{ chainId: string }>()
  const powers = usePowersStore();
  const { authenticated } = usePrivy() 
  const [selectedItem, setSelectedItem] = useState<Action | null>(null)
  const [actionData, setActionData] = useState<Action | null>(null)
  const [loadingActionData, setLoadingActionData] = useState(false)
  const [itemsToShow, setItemsToShow] = useState(25)
  const { fetchChecks } = useChecks() 
  console.log("@Fulfilled, powers", powers)

  const allActions = powers.mandates && powers.mandates?.length > 0 ? powers.mandates.flatMap(l => l.actions).filter(a => a?.state === 7) : []
  const displayedItems = allActions.slice(0, itemsToShow)
  const hasMoreItems = allActions.length > itemsToShow

  // Handle show more button click
  const handleShowMore = useCallback(() => {
    setItemsToShow(prev => prev + 25)
  }, [])

  // Handle item click and fetch action data
  const handleItemClick = useCallback(async (action: Action) => {
    setSelectedItem(action)
    setLoadingActionData(true)
    setActionData(null)

    try {
      const allActions = powers.mandates && powers.mandates?.length > 0 ? powers.mandates.flatMap(l => l.actions) : []
      const completeAction = allActions.find(a => a?.actionId === action.actionId)
      if (completeAction) {
        setActionData(completeAction)
        // Set the action in the store so StaticForm can access it
        setAction(completeAction)
      }
    } catch (error) {
      console.error("Error fetching action data:", error)
    } finally {
      setLoadingActionData(false)
    }
  }, [powers])

  // If an item is selected, show the details inline
  if (selectedItem) {
    const mandate = powers.mandates?.find(l => l.index === selectedItem.mandateId)
    
    return (
      <div className="w-full mx-auto pb-12">
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
              {/* Header section with UserItem - matching DynamicForm */}
              {mandate && (
                <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                  <UserItem 
                    powers={powers as Powers}
                    mandate={mandate}
                    chainId={chainId as string}
                    actionId={BigInt(selectedItem.actionId)}
                    showLowerSection={false}
                  />
                </div>
              )}

              {/* Form content */}
              <div className="p-6">
                {loadingActionData ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-slate-500">Loading action data...</div>
                  </div>
                ) : actionData && mandate ? (
                  <StaticForm mandate={mandate} staticDescription={true} onCheck={fetchChecks} />
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

  if (allActions.length === 0) {
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
          </div>
        </div>
        
        {/* Render UserItem components for each fulfilled action */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {displayedItems.map((action, index) => {
            const mandate = powers.mandates?.find(l => l.index === action?.mandateId)
            if (!mandate) return null
            
            return action ? (
              <div 
                key={`${action.actionId}-${action.mandateId}-${index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(action)}
              >
                <UserItem 
                  powers={powers}
                  mandate={mandate}
                  chainId={chainId as string}
                  actionId={BigInt(action.actionId)}
                  showLowerSection={false}
                />
              </div>
            ) : null
          })}
          
          {/* Show more button */}
          {hasMoreItems && (
            <div className="p-4">
              <button
                onClick={handleShowMore}
                className="w-full py-2 px-4 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-300 rounded-md transition-colors"
              >
                Show more (`{allActions.length - itemsToShow} remaining)
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
