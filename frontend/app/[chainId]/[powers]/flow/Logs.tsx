'use client'

import { setAction } from "@/context/store";
import { Law, Powers, Status, LawExecutions } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { toFullDateFormat } from "@/utils/toDates";
import { GetBlockReturnType } from "@wagmi/core";
import { parseRole } from "@/utils/parsers";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect } from "react";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

type LogsProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  powers: Powers | undefined;
  status: Status;
}

type ExecutionAndLaw = {
  execution: any; // You might want to define a proper Execution type
  law: Law; 
}

export function Logs({ hasRoles, authenticated, powers, status}: LogsProps) {
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.role > 0).map(hasRole => hasRole.role)
  const { chainId } = useParams<{ chainId: string }>()
  const { data: blocks, fetchBlocks } = useBlocks()

  // Get recent executions - you'll need to implement this based on your data structure
  // This is a placeholder - adjust based on how executions are stored in your Powers type
  const recentExecutions = powers?.activeLaws?.slice(0, 5).map((law: Law) => {
    // This is a placeholder - replace with actual execution data
    return {
      execution: {
        lawId: law.index,
        executedAt: Date.now() - Math.random() * 86400000, // Random recent time
        caller: "0x1234...5678", // Placeholder
        status: "success" // Placeholder
      },
      law: law
    } as ExecutionAndLaw
  }) || []

  useEffect(() => {
    if (recentExecutions && recentExecutions.length > 0) {
      // fetchBlocks for execution timestamps - adjust based on your data structure
      // fetchBlocks(recentExecutions.map(item => BigInt(item.execution.executedAt)), chainId)
    }
  }, [recentExecutions, chainId, fetchBlocks])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-68"> 
      <button
        onClick={() => 
          { 
            router.push(`/${chainId}/${powers?.contractAddress}/flow/laws`)
          }
        } 
        className="w-full border-b border-slate-300 p-2"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
        <div className="text-left text-sm text-slate-600 w-44">
          Latest executions
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {
        authenticated ?
        recentExecutions && recentExecutions.length > 0 ? 
          <div className = "w-full h-fit lg:max-h-48 max-h-32 flex flex-col gap-2 justify-start items-center overflow-x-scroll p-2 px-1">
          {
            recentExecutions?.slice(0, 3).map((item: ExecutionAndLaw, i) => 
                <div className = "w-full px-2" key={i}>
                  <button 
                    className = {`w-full h-full disabled:opacity-50 rounded-md border ${roleColour[parseRole(item.law.conditions?.allowedRole || 0n)]} text-sm p-1 px-2`} 
                    onClick={
                      () => {
                        setAction({
                          uri: "", // Set based on execution data
                          callData: "0x0" as `0x${string}`, // Set based on execution data  
                          nonce: "0", // Set based on execution data
                          lawId: item.execution.lawId,
                          caller: item.execution.caller,
                          dataTypes: item.law.params?.map(param => param.dataType),
                          upToDate: true
                        })
                        router.push(`/${chainId}/${powers?.contractAddress}/logs`)
                        }
                      }>
                      <div className ="w-full flex flex-col gap-1 text-sm text-slate-600 justify-center items-center">
                        <div className = "w-full flex flex-row justify-between items-center text-left">
                          <p> Status: </p> 
                          <p className="capitalize"> {item.execution.status} </p>
                        </div>

                        <div className = "w-full flex flex-row justify-between items-center text-left">
                          <p> Law: </p> 
                          <p> {item.law.nameDescription?.length && item.law.nameDescription?.length > 24 ? item.law.nameDescription?.substring(0, 24) + "..." : item.law.nameDescription || `#${item.law.index}`}  </p>
                        </div>
                      </div>
                  </button>
                </div>
            )
          }
        </div>
      :
      <div className = "w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
        No recent executions found
      </div>
      :   
      <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
        Connect your wallet to see execution logs. 
      </div>
    }
    </div>
  )
} 