"use client";

import React, { useCallback, useEffect, useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useParams } from "next/navigation";
import { Status, Powers } from "@/context/types";
import { parseChainId } from "@/utils/parsers";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { LoadingBox } from "@/components/LoadingBox";
import { bigintToRole } from "@/utils/bigintTo";
import { useChains } from "wagmi";

export function MemberList({powers, roleId, status: statusPowers}: {powers: Powers | undefined, roleId: bigint, status: Status}) {
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains();
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [members, setMembers] = useState<`0x${string}`[]>([])

  console.log("@MemberList: ", {powers, roleId, status, error, chainId})
  const roleName = powers ? bigintToRole(roleId, powers) : "Loading..."
  const blockExplorerUrl = chains.find(chain => chain.id === parseInt(chainId))?.blockExplorers?.default.url;

  const fetchRoleHolders = useCallback(
    async (roleId: bigint) => {
      setError(null)
      setStatus("pending")

      if (powers) {
        try {
          const result = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getRoleHolders',
            args: [roleId],
            chainId: parseChainId(chainId)
          })
          console.log("@fetchRoleHolders: ", {result})

          const membersParsed = result as `0x${string}`[]
          setMembers(membersParsed)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          setError(error)
          console.error("Error fetching role holders:", error)
        }
      }
    }, [powers, chainId])

  useEffect(() => {
    if (powers && roleId != undefined) {
      fetchRoleHolders(roleId)
    }
  }, [powers, roleId, fetchRoleHolders])

  const handleRefresh = () => {
    console.log("@handleRefresh: ", {powers, roleId})
    if (powers && roleId != undefined) {
      fetchRoleHolders(roleId)
    }
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">

      {/* Table content */}
      {status == 'pending' ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        : 
        members && members.length > 0 ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-16"> # </th>
                    <th className="px-2 py-3 font-light w-auto"> Address </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {members?.map((member, i) =>
                    <tr key={i} className="text-xs text-left text-slate-800 hover:bg-slate-100 transition-colors">
                      <td className="ps-4 px-2 py-3 w-16">
                        <div className="text-slate-500 text-xs">
                          {i + 1}
                        </div>
                      </td>
                      
                      <td className="px-2 py-3 w-auto">
                        {blockExplorerUrl ? (
                          <a
                            href={`${blockExplorerUrl}/address/${member}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-slate-800 font-mono text-xs hover:text-blue-600 hover:underline transition-colors"
                          >
                            {member}
                          </a>
                        ) : (
                          <div className="text-slate-800 font-mono text-xs">
                            {member}
                          </div>
                        )}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        :
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No members found
        </div>
      }
    </div>
  );
}

