"use client";

import React, { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { Action, Powers } from "@/context/types";
import { parseProposalStatus, shorterDescription } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";
import { setAction } from "@/context/store";

export function ActionsList({powers, status}: {powers: Powers | undefined, status: string}) {
  const router = useRouter()
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()

  const possibleStatus: string[] = ['0', '1', '2', '3', '4', '5']
  const [ deselectedStatus, setDeselectedStatus] = useState<string[]>([])

  // Aggregate actions across all laws, skipping those without a defined state
  const aggregatedActions: Action[] = (powers?.laws || [])
    .flatMap(law => (law.actions || [])
      .map(action => ({ ...action }))
    )
  
  const actionsWithState: Action[] = aggregatedActions.map(action =>  {
    if (action?.cancelledAt && action.cancelledAt > 0) {
      return { ...action, state: 2 }
    }
    if (action?.fulfilledAt && action.fulfilledAt > 0) {
      return { ...action, state: 7 }
    }
    if (action?.requestedAt && action.requestedAt > 0) {
      return { ...action, state: 6 }
    }
    if (action?.proposedAt && action.proposedAt > 0) {
      return { ...action, state: 3 }
    } 
    return { ...action, state: 0 }
  })
    // .filter(a => a != undefined && a.state != undefined) as Action[]

  console.log("@ActionsList: waypoint 0", {actionsWithState})

  // Fetch timestamps for action blocks
  useEffect(() => {
    if (!actionsWithState || actionsWithState.length === 0) return
    const allTimestamps = Array.from(new Set(
      actionsWithState.flatMap(action => [
        action?.requestedAt,
        action?.proposedAt, 
        action?.fulfilledAt,
        action?.cancelledAt
      ].filter((timestamp): timestamp is bigint => 
        timestamp !== undefined && 
        timestamp !== null
      ))
    ))
    if (allTimestamps.length > 0) {
      fetchTimestamps(allTimestamps, chainId)
    }
  }, [actionsWithState, chainId, fetchTimestamps])

  const handleStatusSelection = (actionStatus: string) => {
    let newDeselection: string[] = []
    if (deselectedStatus.includes(actionStatus)) {
      newDeselection = deselectedStatus.filter(option => option !== actionStatus)
    } else {
      newDeselection = [...deselectedStatus, actionStatus]
    }
    setDeselectedStatus(newDeselection)
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Status filter bar */}
      <div className="w-full flex flex-row gap-6 justify-between items-center py-4 overflow-y-scroll border-b border-slate-200 px-4">
      {
        possibleStatus.map((option, i) => {
          return (
            <button 
            key = {i}
            onClick={() => handleStatusSelection(option)}
            className="w-fit h-full hover:text-slate-400 text-sm aria-selected:text-slate-800 text-slate-300"
            aria-selected = {!deselectedStatus?.includes(option)}
            >  
              <p className="text-sm text-left"> {parseProposalStatus(option)} </p>
          </button>
          )
        })
      }
      </div>

      {/* Table content */}
      {status == "pending" ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        : 
        actionsWithState && actionsWithState.length > 0 ? 
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-40"> Date </th>
                    <th className="px-2 py-3 font-light w-32"> Action ID </th>
                    <th className="px-2 py-3 font-light w-auto"> Law </th>
                    <th className="px-2 py-3 font-light w-24"> Status </th>
                    <th className="px-2 py-3 font-light w-20"> Role </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    actionsWithState
                      
                      ?.map((action: Action, i) => {
                        const law = powers?.laws?.find(law => law.index == action.lawId)
                        if (!law || law.conditions?.allowedRole == undefined) return null
                        if (deselectedStatus.includes(String(action.state))) return null

                        return (
                          <tr
                            key={i}
                            className="text-xs text-left text-slate-800"
                          >
                            {/* Date */}
                            <td className="ps-4 px-2 py-3 w-40">
                              <a
                                href="#"
                                onClick={e => { 
                                  e.preventDefault(); 
                                  setAction(action) 
                                  router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${Number(action.lawId)}`)
                                }}
                                className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                              >
                                {(() => {
                                  // Get the earliest non-zero timestamp between proposed and requested
                                  let targetBlock: bigint | undefined;
                                  const proposedAt = typeof action.proposedAt === 'bigint' 
                                    ? action.proposedAt 
                                    : (action.proposedAt ? BigInt(action.proposedAt as unknown as string) : 0n);
                                  const requestedAt = typeof action.requestedAt === 'bigint'
                                    ? action.requestedAt
                                    : (action.requestedAt ? BigInt(action.requestedAt as unknown as string) : 0n);

                                  if (proposedAt > 0n && requestedAt > 0n) {
                                    targetBlock = proposedAt < requestedAt ? proposedAt : requestedAt;
                                  } else if (proposedAt > 0n) {
                                    targetBlock = proposedAt;
                                  } else if (requestedAt > 0n) {
                                    targetBlock = requestedAt;
                                  }

                                  if (!targetBlock) {
                                    return 'No timestamp';
                                  }

                                  const timestampData = timestamps.get(`${chainId}:${targetBlock}`)
                                  const timestamp = timestampData?.timestamp
                                  
                                  if (!timestamp || timestamp <= 0n) {
                                    return 'Loading...'
                                  }
                                  
                                  const timestampNumber = Number(timestamp)
                                  if (isNaN(timestampNumber) || timestampNumber <= 0) {
                                    return 'Invalid date'
                                  }
                                  
                                  try {
                                    return `${toFullDateFormat(timestampNumber)}: ${toEurTimeFormat(timestampNumber)}`
                                  } catch (error) {
                                    console.error('Date formatting error:', error, { timestamp, timestampNumber })
                                    return 'Date error'
                                  }
                                })()}
                              </a>
                            </td>

                            {/* Action ID */}
                            <td className="px-2 py-3 w-32">
                              <div className="truncate text-slate-500 text-xs font-mono">
                                {`${action.actionId.toString().slice(0, 6)}...${action.actionId.toString().slice(-4)}`}
                              </div>
                            </td>

                            {/* Law */}
                            <td className="px-2 py-3 w-auto">
                              <div className="truncate text-slate-500 text-xs">
                                {shorterDescription(law.nameDescription, "short")}
                              </div>
                            </td>

                            {/* Status */}
                            <td className="px-2 py-3 w-24">
                              <div className="truncate text-slate-500 text-xs">
                                {parseProposalStatus(String(action.state))}
                              </div>
                            </td>

                            {/* Role */}
                            <td className="px-2 py-3 w-20">
                              <div className="truncate text-slate-500 text-xs">
                                {bigintToRole(law.conditions?.allowedRole, powers as Powers)}
                              </div>
                            </td>
                          </tr>
                        )
                      })
                  }
                </tbody>
              </table>
            </div>
          </div>
        :
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No actions found
        </div>
      }
    </div>
  );
} 