"use client"

import { usePrivy } from "@privy-io/react-auth";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { bigintToRole } from "@/utils/bigintToRole";
import { GetBlockReturnType } from "@wagmi/core";
import { toFullDateFormat } from "@/utils/toDates";
import { Powers } from "@/context/types";

type MyRolesProps = {
  hasRoles: {role: bigint, since: bigint, blockData: GetBlockReturnType}[]; 
  authenticated: boolean; 
  powers: Powers | undefined;
}

export function MyRoles({hasRoles, authenticated, powers}: MyRolesProps ) {
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.since != 0n)

  return (
    <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
      <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
        <button
          onClick={() => router.push('/roles') } 
          className="w-full border-b border-slate-300"
        >
        <div className="w-full flex flex-row gap-6 items-center justify-between p-2 ps-4">
          <div className="text-left text-sm text-slate-600 w-52">
            My roles
          </div> 
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
              />
          </div>
        </button>
       {
      authenticated ? 
      <div className = "w-full flex flex-col gap-1 justify-center items-center lg:max-h-48 max-h-36 overflow-y-scroll divider-slate-300 divide-y">
           <div className ={`w-full p-1`}>
            <div className ={`w-full flex flex-row text-sm text-slate-600 justify-center items-center rounded-md ps-4 py-2`}>
              <div className = "w-full flex flex-row justify-start items-center text-left">
              Public
              </div>
              <div className = "w-full flex flex-row justify-end items-center text-right">
                {/* Since: n/a */}
              </div>
            </div>
          </div>
        {
        powers && myRoles?.map((role: {role: bigint, since: bigint, blockData: GetBlockReturnType}, i) => 
            <div className ={`w-full flex flex-row text-sm text-slate-600 justify-center items-center rounded-md ps-4 py-3 p-1`} key = {i}>
              <div className = "w-full flex flex-row justify-start items-center text-left">
                {/* need to get the timestamp.. */}
                {
                  bigintToRole(role.role, powers)
                }
              </div>
              <div className = "grow w-full min-w-40 flex flex-row justify-end items-center text-right pe-4">
                Since: {toFullDateFormat(Number(role.blockData.timestamp))} 
              </div>
              </div>
            )
        }
      </div>
  : 
  <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
    Connect your wallet to see your roles. 
  </div>
  }
  </div>
  </div>
  )
}
