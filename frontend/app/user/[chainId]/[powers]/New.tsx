'use client'

import React from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth' 
import { UserItem } from './UserItem'
import { Mandate, Powers } from '@/context/types'
import { useActionStore, setAction, useStatusStore, usePowersStore } from '@/context/store'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { MandateBox } from '@/components/MandateBox'
import { MandateDependenciesList } from '@/components/MandateDependenciesList'
import { useChains } from 'wagmi'

export default function New({hasRoles}: {hasRoles: bigint[]}) {
  const { chainId } = useParams<{ chainId: string }>()
  const powers = usePowersStore();
  const { authenticated } = usePrivy()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))

  // const { fetchChecks, status: statusChecks, checks } = useChecks()
  const finalFilteredMandates = powers?.mandates?.filter(mandate => 
    mandate.active && 
    mandate.conditions &&
    mandate.conditions.needFulfilled == 0n &&
    hasRoles.some(role => role === mandate?.conditions?.allowedRole as bigint)
  )
  const status = useStatusStore(); 
  const action = useActionStore();
  const mandate = powers?.mandates?.find(mandate => BigInt(mandate.index) == BigInt(action.mandateId))

    // Get mandates that will be enabled by executing the selected item's mandate
  const enabledMandates = action.actionId && powers?.mandates ? 
    powers.mandates.filter(mandate => 
      mandate.active && 
      mandate.conditions?.needFulfilled == action.mandateId
    ) : []

  // Get mandates that will be blocked by executing the selected item's mandate
  const blockedMandates = action.actionId && powers?.mandates ? 
    powers.mandates.filter(mandate => 
      mandate.active && 
      mandate.conditions?.needNotFulfilled == action.mandateId
    ) : []
  
  // console.log("@New, waypoint 0", {action, mandate, powers, finalFilteredMandates, hasRoles})

  // If a mandate is selected, show the either MandateBox or ProposalBox
  if (mandate) {
    return (
      <div className="w-full mx-auto pb-12">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setAction({...action, mandateId: 0n})}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to mandates
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] ">
            <MandateBox 
              powers={powers as Powers}
              mandate={mandate}
              status={status.status}
              params={mandate.params || []}
            />

             <MandateDependenciesList
              mandates={enabledMandates}
              mode="enables"
              powers={powers as Powers}
              blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
            />

            <MandateDependenciesList
              mandates={blockedMandates}
              mode="blocks"
              powers={powers as Powers}
              blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
            />

          </div>
        </div>
      </div>
    )
  }

  /// Error messages /// 

  if (!authenticated || (finalFilteredMandates && finalFilteredMandates.length === 0)) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">New</h2>
            <p className="text-sm text-slate-600">New proposals and actions</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              {!authenticated ? "Please connect your wallet to view available mandates" : "No new mandates available for your roles"} 
            </p>
          </div>
        </div>
      </div>
    )
  }

  ///  List of mandates for the selected roles /// 
  return (
    <div className="w-full mx-auto pb-12">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-800">New</h2>
              <p className="text-sm text-slate-600">Available mandates for your roles</p>
            </div>
          </div>
        </div>
        
        {/* Render UserItem components for each filtered mandate */}
        <div className="max-h-[calc(100vh-200px)] divide-y divide-slate-200">
          {status.status === "pending" ? (
            <div className="p-4">
              <div className="flex items-center justify-center py-8">
                <div className="text-sm text-slate-500">Loading mandates...</div>
              </div>
            </div>
          ) : (
            finalFilteredMandates && finalFilteredMandates.map((mandate: Mandate) => (
              <div 
                key={`${mandate.mandateAddress}-${mandate.index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => {
                  setAction({...action, mandateId: mandate.index, upToDate: false})  
                  }
                }
              >
                <UserItem 
                  powers={powers}
                  mandate={mandate}
                  chainId={chainId as string}
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
