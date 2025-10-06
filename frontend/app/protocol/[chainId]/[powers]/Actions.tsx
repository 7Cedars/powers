'use client'

import { setAction } from "@/context/store";
import { Law, Powers, Status, Action } from "@/context/types";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect, useState, useRef } from "react";
import { useAction } from "@/hooks/useAction";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

type TempAction = {actionId: string, lawId: bigint, fulfilledAt: bigint, role: bigint}

type ActionsProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  powers: Powers | undefined;
  status: Status;
  onRefresh: () => void;
}

export function Actions({ hasRoles, authenticated, powers, status, onRefresh}: ActionsProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { fetchActionData, action: actionData, status: statusAction } = useAction()
  const [tempActions, setTempActions] = useState<TempAction[]>([])
  const hasFetchedRef = useRef(false)
  
  // Auto-fetch executed actions on initialization
  useEffect(() => {
    if (powers && authenticated && !hasFetchedRef.current) {
      hasFetchedRef.current = true
      onRefresh()
    }
  }, [powers, authenticated])
  
  useEffect(() => {
    if (powers?.laws) {
      const actionArray = powers.laws.map((law: Law, i) => {
        return law.actions?.map((action, j) => {
          return {
            actionId: action.actionId,
            lawId: law.index,
            fulfilledAt: action.fulfilledAt,
            role: law.conditions?.allowedRole
          }
        })
      }).flat()
      setTempActions(actionArray as unknown as {actionId: string, lawId: bigint, fulfilledAt: bigint, role: bigint}[])
    }
  }, [powers])

  // console.log("@Logs: waypoint 0", {tempActions})
  let fulfilledActions: TempAction[] = tempActions.filter((action): action is TempAction => action !== undefined)
  fulfilledActions = fulfilledActions.sort((a, b) => Number(b?.fulfilledAt) - Number(a?.fulfilledAt))

  useEffect(() => {
    if (fulfilledActions) {
      fetchTimestamps(fulfilledActions.map((action) => action.fulfilledAt as bigint), chainId)
    }
  }, [fulfilledActions])

  useEffect(() => {
    if (actionData) {
      setAction(actionData)
      router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${Number(actionData.lawId)}`)
    }
  }, [actionData])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden"> 
      <div className="w-full border-b border-slate-300 p-2 bg-slate-100">
      <div className="w-full flex flex-row gap-6 items-center justify-between">
        <div className="text-left text-sm text-slate-600">
          Latest executions
        </div> 
        <div className="flex flex-row gap-2">
          <button
            onClick={() => {onRefresh()}}
            className={`w-full h-full flex justify-center items-center py-1`}  
          >
            <ArrowPathIcon 
              className="w-4 h-4 text-slate-800 aria-selected:animate-spin"
              aria-selected={status == "pending"}
            />
          </button>
          <button
            onClick={() => 
              { 
                router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws`)
              }
            }>
           <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
          </button>
        </div>
        </div>
      </div>
       {
        tempActions.length > 0 ? 
          <div className="w-full h-fit lg:max-h-80 max-h-56 flex flex-col justify-start items-center overflow-hidden">
           <div className="w-full overflow-x-auto overflow-y-auto">
            <table className="w-full table-auto text-sm">
            <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
            <tr className="w-full text-xs font-light text-left text-slate-500">
                <th className="px-2 py-3 font-light w-32"> Date </th>
                <th className="px-2 py-3 font-light w-auto"> Law </th>
                <th className="px-2 py-3 font-light w-24"> Action ID </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
          {
            fulfilledActions?.map((action: TempAction, i) => {
              const law = powers?.laws?.find(law => Number(law.index) == Number(action.lawId))
              return (
                law && 
                <tr
                  key={i}
                  className="text-sm text-left text-slate-800"
                >
                  {/* Executed at */}
                  <td className="px-2 py-3 w-32">
                    <a
                      href="#"
                      onClick={e => { e.preventDefault(); fetchActionData(action, powers as Powers); }}
                      className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                    >
                      {(() => {
                        // Ensure consistent block number format for lookup
                        const fulfilledAtBlock = typeof action.fulfilledAt === 'bigint' 
                          ? action.fulfilledAt 
                          : BigInt(action.fulfilledAt as unknown as string)
                        
                        const timestampData = timestamps.get(`${chainId}:${fulfilledAtBlock}`)
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
                  
                  {/* Law */}
                  <td className="px-2 py-3 w-auto">
                    <div className="truncate text-slate-500 text-xs">
                      {shorterDescription(law.nameDescription, "short")}
                    </div>
                  </td>
                  
                  {/* Action ID */}
                  <td className="px-2 py-3 w-24">
                    <div className="truncate text-slate-500 text-xs font-mono">
                      {action.actionId.toString()}
                    </div>
                  </td>
                </tr>
              )
            }
          )}
        </tbody>
        </table>
           </div>
          </div>
      :
      <div className = "w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
        No recent executions found
      </div>
    }
    </div>
  )
} 