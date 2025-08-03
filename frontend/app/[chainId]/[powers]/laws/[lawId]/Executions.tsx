import { Status, LawExecutions, Powers } from "@/context/types";
import { parseActionData } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";
import { LoadingBox } from "@/components/LoadingBox";
import { readContract } from "wagmi/actions";
import { getEnsName } from "@wagmi/core";
import { powersAbi } from "@/context/abi";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useBlocks } from "@/hooks/useBlocks";
import { useAction } from "@/hooks/useAction";
import { ArrowUpRightIcon, ArrowPathIcon } from "@heroicons/react/24/outline";
import { setAction, useActionStore } from "@/context/store";

// Helper function to truncate addresses, preferring ENS names
const truncateAddress = (address: string | undefined, ensName: string | null | undefined): string => {
  if (ensName) return ensName
  if (!address) return 'Unknown'
  if (address.length < 10) return address
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

type ExecutionWithCaller = {
  execution: bigint;
  actionId: bigint;
  caller?: `0x${string}`;
  ensName?: string | null;
}

type ExecutionsProps = {
  roleId: bigint;
  lawExecutions: LawExecutions | undefined
  powers: Powers | undefined;
  status: Status;
  onRefresh?: () => void;
};

export const Executions = ({roleId, lawExecutions, powers, status, onRefresh}: ExecutionsProps) => {
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { fetchActionData, data: actionData } = useAction()
  const router = useRouter()
  const [executionsWithCallers, setExecutionsWithCallers] = useState<ExecutionWithCaller[]>([])
  const [isRefreshing, setIsRefreshing] = useState(false)
  const action = useActionStore() 

  // console.log('@Executions: action', action)

  useEffect(() => {
    if (lawExecutions) {
      const blocks = lawExecutions.executions
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks, chainId)
      }
    }
  }, [lawExecutions, chainId])

  const fetchCallers = async () => {
    try {
      if (!lawExecutions?.executions || !lawExecutions?.actionsIds || !powers?.contractAddress) return

      setIsRefreshing(true)
      const executionsData = await Promise.all(
        lawExecutions?.executions.map(async (execution, index) => {
          const actionId = lawExecutions?.actionsIds[index]
          try {
            const actionData = await readContract(wagmiConfig, {
              abi: powersAbi,
              address: powers?.contractAddress,
              functionName: 'getActionData',
              args: [actionId]
            }) 
            const parsedActionData = parseActionData(actionData as unknown as unknown[])
             
             // Try to get ENS name for the caller
             let ensName: string | null = null
             try {
               ensName = await getEnsName(wagmiConfig, {
                 address: parsedActionData.caller as `0x${string}`
               })
             } catch (ensError) {
               // ENS lookup failed, continue without ENS name
               // console.log('ENS lookup failed for:', parsedActionData.caller)
             }
             return {
               execution,
               actionId,
               caller: parsedActionData.caller,
               ensName
             }
          } catch (error) {
            console.error('Error fetching caller for action:', actionId, error)
            return {
              execution,
              actionId,
              caller: undefined,
              ensName: null
            }
          }
        })
      )
      setExecutionsWithCallers(executionsData)
      setIsRefreshing(false)
    } catch (error) {
      console.error('Error fetching callers:', error)
      setIsRefreshing(false)
    }
  }

  // Fetch caller information for each execution
  useEffect(() => {
    if (lawExecutions?.executions && lawExecutions?.actionsIds && powers?.contractAddress) {
      fetchCallers()
    }
  }, [lawExecutions, powers?.contractAddress])

  const handleSelectAction = (actionId: bigint) => {
    fetchActionData(actionId, powers as Powers)
  }

  useEffect(() => {
    if (actionData) {
      setAction({...actionData, upToDate: true})
    }
  }, [actionData])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      <div
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600">
            Latest executions
          </div> 
          <div className="flex flex-row gap-2 items-center">
            <button
              className="p-1 hover:bg-slate-200 rounded transition-colors"
              onClick={() => {
                fetchCallers()
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
        lawExecutions?.executions && lawExecutions?.executions?.length > 0 ?  
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
                  {
                    (executionsWithCallers.length > 0 ? executionsWithCallers : 
                     lawExecutions.executions.map((execution, index) => ({
                       execution,
                       actionId: lawExecutions.actionsIds[index],
                       caller: undefined,
                       ensName: null
                     }))
                    ).map((executionData, index: number) => (
                      <tr
                        key={index}
                        className="text-sm text-left text-slate-800"
                      >
                        {/* Executed at */}
                        <td className="px-2 py-3 w-32">
                          <a
                            href="#"
                            onClick={e => { e.preventDefault(); handleSelectAction(executionData.actionId); }}
                            className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-blue-800 cursor-pointer"
                          >
                            {(() => {
                              // Ensure consistent block number format for lookup
                              const executedAtBlock = typeof executionData.execution === 'bigint' 
                                ? executionData.execution 
                                : BigInt(executionData.execution as unknown as string)
                              
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
                            {truncateAddress(executionData.caller, executionData.ensName)}
                          </div>
                        </td>

                        {/* Action ID */}
                          <td className="px-2 py-3 w-24">
                          <div className="truncate text-slate-500 text-xs font-mono">
                            {executionData.actionId.toString()}
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