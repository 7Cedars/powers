"use client";

import React, { useEffect, useState } from "react";
import { setAction } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter, useParams } from "next/navigation";
import { Action, LawExecutions, Powers, PowersExecutions, Status } from "@/context/types";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";
import { useAction } from "@/hooks/useAction";

export function LogsList({powers, status, onRefresh}: {powers: Powers | undefined, status: string, onRefresh: () => void}) {
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { fetchActionData, data: actionData, status: statusAction } = useAction()
  const router = useRouter()

  // console.log("@LogsList: waypoint 0", {powers, status, onRefresh})

  let tempActions: (Action | undefined)[] = powers?.executedActions?.map((lawActions: LawExecutions, i) => {
    const law = powers?.laws?.find(law => law.index == BigInt(i + 1))
    const executions = lawActions.actionsIds.map((actionId, i) => {
      return {
        lawId: law?.index,
        actionId: actionId,
        executedAt: lawActions.executions[i],
        role: law?.conditions?.allowedRole
      }
    })
    return executions as unknown as (Action | undefined)[]
  }).flat() as (Action | undefined)[]
  
  // console.log("@LogsList: waypoint 0", {tempActions})
  let executedActions: Action[] = tempActions.filter((action): action is Action => action !== undefined)
  executedActions = executedActions.sort((a, b) => Number(b?.executedAt) - Number(a?.executedAt))

  useEffect(() => {
    if (executedActions) {
      fetchTimestamps(executedActions.map((action) => action.executedAt as bigint), chainId)
    }
  }, [executedActions])

  const handleSelectAction = (action: Action) => {
    fetchActionData(BigInt(action.actionId), powers as Powers)
  }

  useEffect(() => {
    if (actionData) {
      setAction(actionData)
      router.push(`/${chainId}/${powers?.contractAddress}/laws/${Number(actionData.lawId)}`)
    }
  }, [actionData])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* table banner:roles  */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-4 overflow-y-scroll">
        <div className="text-slate-800 text-center text-md">
          Execution history
        </div>
        <div className="w-8 h-8">
          <button
            onClick={onRefresh}
            className={`w-full h-full flex justify-center items-center rounded-md border border-slate-400 py-1 px-2`}  
          >
            <ArrowPathIcon 
              className="w-5 h-5 text-slate-500 aria-selected:animate-spin"
              aria-selected={status == "pending"}
            />
          </button>
        </div>
      </div>

      {/* Table content */}
      {status == "pending" ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        : 
        powers?.executedActions && powers?.executedActions.length > 0 ? 
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-32"> Date </th>
                    <th className="px-2 py-3 font-light w-20"> Role </th>
                    <th className="px-2 py-3 font-light w-auto"> Law </th>
                    <th className="px-2 py-3 font-light w-24"> Action ID </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    executedActions?.map((action: Action, i) => {
                      const law = powers?.laws?.find(law => Number(law.index) == Number(action.lawId))
                      return (
                        law && law.conditions?.allowedRole != undefined ?
                        <tr
                          key={i}
                          className="text-xs text-left text-slate-800"
                        >
                          {/* Executed at */}
                          <td className="ps-4 px-2 py-3 w-32">
                            <a
                              href="#"
                              onClick={e => { e.preventDefault(); handleSelectAction(action); }}
                              className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                            >
                              {(() => {
                                // Ensure consistent block number format for lookup
                                const executedAtBlock = typeof action.executedAt === 'bigint' 
                                  ? action.executedAt 
                                  : BigInt(action.executedAt as unknown as string)
                                
                                const timestampData = timestamps.get(`${chainId}:${executedAtBlock}`)
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
                          
                          {/* Role */}
                          <td className="px-2 py-3 w-20">
                            <div className="truncate text-slate-500 text-xs">
                              {bigintToRole(law.conditions?.allowedRole, powers as Powers)}
                            </div>
                          </td>
                          
                          {/* Law */}
                          <td className="px-2 py-3 w-auto">
                            <div className="truncate text-slate-500 text-xs">
                              {shorterDescription(law.nameDescription, "short")}
                            </div>
                          </td>
                          
                          {/* Action ID */}
                          <td className="px-2 py-3 w-24">
                            <div className="truncate text-slate-500 text-xs font-mono" title={action.actionId.toString()}>
                              {action.actionId.toString()}
                            </div>
                          </td>
                        </tr>
                        : 
                        null
                      )
                    })
                  }
                </tbody>
              </table>
            </div>
          </div>
        :
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No recent executions found
        </div>
      }
    </div>
  );
} 