'use client'

import React, { useState } from 'react'
import { Powers, Action, Mandate } from '@/context/types'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { UserItem } from './UserItem'
import { useParams } from 'next/navigation'
import { setAction, usePowersStore, useActionStore } from '@/context/store'
import { useChains } from 'wagmi'
import { hashAction } from '@/utils/hashAction'
import { MandateBoxStatic } from '@/components/MandateBoxStatic'
import { MandateDependenciesList } from '@/components/MandateDependenciesList'
import { callDataToActionParams } from '@/utils/callDataToActionParams'


const getIncomingActions = ( 
  powers: Powers, 
  hasRoles: bigint[]
): Action[] => {
  const incomingActions: Action[] = []
  console.log("@Incoming, getIncomingActions", {hasRoles, powers})
  
  // Create a map of all actions for quick lookup
  const actionMap = new Map<string, Action>();
  powers.mandates?.forEach(l => l.actions?.forEach(a => {
      if (a.actionId) actionMap.set(a.actionId, a);
  }));

  // Step 1: get the user mandates 
  const userMandates = powers.mandates?.filter(mandate => 
    mandate.active && mandate.conditions && hasRoles.some(role => role === mandate.conditions?.allowedRole as bigint)
  )
  console.log("@Incoming, userMandates", {userMandates})

  if (!userMandates || userMandates.length === 0) {
    return []
  }

  // step 2: get the proposed actions for the user
  const proposedActions = userMandates.flatMap(l => l.actions || [])
    .filter(a => a?.state === 1 || a?.state === 3 || a?.state === 5) as Action[]
  
  // Step 3: get the enabled (incoming) actions
  for (const mandate of userMandates) {
    const needFulfilled = mandate.conditions?.needFulfilled;
    const needNotFulfilled = mandate.conditions?.needNotFulfilled;

    console.log("@Incoming, processing mandate", {mandateIndex: mandate.index, needFulfilled, needNotFulfilled})

    // 1: if no needFulfilled has been set: skip the rest, do nothing
    if (!needFulfilled || needFulfilled === 0n) continue;

    // 2: if 'needFulfilled' is set: check if any of the actionIds of the needFulfilled mandate are set to 7 (fulfilled).
    const parentMandate = powers.mandates?.find(l => l.index === needFulfilled);
    if (!parentMandate || !parentMandate.actions) continue;

    // Filter parent actions that are fulfilled (state 7)
    const fulfilledParentActions = parentMandate.actions.filter(a => a.state === 7);

    console.log("@Incoming, fulfilled parent actions", {parentMandateIndex: parentMandate.index, fulfilledParentActions})

    for (const parentAction of fulfilledParentActions) {
      // 3: calculate the actionId for the userMandate
      const userActionId = hashAction(
        mandate.index,
        parentAction.callData as `0x${string}`,
        BigInt(parentAction.nonce as string)
      );

      // see if it has been executed (state == 7)
      const existingUserAction = actionMap.get(userActionId.toString());
      console.log("@Incoming, existing user action", {userActionId, existingUserAction})

      if (existingUserAction?.state === 7) continue;

      // 4: if not, calculated the actionId for the needNotFulfilled mandate Id and check if that one has been executed (state == 7).
      if (needNotFulfilled && needNotFulfilled > 0n) {
        const blockingActionId = hashAction(
          needNotFulfilled,
          parentAction.callData as `0x${string}`,
          BigInt(parentAction.nonce as string)
        );
        console.log("@Incoming, blocking action", {blockingActionId})
        
        const existingBlockingAction = actionMap.get(blockingActionId.toString());
        if (existingBlockingAction?.state === 7) continue;
      }

      console.log("@Incoming, adding incoming action", {userActionId, mandateIndex: mandate.index})

      // 5: if not: add the useMandate actionId and all other action data to the 'incomingActions' array.
      incomingActions.push({
        actionId: userActionId.toString(),
        mandateId: mandate.index,
        caller: parentAction.caller,
        dataTypes: parentAction.dataTypes,
        paramValues: parentAction.paramValues,
        nonce: parentAction.nonce,
        description: parentAction.description,
        callData: parentAction.callData,
      })
    }
  }

  return [...proposedActions, ...incomingActions]
}

export default function Incoming({hasRoles}: {hasRoles: bigint[]}) {
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const powers = usePowersStore();
  const action = useActionStore();
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))

  // State for selected proposal/action 
  const incomingActions = getIncomingActions(powers, hasRoles)

  console.log("@Incoming, waypoint 0", {incomingActions})

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

  // Handle item click for static form view (enabled actions or succeeded proposals)
  const handleItemClick = (action: Action) => {
    try {
      const paramValues = callDataToActionParams(action, powers)
      setAction({
        ...action,
        paramValues: paramValues
      }) 
      console.log("@Incoming, handleItemClick", {action})
    } catch (error) {
      console.error("Error fetching action data:", error)
    }
  }

  // If an item is selected for static form view (enabled action or succeeded proposal)
  if (action.actionId) {
    const mandate = powers.mandates?.find(mandate => mandate.index === BigInt(action.mandateId)) as Mandate
    
    return (
      <div className="w-full mx-auto pb-12">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  setAction({
                    actionId: '',
                    mandateId: 0n,
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
            {/* Static Form with Action Data - Matching DynamicForm layout Note: execution is not yet implemented */}
            <MandateBoxStatic powers={powers as Powers} mandate={mandate as Mandate} selectedExecution={undefined} /> 

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
                key={`${action.actionId}-${action.mandateId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleItemClick(action as Action)}
              >
                <UserItem 
                  powers={powers as Powers}
                  mandate={powers.mandates?.find(mandate => mandate.index === BigInt(action.mandateId)) as Mandate}
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
