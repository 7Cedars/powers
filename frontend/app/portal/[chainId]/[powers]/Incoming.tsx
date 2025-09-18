'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { Powers, Action, Law, Status, InputType } from '@/context/types'
import { ArrowPathIcon, ArrowLeftIcon } from '@heroicons/react/24/outline'
import { PortalItem } from './PortalItem'
import { useParams } from 'next/navigation'
import { useProposal } from '@/hooks/useProposal'
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

// Function to check for actions enabled by other laws
const getEnabledActions = async (powers: Powers, hasRoles: {role: bigint, since: bigint}[], fetchActionData: (actionId: bigint, powers: Powers) => Promise<Action | undefined>): Promise<Action[]> => {
  const enabledActions: Action[] = []
  
  if (!powers.laws || !powers.executedActions) {
    console.log("@getEnabledActions: Missing laws or executedActions", {laws: powers.laws, executedActions: powers.executedActions})
    return enabledActions
  }

  // 1. Filter laws with roles that the user has
  const userRoleIds = hasRoles.map(role => role.role)
  const userLaws = powers.laws.filter(law => 
    law.conditions && userRoleIds.includes(law.conditions.allowedRole)
  )
  
  console.log("@getEnabledActions: User roles and laws", {userRoleIds, userLaws: userLaws.length})

  // 2. Check each law for needCompleted requirement
  for (const law of userLaws) {
    if (law.conditions?.needCompleted && law.conditions.needCompleted > 0) {
      console.log("@getEnabledActions: Found law with needCompleted", {lawIndex: law.index, needCompleted: law.conditions.needCompleted})
      
      // 3. Find the needCompleted law
      const needCompletedLaw = powers.laws.find(l => 
        BigInt(l.index) === BigInt(law.conditions!.needCompleted)
      )
      
      if (needCompletedLaw) {
        console.log("@getEnabledActions: Found needCompleted law", {needCompletedLawIndex: needCompletedLaw.index})
        
        // 4. Get fulfilled actions from the needCompleted law
        // Find the executed actions for the needCompleted law by matching the law index
        const needCompletedLawExecutions = powers.executedActions.find((exec, index) => {
          const lawForExecution = powers.laws?.[index]
          return lawForExecution?.index === needCompletedLaw.index
        })
        
        console.log("@getEnabledActions: NeedCompleted law executions", {needCompletedLawExecutions, actionsCount: needCompletedLawExecutions?.actionsIds.length})
        
        if (needCompletedLawExecutions && needCompletedLawExecutions.actionsIds.length > 0) {
          // 5. For each fulfilled action, we need to get its data to calculate the corresponding action ID for the original law
          for (const fulfilledActionId of needCompletedLawExecutions.actionsIds) {
            try {
              // Fetch the complete action data for the fulfilled action
              console.log("@getEnabledActions: Fetching fulfilled action data", {fulfilledActionId})
              
              const fulfilledActionData = await fetchActionData(fulfilledActionId, powers)

              console.log("@getEnabledActions A: Fetched fulfilled action data", {fulfilledActionData})

              if (fulfilledActionData) {
                console.log("@getEnabledActions B: Fetched fulfilled action data", {fulfilledActionData})
                
                // Now we need to calculate what the action ID would be for the original law
                // We'll use the same nonce and callData but with the original law's index
                const calculatedActionId = hashAction(
                  law.index, // Use the original law's index
                  fulfilledActionData.callData, // Use the same callData
                  BigInt(fulfilledActionData.nonce) // Use the same nonce
                )
                
                console.log("@getEnabledActions: Calculated action ID", {calculatedActionId, lawIndex: law.index, callData: fulfilledActionData.callData, nonce: fulfilledActionData.nonce})
                
                // Check if this action exists in the original law's proposals
                const existingAction = powers.proposals?.find(action => 
                  action.actionId === calculatedActionId.toString() && 
                  action.lawId === law.index
                )
                
                console.log("@getEnabledActions: Checking if action exists", {calculatedActionId, existingAction: !!existingAction})
                
                // 6. If action is undefined (doesn't exist in proposals), add to enabledActions
                if (!existingAction) {
                  // Create a complete action structure for the enabled action
                  const enabledAction: Action = {
                    actionId: calculatedActionId.toString(),
                    lawId: law.index,
                    caller: fulfilledActionData.caller,
                    dataTypes: law.params?.map(param => param.dataType),
                    paramValues: fulfilledActionData.paramValues,
                    nonce: fulfilledActionData.nonce,
                    description: `Action enabled by completion of law ${needCompletedLaw.index}`,
                    callData: fulfilledActionData.callData,
                    upToDate: true,
                    state: undefined,
                    fulfilled: true,
                    // Store the original fulfilled action data for display
                    originalFulfilledAction: fulfilledActionData,
                    // Store the needCompleted law for reference
                    needCompletedLaw: needCompletedLaw
                  }
                  enabledActions.push(enabledAction)
                  console.log("@getEnabledActions: Added enabled action", {enabledAction})
                }
              }
            } catch (error) {
              console.error("@getEnabledActions: Error fetching action data", {fulfilledActionId, error})
            }
          }
        }
      }
    }
  }
  
  console.log("@getEnabledActions: Final enabled actions", {enabledActionsCount: enabledActions.length, enabledActions})
  return enabledActions
}

type IncomingProps = {
  hasRoles: {role: bigint, since: bigint}[]
  powers: Powers
  proposals: Action[]
  loading: boolean
  onRefresh: () => void
}

export default function Incoming({hasRoles, powers, proposals, loading, onRefresh}: IncomingProps) {
  const { chainId } = useParams<{ chainId: string }>()
  const { getProposalsState } = useProposal()
  const { fetchChainChecks, status: statusChecks } = useChecks()
  const { fetchActionData } = useAction()
  const { status: statusLaw, execute } = useLaw()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))
  
  // State for selected proposal
  const [selectedProposal, setSelectedProposal] = useState<Action | null>(null)
  const [enabledActions, setEnabledActions] = useState<Action[]>([])
  const [selectedItem, setSelectedItem] = useState<Action | null>(null)
  const [actionData, setActionData] = useState<Action | null>(null)
  const [loadingActionData, setLoadingActionData] = useState(false)

  console.log("@Incoming, waypoint 0", {proposals, powers, enabledActions, enabledActionsCount: enabledActions.length})

  // Get laws that will be enabled by executing the selected item's law
  const enabledLaws = selectedItem && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needCompleted == selectedItem.lawId
    ) : []

  // Get laws that will be blocked by executing the selected item's law
  const blockedLaws = selectedItem && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needNotCompleted == selectedItem.lawId
    ) : []

  useEffect(() => {
    if (powers) {
      getProposalsState(powers)
    }
  }, [powers])

  useEffect(() => {
    if (powers) {
      onRefresh()
    }
  }, [ ])

  // Fetch enabled actions when powers or hasRoles change
  useEffect(() => {
    const fetchEnabledActions = async () => {
      console.log("@Incoming: useEffect triggered", {powers: !!powers, hasRoles: hasRoles.length, fetchActionData: !!fetchActionData})
      
      if (powers && hasRoles.length > 0 && fetchActionData) {
        try {
          console.log("@Incoming: Starting to fetch enabled actions", {
            powers: !!powers, 
            hasRoles: hasRoles.length,
            laws: powers.laws?.length,
            executedActions: powers.executedActions?.length,
            proposals: powers.proposals?.length
          })
          const enabled = await getEnabledActions(powers, hasRoles, fetchActionData)
          setEnabledActions(enabled)
          console.log("@Incoming: Successfully fetched enabled actions", {enabledCount: enabled.length, enabled})
        } catch (error) {
          console.error("Error fetching enabled actions:", error)
          setEnabledActions([]) // Reset on error
        }
      } else {
        console.log("@Incoming: Conditions not met for fetching enabled actions", {
          powers: !!powers,
          hasRoles: hasRoles.length,
          fetchActionData: !!fetchActionData
        })
        setEnabledActions([]) // Reset if conditions not met
      }
    }
    
    fetchEnabledActions()
  }, [powers, hasRoles, fetchActionData])

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
      // Check if this is an enabled action with stored original fulfilled action data
      const isEnabledAction = enabledActions.some(enabled => enabled.actionId === action.actionId)
      
      if (isEnabledAction && action.originalFulfilledAction) {
        // For enabled actions, use the stored original fulfilled action data
        console.log("@handleItemClick: Using stored original fulfilled action data", {originalFulfilledAction: action.originalFulfilledAction})
        setActionData(action.originalFulfilledAction)
        setAction(action.originalFulfilledAction)
      } else {
        // For succeeded proposals, fetch the action data normally
        const actionData = await fetchActionData(BigInt(action.actionId), powers)
        if (actionData) {
          setActionData(actionData)
          setAction(actionData)
        }
      }
    } catch (error) {
      console.error("Error fetching action data:", error)
    } finally {
      setLoadingActionData(false)
    }
  }, [fetchActionData, powers, enabledActions])

  // Wrapper for fetchChainChecks to match the expected signature
  const handleCheck = async (law: Law, action: Action, wallets: any[], powers: Powers) => {
    if (action && wallets.length > 0) {
      await fetchChainChecks(
        law.index,
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

    execute(
      law, 
      lawCalldata as `0x${string}`,
      nonce,
      description
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
            {/* Action coming from section - for enabled actions */}
            {selectedItem.needCompletedLaw && actionData && (
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Action <b>coming</b> from: </h3>
                <div className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50">
                  <PortalItem
                    powers={powers as Powers}
                    law={selectedItem.needCompletedLaw}
                    chainId={chainId as string}
                    actionId={BigInt(actionData.actionId)}
                    showLowerSection={false}
                  />
                </div>
              </div>
            )}

            {/* Static Form with Action Data - Matching DynamicForm layout */}
            <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600`}>
              {/* Header section with PortalItem - matching DynamicForm */}
              <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                <PortalItem
                  powers={powers as Powers}
                  law={law}
                  chainId={chainId as string}
                  actionId={BigInt(selectedItem.actionId)}
                  showLowerSection={false}
                  isEnabledAction={enabledActions.some(enabled => enabled.actionId === selectedItem.actionId)}
                />
              </div>

              {/* Form content */}
              <div className="p-6">
                {loadingActionData ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-slate-500">Loading action data...</div>
                  </div>
                ) : actionData ? (
                  <StaticForm law={law} />
                ) : (
                  <div className="text-slate-500 italic">No action data available</div>
                )}
              </div>

              {/* Check and Execute buttons - matching LawBox */}
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
                      statusButton="idle"
                    >
                      Check
                    </Button>
                  </div>

                  {/* Execute button */}
                  <div className="w-full h-fit px-6 py-2 pb-6">
                    <Button 
                      size={0} 
                      role={6}
                      onClick={() => {
                        if (actionData) {
                          handleExecute(
                            actionData.paramValues ? actionData.paramValues : [], 
                            BigInt(actionData.nonce), 
                            actionData.description
                          )
                        }
                      }} 
                      filled={false}
                      selected={true}
                      statusButton={statusLaw}
                    > 
                      Execute
                    </Button>
                  </div>
                </>
              )}
            </section>
            
            {/* Enables section */}
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
            
            {/* Blocks section */}
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
    const law = powers.laws?.find(law => law.index === BigInt(selectedProposal.lawId)) as Law
    
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
              {/* ProposalBox section */}
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

              {/* Voting and Votes section - side by side on wide screens */}
              <div className="w-full flex flex-col lg:flex-row gap-4">
                <section className="w-full lg:w-1/2">
                  <Voting 
                    action={selectedProposal} 
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
              disabled={loading}
              className="p-2 text-slate-500 hover:text-slate-700 transition-colors disabled:opacity-50"
            >
              <ArrowPathIcon className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
        
        {loading ? (
          <div className="p-4">
            <div className="flex items-center justify-center py-8">
              <div className="text-sm text-slate-500">Loading active proposals...</div>
            </div>
          </div>
        ) : (proposals.length === 0 && enabledActions.length === 0) ? (
          <div className="p-4">
            <div className="text-center py-8">
              <p className="text-sm text-slate-500 italic">
                No active proposals requiring your attention
              </p>
            </div>
          </div>
        ) : (
          <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
            {/* Regular proposals */}
            {powers.proposals?.map((proposal: Action) => (
              (proposal.state == 0 || proposal.state == 3) && (
              <div 
                key={`${proposal.actionId}-${proposal.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => proposal.state === 3 ? handleItemClick(proposal) : handleProposalClick(proposal)}
              >
                <PortalItem
                  powers={powers}
                  law={powers.laws?.find(law => law.index === BigInt(proposal.lawId)) as Law}
                  chainId={chainId as string}
                  showLowerSection={false}
                  actionId={BigInt(proposal.actionId)}
                />
              </div>
              )
            ))}
            
            {/* Enabled actions */}
            {enabledActions.map((action: Action) => (
              <div 
                key={`enabled-${action.actionId}-${action.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(action)}
              >
                <PortalItem
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
