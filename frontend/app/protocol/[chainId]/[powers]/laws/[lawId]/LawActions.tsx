import { Status, Powers } from "@/context/types";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useBlocks } from "@/hooks/useBlocks";
import { ArrowUpRightIcon, ArrowPathIcon } from "@heroicons/react/24/outline";

// Helper function to truncate addresses, preferring ENS names
const truncateAddress = (address: string | undefined): string => {
  if (!address) return 'Unknown'
  if (address.length < 10) return address
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}
 
type LawActionsProps = {
  roleId: bigint; 
  powers: Powers | undefined;
  status: Status;
  onRefresh?: () => void;
};

export const LawActions = ({roleId, powers, status, onRefresh}: LawActionsProps) => {
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const router = useRouter()
  const [isRefreshing, setIsRefreshing] = useState(false) 

  const lawActions = powers?.laws?.find(law => law.index == roleId)?.actions
  // console.log('@LawActions: lawActions', lawActions)

  const handleSelectAction = (actionId: string) => {
    router.push(`/protocol/${chainId}/${powers?.contractAddress}/actions/${actionId}`)
  }

  useEffect(() => {
    if (lawActions) {
      const blocks = lawActions.map(action => action.fulfilledAt)
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks as bigint[], chainId)
      }
    }
  }, [lawActions, chainId])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden" help-nav-item="latest-executions">
      <div
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600">
            Latest actions
          </div> 
          <div className="flex flex-row gap-2 items-center">
            <button
              className="p-1 hover:bg-slate-200 rounded transition-colors"
              onClick={() => {
                if (onRefresh) {
                  onRefresh()
                }
              }}
            >
              {isRefreshing ? (
                <ArrowPathIcon
                  className="w-4 h-4 text-slate-800 animate-spin"
                />
              ) : (
                <ArrowPathIcon
                  className="w-4 h-4 text-slate-800"
                />
              )}
            </button>
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
            />
          </div>
        </div>
      </div>
      
    {
        lawActions && lawActions?.length > 0 ?  
          <div className="w-full h-fit lg:max-h-80 max-h-56 flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="px-2 py-3 font-light w-32"> Date </th>
                    <th className="px-2 py-3 font-light w-24"> Executioner </th>
                    <th className="px-2 py-3 font-light w-24"> Action ID </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {lawActions.map((action, index) => (
                      <tr
                        key={index}
                        className="text-sm text-left text-slate-800"
                      >
                        {/* Executed at */}
                        <td className="px-2 py-3 w-32">
                          <a
                            href="#"
                            onClick={e => { e.preventDefault(); handleSelectAction(action.actionId); }}
                            className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-blue-800 cursor-pointer"
                          >
                            {(() => {
                              // Ensure consistent block number format for lookup
                              const executedAtBlock = typeof action.fulfilledAt === 'bigint' 
                                ? action.fulfilledAt 
                                : BigInt(action.fulfilledAt as unknown as string)
                              
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
                      
                        {/* Executioner */}
                        <td className="px-2 py-3 w-24">
                          <div className="truncate text-slate-500 text-xs font-mono">
                            {truncateAddress(action.caller)}
                          </div>
                        </td>

                        {/* Action ID */}
                          <td className="px-2 py-3 w-24">
                          <div className="truncate text-slate-500 text-xs font-mono">
                            {action.actionId.toString()}
                          </div>
                        </td>
                      </tr>
                    ))
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
  )
}