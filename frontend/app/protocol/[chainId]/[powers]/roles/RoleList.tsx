"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { Status, Powers } from "@/context/types";
import { parseChainId } from "@/utils/parsers";
import { powersAbi } from "@/context/abi";
import { readContracts } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import DynamicThumbnail from "@/components/DynamicThumbnail";

// Type definition for role data with holder count and related laws
type Roles = {
  roleId: bigint;
  holders: number;
  laws: unknown[];
}

export function RoleList({powers}: {powers: Powers | undefined, status: Status, onRefresh?: () => void}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus] = useState<Status>('idle') 
  const [roles, setRoles] = useState<Roles[]>([])

  // console.log("@RoleList: ", {powers, roles})

  const fetchAmountRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      // console.log("fetch role triggered", {roleIds}
      setStatus("pending")

      if (powers) {
        try {
          // Filter out roleIds that are too large (> 429496729600000)
          const validRoleIds = roleIds.filter(roleId => Number(roleId) < 429496729600000)
          
          if (validRoleIds.length === 0) {
            setRoles([])
            setStatus("success")
            return
          }

          // Build multicall contracts array for all valid role IDs
          const contracts = validRoleIds.map((roleId) => ({
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getAmountRoleHolders' as const,
            args: [roleId] as [bigint],
            chainId: parseChainId(chainId)
          }))

          // Fetch all role holder counts in a single multicall
          const results = await readContracts(wagmiConfig, {
            allowFailure: false,
            contracts
          }) as bigint[]

          // Build the roles array with holder counts and filtered laws
          const rolesFetched: Roles[] = validRoleIds.map((roleId, index) => {
            const holders = results[index]
            const laws = powers?.laws?.filter(law => law.conditions?.allowedRole == BigInt(roleId)) || []
            return {
              roleId,
              holders: Number(holders),
              laws
            }
          })

          // Sort roles by roleId
          const rolesSorted = rolesFetched.sort((a: Roles, b: Roles) => a.roleId > b.roleId ? 1 : -1)
          setRoles(rolesSorted)
          setStatus("success")
        } catch (error) {
          setStatus("error")  
          console.error("Error fetching role holders:", error)
        }
      }
    }, [powers, chainId]) 

  useEffect(() => {
    if (powers) {
      fetchAmountRoleHolders(powers.roles || [])
    }
  }, [powers, fetchAmountRoleHolders])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">

      {/* Table content - matching AssetList.tsx structure */}
      {status && status == 'pending' ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        : 
        roles && roles.length > 0 ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    roles?.map((role: Roles, i: number) =>
                      <tr 
                        key={i} 
                        className="text-xs text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                        onClick={() => {
                          router.push(`/protocol/${chainId}/${powers?.contractAddress}/roles/${role.roleId}`);
                        }}
                      >
                        <td className="ps-4 py-3 w-auto">
                          <div className="flex flex-row items-center justify-start gap-4">
                            <div className="flex-shrink-0 w-12 h-12 rounded-lg overflow-hidden">
                              <DynamicThumbnail
                                roleId={role.roleId}
                                powers={powers as Powers}
                                size={48}
                                className="object-cover w-12 h-12"
                              />
                            </div>
                            <div className="flex flex-col">
                              <div className="font-semibold text-base text-slate-800">
                                {bigintToRole(role.roleId, powers as Powers)} 
                              </div>
                              <div className="text-sm text-slate-600">
                                {role.roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n 
                                  ? 'Universal role' 
                                  : `${role.holders} ${role.holders === 1 ? 'holder' : 'holders'}`
                                } • {role.laws?.length} {role.laws?.length === 1 ? 'law' : 'laws'}
                              </div>
                            </div>
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
