'use client'

import { setAction } from "@/context/store";
import { Law, Powers, Status, LawExecutions, Action } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { GetBlockReturnType } from "@wagmi/core";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect, useState } from "react";
import { Button } from "@/components/Button";
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

type TempAction = {lawId: bigint, actionId: bigint, executedAt: bigint, role: bigint}

type LogsProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  powers: Powers | undefined;
  status: Status;
}

export function Logs({ hasRoles, authenticated, powers, status}: LogsProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { fetchActionData, actionData, status: statusAction } = useAction()
  const [tempActions, setTempActions] = useState<TempAction[]>([])

  useEffect(() => {
    if (powers?.executedActions) {
      const actionArray = powers.executedActions.map((lawActions: LawExecutions, i) => {
        return lawActions.actionsIds.map((actionId, j) => {
          return {
            lawId: BigInt(i + 1),
            actionId: actionId,
            executedAt: lawActions.executions[j],
            role: powers?.laws?.[i]?.conditions?.allowedRole
          }
        })
      }).flat()
      setTempActions(actionArray as unknown as {lawId: bigint, actionId: bigint, executedAt: bigint, role: bigint}[])
    }
  }, [powers])

  console.log("@Logs: waypoint 0", {tempActions})
  let executedActions: TempAction[] = tempActions.filter((action): action is TempAction => action !== undefined)
  executedActions = executedActions.sort((a, b) => Number(b?.executedAt) - Number(a?.executedAt))

  useEffect(() => {
    if (executedActions) {
      fetchTimestamps(executedActions.map((action) => action.executedAt as bigint), chainId)
    }
  }, [executedActions])

  const handleSelectAction = (action: TempAction) => {
    fetchActionData(BigInt(action.actionId), powers as Powers)
    router.push(`/${chainId}/${powers?.contractAddress}/laws/${Number(action.lawId)}`)
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden"> 
      <button
        onClick={() => 
          { 
            router.push(`/${chainId}/${powers?.contractAddress}/laws`)
          }
        } 
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between">
        <div className="text-left text-sm text-slate-600">
          Latest executions
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {
        powers?.executedActions && powers?.executedActions.length > 0 ? 
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
            executedActions?.map((action: TempAction, i) => {
              const law = powers?.laws?.find(law => Number(law.index) == Number(action.lawId))
              return (
                law && 
                <tr
                  key={i}
                  className="text-sm text-left text-slate-800"
                >
                  {/* Executed at */}
                  <td className="px-2 py-3 w-32">
                      <Button
                        showBorder={true}
                        role={parseRole(law.conditions?.allowedRole || 0n)}
                        onClick={() => handleSelectAction(action)}
                        align={0}
                        selected={true}
                        filled={false}
                        size={0}
                      > 
                        <div className="text-xs whitespace-nowrap py-1 px-1">
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
                        </div>
                      </Button>
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