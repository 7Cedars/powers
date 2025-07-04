"use client"

import { usePrivy } from "@privy-io/react-auth";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { bigintToRole } from "@/utils/bigintTo";
import { GetBlockReturnType } from "@wagmi/core";
import { toFullDateFormat, toEurTimeFormat } from "@/utils/toDates";
import { Powers, Status } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect } from "react";
import { Button } from "@/components/Button";
import { parseRole } from "@/utils/parsers";

type MyRolesProps = {
  hasRoles: {role: bigint, since: bigint}[]; 
  authenticated: boolean; 
  powers: Powers | undefined;
  status: Status;
}

export function MyRoles({hasRoles, authenticated, powers, status}: MyRolesProps ) {
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.since != 0n)
  const { chainId } = useParams<{ chainId: string }>()
  const hasRolesSince = myRoles.map(role => BigInt(role.since))
  const { timestamps, fetchTimestamps } = useBlocks()

  useEffect(() => {
    if (authenticated) {
      const blocks = hasRolesSince
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks, chainId)
      }
    }
  }, [authenticated, hasRolesSince, chainId])

  // Add public role to display
  const allRoles = [
    { role: 0n, since: 0n }, // Public role
    ...myRoles
  ];

  const handleRoleClick = (role: {role: bigint, since: bigint}) => {
    router.push(`/${chainId}/${powers?.contractAddress}/roles`)
  }

  return (
    <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md lg:max-w-80 overflow-hidden">
      <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
        <button
          onClick={() => router.push(`/${chainId}/${powers?.contractAddress}/roles`) } 
          className="w-full border-b border-slate-300 p-2 bg-slate-100"
        >
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600 w-44">
            My roles
          </div> 
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
              />
          </div>
        </button>
        
        {authenticated ? 
          <div className="w-full h-fit lg:max-h-48 max-h-36 flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="px-2 py-3 font-light w-auto"> Role </th>
                    <th className="px-2 py-3 font-light w-40"> Since </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {allRoles.map((role: {role: bigint, since: bigint}, i) => (
                    <tr
                      key={i}
                      className="text-sm text-left text-slate-800"
                    >
                      {/* Role Name */}
                      <td className="px-2 py-3 w-auto">
                        <div className="text-xs text-slate-600">
                          {role.role === 0n ? 'Public' : (powers ? bigintToRole(role.role, powers) : 'Loading...')}
                        </div>
                      </td>
                      
                      {/* Since Date */}
                      <td className="px-2 py-3 w-40">
                        <div className="text-xs text-slate-500">
                          {role.role === 0n ? (
                            'Always'
                          ) : (
                            (() => {
                              const timestampData = timestamps.get(`${chainId}:${role.since}`)
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
                            })()
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
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
