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
  const { chainId } = useParams<{ chainId: string }>()

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-68"> 
      <button
        onClick={() => 
          { 
            router.push(`/${chainId}/${powers?.contractAddress}/laws`)
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
        powers?.executedActions && powers?.executedActions.length > 0 ? 
          <div className = "w-full h-fit lg:max-h-48 max-h-32 flex flex-col gap-2 justify-start items-center overflow-x-scroll p-2 px-1">
          DATA WILL GO HERE
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