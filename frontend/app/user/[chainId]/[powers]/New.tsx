'use client'

import React from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth' 
import { UserItem } from './UserItem'
import { Law, Powers } from '@/context/types'
import { useActionStore, setAction, useStatusStore, usePowersStore } from '@/context/store'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { LawBox } from '@/components/LawBox'

export default function New({hasRoles}: {hasRoles: bigint[]}) {
  const { chainId } = useParams<{ chainId: string }>()
  const powers = usePowersStore();
  const { authenticated } = usePrivy()

  // const { fetchChecks, status: statusChecks, checks } = useChecks()
  const finalFilteredLaws = powers?.laws?.filter(law => 
    law.active && 
    law.conditions &&
    law.conditions.needFulfilled == 0n &&
    hasRoles.some(role => role === law?.conditions?.allowedRole as bigint)
  )
  const status = useStatusStore(); 
  const action = useActionStore();
  const law = powers?.laws?.find(law => BigInt(law.index) == BigInt(action.lawId))
  
  console.log("@New, waypoint 0", {action, law, powers, finalFilteredLaws, hasRoles})

  // If a law is selected, show the either LawBox or ProposalBox
  if (law) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setAction({...action, lawId: 0n})}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to laws
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] ">
            <LawBox 
              powers={powers as Powers}
              law={law}
              status={status.status}
              params={law.params || []}
            />

          </div>
        </div>
      </div>
    )
  }

  /// Error messages /// 

  if (!authenticated || (finalFilteredLaws && finalFilteredLaws.length === 0)) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">New</h2>
            <p className="text-sm text-slate-600">New proposals and actions</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              {!authenticated ? "Please connect your wallet to view available laws" : "No new laws available for your roles"} 
            </p>
          </div>
        </div>
      </div>
    )
  }

  ///  List of laws for the selected roles /// 
  return (
    <div className="w-full mx-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-800">New</h2>
              <p className="text-sm text-slate-600">Available laws for your roles</p>
            </div>
          </div>
        </div>
        
        {/* Render UserItem components for each filtered law */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {status.status === "pending" ? (
            <div className="p-4">
              <div className="flex items-center justify-center py-8">
                <div className="text-sm text-slate-500">Loading laws...</div>
              </div>
            </div>
          ) : (
            finalFilteredLaws && finalFilteredLaws.map((law: Law) => (
              <div 
                key={`${law.lawAddress}-${law.index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => {
                  setAction({...action, lawId: law.index, upToDate: false})  
                  }
                }
              >
                <UserItem 
                  powers={powers}
                  law={law}
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
