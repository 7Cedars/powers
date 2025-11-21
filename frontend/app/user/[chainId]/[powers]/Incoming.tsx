'use client'

import React, { useState } from 'react'
import { Powers, Action, Law } from '@/context/types'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { UserItem } from './UserItem'
import { useParams } from 'next/navigation'
import { setAction, usePowersStore, useActionStore } from '@/context/store'
import { useChains } from 'wagmi'
import { hashAction } from '@/utils/hashAction'
import { LawBoxStatic } from '@/components/LawBoxStatic'
import { LawDependenciesList } from '@/components/LawDependenciesList'
import { callDataToActionParams } from '@/utils/callDataToActionParams'


const getIncomingActions = ( 
  powers: Powers, 
  hasRoles: bigint[]
): Action[] => {
  const incomingActions: Action[] = []
  console.log("@Incoming, getIncomingActions", {hasRoles, powers})
  
  // Create a map of all actions for quick lookup
  const actionMap = new Map<string, Action>();
  powers.laws?.forEach(l => l.actions?.forEach(a => {
      if (a.actionId) actionMap.set(a.actionId, a);
  }));

  // Step 1: get the user laws 
  const userLaws = powers.laws?.filter(law => 
    law.active && law.conditions && hasRoles.some(role => role === law.conditions?.allowedRole as bigint)
  )
  console.log("@Incoming, userLaws", {userLaws})

  if (!userLaws || userLaws.length === 0) {
    return []
  }

  // step 2: get the proposed actions for the user
  const proposedActions = userLaws.flatMap(l => l.actions || [])
    .filter(a => a?.state === 1 || a?.state === 3 || a?.state === 5) as Action[]
  
  // Step 3: get the enabled (incoming) actions
  for (const law of userLaws) {
    const needFulfilled = law.conditions?.needFulfilled;
    const needNotFulfilled = law.conditions?.needNotFulfilled;

    console.log("@Incoming, processing law", {lawIndex: law.index, needFulfilled, needNotFulfilled})

    // 1: if no needFulfilled has been set: skip the rest, do nothing
    if (!needFulfilled || needFulfilled === 0n) continue;

    // 2: if 'needFulfilled' is set: check if any of the actionIds of the needFulfilled law are set to 7 (fulfilled).
    const parentLaw = powers.laws?.find(l => l.index === needFulfilled);
    if (!parentLaw || !parentLaw.actions) continue;

    // Filter parent actions that are fulfilled (state 7)
    const fulfilledParentActions = parentLaw.actions.filter(a => a.state === 7);

    console.log("@Incoming, fulfilled parent actions", {parentLawIndex: parentLaw.index, fulfilledParentActions})

    for (const parentAction of fulfilledParentActions) {
      // 3: calculate the actionId for the userLaw
      const userActionId = hashAction(
        law.index,
        parentAction.callData as `0x${string}`,
        BigInt(parentAction.nonce as string)
      );

      // see if it has been executed (state == 7)
      const existingUserAction = actionMap.get(userActionId.toString());
      console.log("@Incoming, existing user action", {userActionId, existingUserAction})

      if (existingUserAction?.state === 7) continue;

      // 4: if not, calculated the actionId for the needNotFulfilled law Id and check if that one has been executed (state == 7).
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

      console.log("@Incoming, adding incoming action", {userActionId, lawIndex: law.index})

      // 5: if not: add the useLaw actionId and all other action data to the 'incomingActions' array.
      incomingActions.push({
        actionId: userActionId.toString(),
        lawId: law.index,
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
    const law = powers.laws?.find(law => law.index === BigInt(action.lawId)) as Law
    
    return (
      <div className="w-full mx-auto pb-12">
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
            {/* Static Form with Action Data - Matching DynamicForm layout Note: execution is not yet implemented */}
            <LawBoxStatic powers={powers as Powers} law={law as Law} selectedExecution={undefined} /> 

            <LawDependenciesList
              laws={enabledLaws}
              mode="enables"
              powers={powers as Powers}
              blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
            />

            <LawDependenciesList
              laws={blockedLaws}
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
