"use client"

import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { bigintToRole } from "@/utils/bigintTo";
import { Powers, Status } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import DynamicThumbnail from "@/components/DynamicThumbnail";
import { useCallback, useEffect, useState } from "react";
import { parseChainId } from "@/utils/parsers";
import { powersAbi } from "@/context/abi";
import { readContracts } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";

type RolesProps = {
  powers: Powers | undefined;
  status: Status;
}

type RoleData = {
  roleId: bigint;
  holders: number;
}

export function Roles({powers, status: statusPowers}: RolesProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus] = useState<Status>('idle')
  const [roles, setRoles] = useState<RoleData[]>([])

  const fetchRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      setStatus("pending")

      if (powers) {
        try {
          // Filter out roleIds that are too large
          const validRoleIds = roleIds.filter(roleId => Number(roleId) < 429496729600000)
          
          if (validRoleIds.length === 0) {
            setRoles([])
            setStatus("success")
            return
          }

          // Build multicall contracts array
          const contracts = validRoleIds.map((roleId) => ({
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getAmountRoleHolders' as const,
            args: [roleId] as [bigint],
            chainId: parseChainId(chainId)
          }))

          // Fetch all role holder counts
          const results = await readContracts(wagmiConfig, {
            allowFailure: false,
            contracts
          }) as bigint[]

          // Build the roles array
          const rolesFetched: RoleData[] = validRoleIds.map((roleId, index) => ({
            roleId,
            holders: Number(results[index])
          }))

          // Sort roles by roleId
          const rolesSorted = rolesFetched.sort((a, b) => a.roleId > b.roleId ? 1 : -1)
          setRoles(rolesSorted)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          console.error("Error fetching role holders:", error)
        }
      }
    }, [powers, chainId])

  useEffect(() => {
    if (powers?.roles) {
      fetchRoleHolders(powers.roles)
    }
  }, [powers?.roles, fetchRoleHolders])

  // Add public role to display
  const allRoles = [
    { roleId: 0n, holders: 0 }, // Public role
    ...roles
  ];

  return (
    <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden">
      <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
        <button
          onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/roles`) } 
          className="w-full border-b border-slate-300 p-2 bg-slate-100"
        >
          <div className="w-full flex flex-row gap-6 items-center justify-between">
            <div className="text-left text-sm text-slate-600 w-32">
              Roles
            </div> 
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
            />
          </div>
        </button>
        
        {status === 'pending' ? 
          <div className="w-full flex flex-col justify-center items-center p-6">
            <LoadingBox /> 
          </div>
        : 
        allRoles && allRoles.length > 0 ? 
          <div className="w-full h-fit lg:max-h-56 max-h-48 flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full h-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {allRoles.map((role, i) => (
                    <tr
                      key={i}
                      className="text-sm text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                      onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/roles/${role.roleId}`)}
                    >
                      <td className="ps-2 py-2 w-auto">
                        <div className="flex flex-row items-center gap-2">
                          <div className="flex-shrink-0 w-10 h-10 rounded-lg overflow-hidden">
                            <DynamicThumbnail
                              roleId={role.roleId === 0n ? 'public' : role.roleId}
                              powers={powers as Powers}
                              size={40}
                              className="object-cover w-10 h-10"
                            />
                          </div>
                          <div className="flex flex-col">
                            <div className="font-medium text-sm text-slate-800">
                              {role.roleId === 0n ? 'Public' : bigintToRole(role.roleId, powers as Powers)} 
                            </div>
                            <div className="text-xs text-slate-500">
                              {role.roleId === 0n 
                                ? 'Everyone' 
                                : role.roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n 
                                ? 'Universal' 
                                : `${role.holders} ${role.holders === 1 ? 'holder' : 'holders'}`
                              }
                            </div>
                          </div>
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
            No roles found
          </div>
        }
      </div>
    </div>
  )
}
