"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/Button";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useRouter, useParams } from "next/navigation";
import { Roles, Status, Powers } from "@/context/types";
import { parseChainId, parseRole } from "@/utils/parsers";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { setRole } from "@/context/store"
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import { getPublicClient } from "wagmi/actions";

export function RoleList({powers, status: statusPowers, onRefresh}: {powers: Powers | undefined, status: Status, onRefresh?: () => void}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roles, setRoles ] = useState<Roles[]>([])
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })

  // console.log("@RoleList: ", {powers, roles})

  const fetchAmountRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      // console.log("fetch role triggered", {roleIds})
      let roleId: bigint; 
      let rolesFetched: Roles[] = []; 

      setError(null)
      setStatus("pending")

      // if (publicClientArbitrumSepolia || publicClientSepolia && powers) {
      if (powers) {
        try {
          for await (roleId of roleIds) {
            // console.log("@fetchRoleHolders: ", {roleId}) 
            if (Number(roleId) < 429496729600000) { 
            const fetchedRoleHolders = await readContract(wagmiConfig, {
              abi: powersAbi,
              address: powers?.contractAddress as `0x${string}`,
              functionName: 'getAmountRoleHolders', 
              args: [roleId]
              })
              // console.log("@fetchRoleHolders, waypoint 1 ", {fetchedRoleHolders})
              const laws = powers?.laws?.filter(law => law.conditions?.allowedRole == BigInt(roleId))
              rolesFetched.push({roleId, holders: Number(fetchedRoleHolders), laws})
            }
          }
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
        const rolesSorted = rolesFetched.sort((a: Roles, b: Roles) => a.roleId > b.roleId ? 1 : -1)
        setRoles(rolesSorted)
        setStatus("success")
      }
  }, [powers]) 

  useEffect(() => {
    if (powers) {
      fetchAmountRoleHolders(powers.roles || [])
    }
  }, [powers, fetchAmountRoleHolders])

  const handleRefreshRoles = () => {
    if (powers) {
      fetchAmountRoleHolders(powers.roles || [])
    }
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Header - matching LogsList.tsx structure */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-4">
        <div className="text-slate-900 text-center font-bold text-lg">
          Roles
        </div>
        <div className="flex flex-row gap-2 items-center">
          <div className="w-8 h-8">
            <Button
              size={0}
              showBorder={true}
              onClick={handleRefreshRoles}
            >
              <ArrowPathIcon className={`w-5 h-5 ${status === 'pending' ? 'animate-spin' : ''}`} />
            </Button>
          </div>
          {onRefresh && (
            <div className="w-8 h-8">
              <Button
                size={0}
                showBorder={true}
                onClick={onRefresh}
              >
                <ArrowPathIcon className="w-5 h-5" />
              </Button>
            </div>
          )}
        </div>
      </div>

      {/* Table content - matching LogsList.tsx structure */}
      {statusPowers == "pending" || status === "pending" ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        :
        roles && roles.length > 0 ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-auto"> Role </th>
                    <th className="px-2 py-3 font-light w-20"> Holders </th>
                    <th className="px-2 py-3 font-light w-16"> Laws </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    roles?.map((role: Roles, i: number) =>
                      <tr key={i} className="text-xs text-left text-slate-800">
                        {/* Role */}
                        <td className="ps-4 px-2 py-3 w-auto">
                          <Button
                            showBorder={true}
                            selected={true}
                            filled={false}
                            role={parseRole(BigInt(role.roleId))}
                            onClick={() => {
                              // router.push(`/${chainId}/${powers?.contractAddress}/roles/${role.roleId}`); // disabled for now
                            }}
                            align={0}
                            size={0}
                          >
                            <div className="text-xs py-1 px-1">
                              {bigintToRole(role.roleId, powers as Powers)} 
                            </div>
                          </Button>
                        </td>
                        
                        {/* Holders */}
                        <td className="px-2 py-3 w-20">
                          <div className="text-slate-500 text-xs text-center">
                            {role.roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? '-' : role.holders}
                          </div>
                        </td>
                        
                        {/* Laws */}
                        <td className="px-2 py-3 w-16">
                          <div className="text-slate-500 text-xs text-center">
                            {role.laws?.length}
                          </div>
                        </td>
                      </tr>
                    )
                  }
                </tbody>
              </table>
            </div>
          </div>
        :
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No roles found
        </div>
      }
    </div>
  );
}
