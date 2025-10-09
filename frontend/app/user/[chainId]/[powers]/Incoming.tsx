'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { Powers, Action, Law, Status, InputType } from '@/context/types'
import { ArrowPathIcon, ArrowLeftIcon } from '@heroicons/react/24/outline'
import { UserItem } from './UserItem'
import { useParams } from 'next/navigation'
import { ProposalBox } from '@/components/ProposalBox'
import { Voting } from '@/components/Voting'
import { Votes } from '@/components/Votes'
import { useChecks } from '@/hooks/useChecks'
import { setAction } from '@/context/store'
import { useChains } from 'wagmi'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'
import { hashAction } from '@/utils/hashAction'
import { useAction } from '@/hooks/useAction'
import { StaticForm } from '@/components/StaticForm'
import HeaderLaw from '@/components/HeaderLaw'
import { Button } from '@/components/Button'
import { useLaw } from '@/hooks/useLaw'
import { encodeAbiParameters, parseAbiParameters } from "viem"

/**
 * Get enabled actions based on fulfilled needFulfilled laws
 * Following the new 10-step logic:
 * 4. Per law that the user has access to:
 * 5. Check if it has a needFulfilled set
 * 6. Fetch all actions from this needFulfilled law, filter by status = fulfilled
 * 7. If the list is longer than 0:
 * 8. Calculate the action IDs for each action for the selected law, and check if the action has been fulfilled
 * 9. If a needNotFulfilled was set at the law, check if the action has been fulfilled at this needNotFulfilled law
 * 10. List the action as 'enabled' in the list
 */
const getEnabledActions = async (
  powers: Powers, 
  hasRoles: {role: bigint, since: bigint}[], 
  fetchAction: (action: Action, powers: Powers) => Promise<Action | undefined>
): Promise<Action[]> => {
  const enabledActions: Action[] = []
  
  if (!powers.laws) {
    return enabledActions
  }

  // Step 4: Per law that the user has access to
  const userRoleIds = hasRoles.map(role => role.role)
  const userLaws = powers.laws.filter(law => 
    law.active && law.conditions && userRoleIds.includes(law.conditions.allowedRole)
  )
  
  for (const law of userLaws) {
    // Step 5: Check if it has a needFulfilled set
    if (!law.conditions?.needFulfilled || law.conditions.needFulfilled === 0n) {
      continue
    }
    
    // Find the needFulfilled law
    const needFulfilledLaw = powers.laws.find(l => 
      l.index === law.conditions!.needFulfilled
    )
    
    if (!needFulfilledLaw || !needFulfilledLaw.actions) {
      continue
    }
    
    // Step 6: Fetch all actions from this needFulfilled law, filter by status = fulfilled
    const fulfilledActions = needFulfilledLaw.actions.filter(action => 
      action.state === 7 || (action.fulfilledAt && action.fulfilledAt > 0n)
    )
    
    // Step 7: If the list is longer than 0
    if (fulfilledActions.length === 0) {
      continue
    }
    
    for (const fulfilledAction of fulfilledActions) {
      try {
        // Ensure we have complete action data
        const completeAction = await fetchAction(fulfilledAction, powers)
        if (!completeAction || !completeAction.callData || !completeAction.nonce) {
          continue
        }
        
        // Step 8: Calculate the action ID for the selected law
        const calculatedActionId = hashAction(
          law.index,
          completeAction.callData,
          BigInt(completeAction.nonce)
        )
        
        // Check if this action has been fulfilled in the current law
        const existingAction = law.actions?.find(action => 
          action.actionId === calculatedActionId.toString()
        )
        
        // If the action is already fulfilled, skip it
        if (existingAction && (existingAction.state === 7 || (existingAction.fulfilledAt && existingAction.fulfilledAt > 0n))) {
          continue
        }
        
        // Step 9: If a needNotFulfilled was set at the law, check if the action has been fulfilled
        if (law.conditions?.needNotFulfilled && law.conditions.needNotFulfilled > 0n) {
          const needNotFulfilledLaw = powers.laws.find(l => 
            l.index === law.conditions!.needNotFulfilled
          )
          
          if (needNotFulfilledLaw) {
            // Calculate what the action ID would be in the needNotFulfilled law
            const needNotFulfilledActionId = hashAction(
              needNotFulfilledLaw.index,
              completeAction.callData,
              BigInt(completeAction.nonce)
            )
            
            // Check if this action is fulfilled in the needNotFulfilled law
            const blockedAction = needNotFulfilledLaw.actions?.find(action => 
              action.actionId === needNotFulfilledActionId.toString() &&
              (action.state === 7 || (action.fulfilledAt && action.fulfilledAt > 0n))
            )
            
            // If the blocking action is fulfilled, skip this enabled action
            if (blockedAction) {
              continue
            }
          }
        }
        
        // Step 10: Add to enabled actions
        const enabledAction: Action = {
          actionId: calculatedActionId.toString(),
          lawId: law.index,
          caller: completeAction.caller,
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: completeAction.paramValues,
          nonce: completeAction.nonce,
          description: completeAction.description || `Action enabled by fulfillment of law ${needFulfilledLaw.index}`,
          callData: completeAction.callData,
          upToDate: true,
          state: undefined, // Not yet proposed or fulfilled
        }
        enabledActions.push(enabledAction)
        
      } catch (error) {
        console.error("@getEnabledActions: Error processing action", error)
      }
    }
  }
  
  return enabledActions
}

type IncomingProps = {
  hasRoles: {role: bigint, since: bigint}[]
  powers: Powers
  onRefresh: () => void
  resetRef: React.MutableRefObject<(() => void) | null>
}

export default function Incoming({hasRoles, powers, onRefresh, resetRef}: IncomingProps) {
  const { chainId } = useParams<{ chainId: string }>()
  const { fetchChecks, status: statusChecks } = useChecks()
  const { fetchAction } = useAction()
  const { status: statusLaw, request, propose } = useLaw()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))
  
  // State for selected proposal/action
  const [selectedProposal, setSelectedProposal] = useState<Action | null>(null)
  const [proposedActions, setProposedActions] = useState<Action[]>([])
  const [enabledActions, setEnabledActions] = useState<Action[]>([])
  const [selectedItem, setSelectedItem] = useState<Action | null>(null)
  const [actionData, setActionData] = useState<Action | null>(null)
  const [loadingActionData, setLoadingActionData] = useState(false)
  const [loadingIncoming, setLoadingIncoming] = useState(false)
  const [dynamicDescription, setDynamicDescription] = useState<string>('')

  // console.log("@Incoming, waypoint 0", {loadingIncoming})

  // Reset function to go back to list view
  const resetSelection = useCallback(() => {
    setSelectedProposal(null)
    setSelectedItem(null)
    setActionData(null)
    setDynamicDescription('')
  }, [])

  // Assign reset function to ref
  React.useEffect(() => {
    resetRef.current = resetSelection
    return () => {
      resetRef.current = null
    }
  }, [resetSelection, resetRef])

  // Filter out enabled actions that already have active or succeeded proposals
  const filteredEnabledActions = useMemo(() => {
    if (!enabledActions.length || !proposedActions.length) return enabledActions
    
    return enabledActions.filter(enabledAction => {
      // Check if there's a proposed action with the same actionId
      const hasProposal = proposedActions.some(proposal => 
        proposal.actionId === enabledAction.actionId
      )
      
      return !hasProposal
    })
  }, [enabledActions, proposedActions])

  // Get laws that will be enabled by executing the selected item's law
  const enabledLaws = selectedItem && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needFulfilled == selectedItem.lawId
    ) : []

  // Get laws that will be blocked by executing the selected item's law
  const blockedLaws = selectedItem && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needNotFulfilled == selectedItem.lawId
    ) : []

  /**
   * Fetch incoming actions following the new architecture:
   * 1. Fetch all actions from the laws that the user has access to
   * 2. Fetch their status
   * 3. List the actions as 'proposed' in the list (3 = Active)
   * 4-10. Get enabled actions (handled in getEnabledActions)
   */
  useEffect(() => {
    const fetchIncomingActions = async () => {
      // console.log("@fetchIncomingActions, waypoint 0", {powers, hasRoles})
      if (!powers || !powers.laws || hasRoles.length === 0) {
        setProposedActions([])
        setEnabledActions([])
        return
      }
      // console.log("@fetchIncomingActions, waypoint 1", {powers, hasRoles})
      setLoadingIncoming(true)
      
      try {
        // console.log("@fetchIncomingActions, waypoint 2", {powers, hasRoles})
        // Step 1: Get all actions from laws that the user has access to
        const userRoleIds = hasRoles.map(role => role.role)
        const userLaws = powers.laws.filter(law => 
          law.active && law.conditions && userRoleIds.includes(law.conditions.allowedRole)
        )
        // console.log("@fetchIncomingActions, waypoint 3", {userLaws})
        const allUserActions: Action[] = []
        for (const law of userLaws) {
          if (law.actions && law.actions.length > 0) {
            allUserActions.push(...law.actions)
          }
        }
        // console.log("@fetchIncomingActions, waypoint 4", {allUserActions})
        // Step 2 & 3: Fetch their status and filter for proposed actions (Active or Succeeded)
        const proposedActionsList: Action[] = []
        for (const action of allUserActions) {
          try {
            const completeAction = await fetchAction(action, powers)
            if (completeAction && (completeAction.state === 3)) {
              proposedActionsList.push(completeAction)
            }
            console.log("@fetchIncomingActions, waypoint 5", {completeAction})
          } catch (error) {
            console.error("Error fetching action state:", error)
          }
        }
        // console.log("@fetchIncomingActions, waypoint 5", {proposedActionsList})
        setProposedActions(proposedActionsList)
        
        // Steps 4-10: Get enabled actions
        const enabled = await getEnabledActions(powers, hasRoles, fetchAction)
        // console.log("@fetchIncomingActions, waypoint 6", {enabled})
        setEnabledActions(enabled)
        
      } catch (error) {
        console.error("Error fetching incoming actions:", error)
        setProposedActions([])
        setEnabledActions([])
      } finally {
        // console.log("@fetchIncomingActions, waypoint 7", {loadingIncoming: false})
        setLoadingIncoming(false)
      }
    }
    
    fetchIncomingActions()
  }, [powers, hasRoles, fetchAction])

  // Handle proposal click
  const handleProposalClick = (proposal: Action) => {
    setSelectedProposal(proposal)
    // Set the action in the store for ProposalBox
    setAction(proposal)
  }

  // Handle item click for static form view (enabled actions or succeeded proposals)
  const handleItemClick = useCallback(async (action: Action) => {
    setSelectedItem(action)
    setLoadingActionData(true)
    setActionData(null)
    
    try {
      // Fetch complete action data
      const completeAction = await fetchAction(action, powers)
      if (completeAction) {
        setActionData(completeAction)
        setAction(completeAction)
        setDynamicDescription(completeAction.description || '')
      }
    } catch (error) {
      console.error("Error fetching action data:", error)
    } finally {
      setLoadingActionData(false)
    }
  }, [fetchAction, powers])

  // Wrapper for fetchChecks to match the expected signature
  const handleCheck = async (law: Law, action: Action, wallets: any[], powers: Powers) => {
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

  // Handle execute for static form view
  const handleExecute = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    if (!selectedItem) return
    
    const law = powers.laws?.find(law => law.index === BigInt(selectedItem.lawId)) as Law
    if (!law) return
    
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        console.error("Error encoding parameters:", error)
        return
      }
    } else {
      lawCalldata = '0x0'
    }

    // Use dynamic description for enabled actions, otherwise use the provided description
    const isEnabledAction = filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId)
    const finalDescription = isEnabledAction ? dynamicDescription : description

    request(
      law, 
      lawCalldata as `0x${string}`,
      nonce,
      finalDescription
    )
  }

  // Handle propose for static form view
  const handlePropose = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    if (!selectedItem) return
    
    const law = powers.laws?.find(law => law.index === BigInt(selectedItem.lawId)) as Law
    if (!law) return
    
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        console.error("Error encoding parameters:", error)
        return
      }
    } else {
      lawCalldata = '0x0'
    }

    // Use dynamic description for enabled actions, otherwise use the provided description
    const isEnabledAction = filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId)
    const finalDescription = isEnabledAction ? dynamicDescription : description

    propose(
      law.index as bigint,
      lawCalldata,
      nonce,
      finalDescription,
      powers as Powers
    )
  }

  // If an item is selected for static form view (enabled action or succeeded proposal)
  if (selectedItem) {
    const law = powers.laws?.find(law => law.index === BigInt(selectedItem.lawId)) as Law
    
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
                  actionId={BigInt(selectedItem.actionId)}
                  showLowerSection={false}
                  isEnabledAction={filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId)}
                />
              </div>

              {/* Form content */}
              <div className="p-6">
                {loadingActionData ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-slate-500">Loading action data...</div>
                  </div>
                ) : actionData ? (
                  <>
                    <StaticForm 
                      law={law} 
                      staticDescription={!filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId)}
                    />
                    
                    {/* Dynamic reason box for enabled actions */}
                    {filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId) && (
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


              {actionData && (
                <>
                  {/* Check button */}
                  <div className="w-full px-6 py-2">
                    <Button 
                      size={0} 
                      role={6}
                      onClick={() => {
                        if (actionData) {
                          handleCheck(law, actionData, [], powers)
                        }
                      }}
                      filled={false}
                      selected={true}
                      statusButton={
                        // For enabled actions, check if we have action data and description
                        filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId) 
                          ? (actionData && dynamicDescription && dynamicDescription.length > 0 ? statusChecks : 'disabled')
                          : statusChecks
                      }
                    >
                      Check
                    </Button>
                  </div>

                  {/* Execute or Propose button */}
                  <div className="w-full h-fit px-6 py-2 pb-6">
                    <Button 
                      size={0} 
                      role={6}
                      onClick={() => {
                        if (actionData && actionData.nonce) {
                          const nonce = BigInt(actionData.nonce)
                          const description = actionData.description || ''
                          const paramValues = actionData.paramValues || []
                          
                          if (law?.conditions?.quorum != 0n) {
                            handlePropose(paramValues, nonce, description)
                          } else {
                            handleExecute(paramValues, nonce, description)
                          }
                        }
                      }} 
                      filled={false}
                      selected={true}
                      statusButton={
                        // For enabled actions, check if we have action data and description
                        filteredEnabledActions.some(enabled => enabled.actionId === selectedItem.actionId) 
                          ? (actionData && dynamicDescription && dynamicDescription.length > 0 ? statusLaw : 'disabled')
                          : statusLaw
                      }
                    > 
                      {law?.conditions?.quorum != 0n ? 'Create proposal' : 'Execute'}
                    </Button>
                  </div>
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
  if (selectedProposal) {
    // const law = powers.laws?.find(law => law.index === BigInt(selectedProposal.lawId)) as Law
    
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSelectedProposal(null)}
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
                  lawId={BigInt(selectedProposal.lawId)}
                  checks={undefined} // Will be fetched by ProposalBox if needed
                  status={statusChecks}
                  onCheck={handleCheck}
                  proposalStatus={selectedProposal.state || 0}
                />
              </section>

              
              <div className="w-full flex flex-col lg:flex-row gap-4">
                <section className="w-full lg:w-1/2">
                  <Voting
                    powers={powers} 
                    status={statusChecks as Status}
                  />
                </section>

                <section className="w-full lg:w-1/2">
                  <Votes 
                    actionId={selectedProposal.actionId}
                    action={selectedProposal}
                    powers={powers}
                    status={statusChecks as Status}
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
            <button 
              onClick={onRefresh}
              disabled={loadingIncoming}
              className="p-2 text-slate-500 hover:text-slate-700 transition-colors disabled:opacity-50"
            >
              <ArrowPathIcon className={`w-5 h-5 ${loadingIncoming ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
        
        {loadingIncoming ? (
          <div className="p-4">
            <div className="flex items-center justify-center py-8">
              <div className="text-sm text-slate-500">Loading active proposals and enabled actions...</div>
            </div>
          </div>
        ) : (proposedActions.length === 0 && filteredEnabledActions.length === 0) ? (
          <div className="p-4">
            <div className="text-center py-8">
              <p className="text-sm text-slate-500 italic">
                No active proposals requiring your attention
              </p>
            </div>
          </div>
        ) : (
          <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
            {/* Proposed actions (Active or Succeeded) */}
            {proposedActions.map((action: Action) => (
              <div 
                key={`${action.actionId}-${action.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => action.state != 3 ? handleItemClick(action) : handleProposalClick(action)}
              >
                <UserItem
                  powers={powers}
                  law={powers.laws?.find(law => law.index === BigInt(action.lawId)) as Law}
                  chainId={chainId as string}
                  showLowerSection={false}
                  actionId={BigInt(action.actionId)}
                />
              </div>
            ))}
            
            {/* Enabled actions */}
            {filteredEnabledActions.map((action: Action) => (
              <div 
                key={`enabled-${action.actionId}-${action.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(action)}
              >
                <UserItem
                  powers={powers}
                  law={powers.laws?.find(law => law.index === BigInt(action.lawId)) as Law}
                  chainId={chainId as string}
                  showLowerSection={false}
                  actionId={BigInt(action.actionId)}
                  isEnabledAction={true}
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