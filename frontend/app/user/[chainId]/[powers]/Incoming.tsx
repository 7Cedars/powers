'use client'

import React, { useState, useMemo, useCallback } from 'react'
import { Powers, Action, Law, Checks } from '@/context/types'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { UserItem } from './UserItem'
import { useParams } from 'next/navigation'
import { ProposalBox } from '@/components/ProposalBox'
import { Voting } from '@/components/Voting'
import { useChecks } from '@/hooks/useChecks'
import { setAction, usePowersStore, useActionStore } from '@/context/store'
import { useChains } from 'wagmi'
import { ConnectedWallet, useWallets } from '@privy-io/react-auth'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'
import { hashAction } from '@/utils/hashAction'
import { StaticForm } from '@/components/StaticForm'
import HeaderLaw from '@/components/HeaderLaw'
import { Button } from '@/components/Button'
import { DynamicActionButton } from '@/components/DynamicActionButton'


const getIncomingActions = ( 
  powers: Powers, 
  hasRoles: bigint[]
): Action[] => {
  console.log("Waypoint 0: getIncomingActions called")
  const incomingActions: Action[] = []
  
  // Step 1: get the user roles and laws 
  const allActionIds = powers.laws?.flatMap(l => l.actions?.map(a => a?.actionId as unknown as bigint)) || []
  const userLaws = powers.laws?.filter(law => 
    law.active && law.conditions && hasRoles.some(role => role === law.conditions?.allowedRole as bigint)
  )
  console.log("Waypoint 1: ", {allActionIds, hasRoles, userLaws, powers})

  // early return if the user has no laws
  if (!userLaws || !userLaws.flatMap(l => l.actions)) {
    return []
  }

  // step 2: get the proposed actions for the user
  const proposedActions = userLaws?.flatMap(l => l.actions).filter(a => a?.state === 1 || a?.state === 3 || a?.state === 5) as Action[]
  console.log("Waypoint 2: ", {proposedActions})

  // get the enabled actions for the user
  const parentLaws = userLaws?.map(law => {
    if (law.conditions?.needFulfilled) { 
      return powers?.laws?.find(l => l.index == law.conditions?.needFulfilled)
    }
    return null
  }).filter(law => law !== null) as Law[] 
  console.log("waypoint 3: ", {parentLaws})

  for (const parentLaw of parentLaws) {
    const fulfilledParentActions = parentLaw.actions?.filter(a => a?.state === 7 || (a?.fulfilledAt && a?.fulfilledAt > 0n)) as Action[]

    fulfilledParentActions?.forEach(action => {
      const actionId = hashAction(
        parentLaw.conditions?.needFulfilled as bigint,
        action.callData as `0x${string}`,
        BigInt(action.nonce as string)
      )
      const isNotActionId = !allActionIds.includes(actionId as unknown as bigint)
      console.log("waypoint 4: ", {actionId, isNotActionId, allActionIds})

      if (isNotActionId) {
        incomingActions.push({
          actionId: actionId.toString(),
          lawId: parentLaw.index,
          caller: action.caller,
          dataTypes: action.dataTypes,
          paramValues: action.paramValues,
          nonce: action.nonce,
          description: action.description,
        })
      }
    })
  }

  return [...proposedActions, ...incomingActions]
}

export default function Incoming({hasRoles}: {hasRoles: bigint[]}) {
  const { chainId } = useParams<{ chainId: string }>()
  const { fetchChecks, status: statusChecks } = useChecks()
  const chains = useChains()
  const powers = usePowersStore();
  const action = useActionStore();
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))

  // State for selected proposal/action 
  const [dynamicDescription, setDynamicDescription] = useState<string>('')
  const incomingActions = getIncomingActions(powers, hasRoles)

  console.log("@Incoming, waypoint 0", {incomingActions})

  // Get laws that will be enabled by executing the selected item's law
  const enabledLaws = action.actionId && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needFulfilled == action.lawId
    ) : []

  // Get laws that will be blocked by executing the selected item's law
  const blockedLaws = action.actionId && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needNotFulfilled == action.lawId
    ) : []

  // Handle item click for static form view (enabled actions or succeeded proposals)
  const handleItemClick = (action: Action) => {
    try {
      // Fetch complete action data
      const completeAction = powers.laws?.flatMap(l => l.actions).find(a => a?.actionId === action.actionId)
      if (completeAction) {
        setAction(completeAction as Action)
        setDynamicDescription(completeAction.description || '')
      }
    } catch (error) {
      console.error("Error fetching action data:", error)
    }
  }

  // Wrapper for fetchChecks to match the expected signature
  const handleCheck = async (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => {
    if (action && action.callData && action.nonce && wallets.length > 0) {
      await fetchChecks(
        law,
        action.callData as `0x${string}`,
        BigInt(action.nonce),
        wallets,
        powers
      )
    }
  }

  // If an item is selected for static form view (enabled action or succeeded proposal)
  if (action.actionId) {
    const law = powers.laws?.find(law => law.index === BigInt(action.lawId)) as Law
    
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  setAction({
                    actionId: '',
                    lawId: 0n,
                    caller: '0x0',
                    dataTypes: [],
                    paramValues: [],
                    nonce: '0',
                    description: '', 
                    upToDate: false,
                  })
                }}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to incoming proposals
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] overflow-y-auto">
            {/* Static Form with Action Data - Matching DynamicForm layout */}
            <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600`}>
              {/* Header section with UserItem - matching DynamicForm */}
              <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                <UserItem 
                  powers={powers as Powers}
                  law={law}
                  chainId={chainId as string}
                  actionId={BigInt(action.actionId)}
                  showLowerSection={false}
                  isEnabledAction={incomingActions.some(enabled => enabled?.actionId === action.actionId)}
                />
              </div>

              {/* Form content */}
              <div className="p-6">
                {action.callData ? (
                  <>
                    <StaticForm 
                      law={law} 
                      staticDescription={!incomingActions.some(enabled => enabled?.actionId === action.actionId)}
                    />
                    
                    {/* Dynamic reason box for enabled actions */}
                    {incomingActions.some(incoming => incoming?.actionId === action.actionId) && (
                      <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3 min-h-24">
                        <label htmlFor="dynamicReason" className="text-xs text-slate-600 ps-3 min-w-28 pt-1">Description</label>
                        <div className="w-full flex items-center rounded-md outline outline-1 outline-slate-300">
                          <textarea 
                            name="dynamicReason" 
                            id="dynamicReason" 
                            rows={5} 
                            cols={25} 
                            value={dynamicDescription}
                            onChange={(e) => setDynamicDescription(e.target.value)}
                            className="w-full py-1.5 ps-2 pe-3 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
                            placeholder="Enter your description for this action here."
                          />
                        </div>
                      </div>
                    )}
                  </>
                ) : (
                  <div className="text-slate-500 italic">No action data available</div>
                )}
              </div>


              {action.callData && (
                <>
                  {/* Check button */}
                  <div className="w-full px-6 py-2">
                    <Button 
                      size={0} 
                      role={6}
                      onClick={() => {
                        if (action.callData) {
                          handleCheck(law, action, [], powers)
                        }
                      }}
                      filled={false}
                      selected={true}
                      statusButton={
                        // For enabled actions, check if we have action data and description
                        incomingActions.some(enabled => enabled?.actionId === action.actionId) 
                          ? (action.callData && dynamicDescription && dynamicDescription.length > 0 ? statusChecks : 'disabled')
                          : statusChecks
                      }
                    >
                      Check
                    </Button>
                  </div>

                  <DynamicActionButton checks={statusChecks as Checks} /> 
                </>
              )}
            </section>
            

            {enabledLaws.length > 0 && (
              <div className="mt-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Execution <b>enables</b> the following laws: </h3>
                <div className="space-y-2">
                  {enabledLaws.map((law: Law) => (
                    <div 
                      key={`enabled-${law.lawAddress}-${law.index}`}
                      className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
                    >
                      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                        <HeaderLaw
                          powers={powers as Powers}
                          lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
                          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
                          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
                          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
                          contractAddress={law.lawAddress}
                          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            
  
            {blockedLaws.length > 0 && (
              <div className="mt-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Execution <b>blocks</b> the following laws: </h3>
                <div className="space-y-2">
                  {blockedLaws.map((law: Law) => (
                    <div 
                      key={`blocked-${law.lawAddress}-${law.index}`}
                      className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
                    >
                      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                        <HeaderLaw
                          powers={powers as Powers}
                          lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
                          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
                          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
                          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
                          contractAddress={law.lawAddress}
                          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  // If a proposal is selected, show the unified item view
  if (action.actionId) {
    // const law = powers.laws?.find(law => law.index === BigInt(selectedProposal.lawId)) as Law
    
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setAction({
                  actionId: '',
                  lawId: 0n,
                  caller: '0x0',
                  dataTypes: [],
                  paramValues: [],
                  nonce: '0',
                  description: '',
                  upToDate: false,
                })}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to incoming proposals
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] overflow-y-auto">
            <div className="space-y-4">
              
              <section className="w-full">
                <ProposalBox
                  powers={powers}
                  lawId={BigInt(action.lawId)}
                  checks={undefined} // Will be fetched by ProposalBox if needed
                  proposalStatus={action.state || 0}
                />
              </section>

              
              <div className="w-full flex flex-col lg:flex-row gap-4">
                <section className="w-full lg:w-1/2">
                  <Voting
                    powers={powers}  
                  />
                </section>
 
              </div>
            </div>
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
              <h2 className="text-lg font-semibold text-slate-800">Incoming</h2>
              <p className="text-sm text-slate-600">Active proposals and enabled actions requiring your attention</p>
            </div>
          </div>
        </div>
        
        {incomingActions.length === 0 ? (
          <div className="p-4">
            <div className="text-center py-8">
              <p className="text-sm text-slate-500 italic">
                No active proposals or enabled actions requiring your attention
              </p>
            </div>
          </div>
        ) : (
          <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
            {/* Proposed actions (Active or Succeeded) */}
            {incomingActions.map((action: Action | undefined) => action && (
              <div 
                key={`${action.actionId}-${action.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(action as Action)}
              >
                <UserItem 
                  powers={powers as Powers}
                  law={powers.laws?.find(law => law.index === BigInt(action.lawId)) as Law}
                  chainId={chainId as string}
                  showLowerSection={false}
                  actionId={BigInt(action.actionId)}
                />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// export default function Incoming(_: any) {
//     return null
//   }