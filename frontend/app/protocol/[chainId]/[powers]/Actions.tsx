'use client'

import { Action, Law, Powers, Status } from "@/context/types";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { shorterDescription } from "@/utils/parsers";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect } from "react";
import { setAction } from "@/context/store";

type ActionsProps = {
  powers: Powers | undefined;
  status: Status;
  onRefresh: () => void;
}

export function Actions({ powers, status, onRefresh}: ActionsProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()

  const allActions = powers?.laws && powers?.laws?.length > 0 ? powers?.laws?.flatMap(law => law.actions) : []
  const sortedActions = allActions.sort((a, b) => Number(b?.fulfilledAt) - Number(a?.fulfilledAt)).filter((action): action is Action => action !== undefined)
  const allTimestamps = Array.from(new Set(
    sortedActions.flatMap(action => [
      action?.requestedAt,
      action?.proposedAt, 
      action?.fulfilledAt,
      action?.cancelledAt
    ].filter((timestamp): timestamp is bigint => 
      timestamp !== undefined && 
      timestamp !== null
    ))
  ))

  useEffect(() => {
    if (sortedActions) {
      fetchTimestamps(allTimestamps, chainId)
    }
  }, [sortedActions, chainId, fetchTimestamps])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden"> 
      <div className="w-full border-b border-slate-300 p-2 bg-slate-100">
      <div className="w-full flex flex-row gap-6 items-center justify-between">
        <div className="text-left text-sm text-slate-600">
          Latest actions
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
        sortedActions.length > 0 ? 
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
            sortedActions?.map((action: Action, i) => {
              const law = powers?.laws?.find(law => Number(law.index) == Number(action.lawId))
              if (!law) return null
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
                      onClick={e => { 
                        setAction(action) 
                        e.preventDefault(); 
                        router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${Number(action.lawId)}`)
                      }}
                      className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                    >
                      {(() => {
                        // Get the earliest non-zero timestamp between proposed and requested
                        let targetBlock: bigint | undefined;
                        const proposedAt = action.proposedAt 
                        const requestedAt = action.requestedAt 

                        if (proposedAt && requestedAt && proposedAt > 0n && requestedAt > 0n) {
                          targetBlock = proposedAt < requestedAt ? proposedAt : requestedAt;
                        } else if (proposedAt && proposedAt > 0n) {
                          targetBlock = proposedAt;
                        } else if (requestedAt && requestedAt > 0n) {
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