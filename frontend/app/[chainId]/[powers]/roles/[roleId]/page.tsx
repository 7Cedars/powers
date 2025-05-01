"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Role, Status, Powers } from "@/context/types";
import { parseChainId, parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { parseEventLogs, ParseEventLogsReturnType } from "viem"
import { supportedChains } from "@/context/chains";
import { bigintToRole } from "@/utils/bigintToRole";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

export default function Page() {
  const { chainId } = useParams<{ chainId: string }>()
  const { powers: addressPowers, roleId } = useParams<{ powers: string, roleId: string }>()  
  const { powers, fetchPowers } = usePowers()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))

  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roleInfo, setRoleInfo ] = useState<Role[]>()

  console.log("@role page: ", {powers, roleInfo})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  const getRolesSet = async () => {
      if (publicClient && roleId) {
        try {
          const logs = await publicClient.getContractEvents({ 
            address: addressPowers as `0x${string}`,
            abi: powersAbi, 
            eventName: 'RoleSet',
            fromBlock: supportedChain?.genesisBlock,
            args: {
              roleId: BigInt(roleId),
              access: true
            },
          })
          const fetchedLogs = parseEventLogs({
            abi: powersAbi,
            eventName: 'RoleSet',
            logs
          })
          console.log("@getRolesSet: ", {fetchedLogs})
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
          console.log("@getRolesSet: ", {fetchedLogsTyped})
          const rolesSet: Role[] = fetchedLogsTyped.map(log => log.args as Role)
          return rolesSet
        } catch (error) {
            setStatus("error") 
            setError(error)
        } 
      }
    }

    const getRoleSince = async (roles: Role[]) => {
        let role: Role; 
        let rolesWithSince: Role[] = []; 
  
        if (publicClient) {
          try {
            for await (role of roles) {
              const fetchedSince = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: addressPowers as `0x${string}`,
                functionName: 'hasRoleSince', 
                args: [role.account, role.roleId]
              })
              rolesWithSince.push({...role, since: fetchedSince as number})
              }
              return rolesWithSince
            } catch (error) {
              setStatus("error") 
              setError(error)
            }
        }
    } 

    const fetchRoleInfo = useCallback(
      async () => {
        setError(null)
        setStatus("pending")

        const rolesSet = await getRolesSet() 
        const roles = rolesSet ? await getRoleSince(rolesSet) : []

        console.log("@fetchRoleInfo: ", {roles, rolesSet})

        setRoleInfo(roles) 
        setStatus("success")
      }, [])
  
    useEffect(() => {
      fetchRoleInfo()
    }, [])

  return (
    <main className={`w-full overflow-hidden pt-20 px-2`}>
      {/* table banner  */}
      <div className={`w-full flex flex-row gap-3 justify-between items-center bg-slate-50 slate-300 mt-2 py-4 px-6 border rounded-t-md ${roleColour[parseRole(BigInt(roleId))]} border-b-slate-300`}>
        <div className="text-slate-900 text-center font-bold text-lg">
         {bigintToRole(BigInt(roleId), powers as Powers)}
        </div>
      </div>
      {/* table laws  */}
      <div className={`w-full border ${roleColour[parseRole(BigInt(roleId))]} border-t-0 rounded-b-md overflow-scroll`}>
      <table className={`w-full table-auto`}>
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Address / ENS </th>
                <th className="font-light text-right pe-8"> Has Role Since </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
          {
            roleInfo?.map((role: Role, index: number) =>
              <tr className="text-sm text-left text-slate-800 h-16 p-2 overflow-x-scroll" key = {index}>
                <td className="ps-6 pe-4 text-slate-500 min-w-60">
                  <a href={`${supportedChain?.blockExplorerUrl}/address/${role.account}`} target="_blank" rel="noopener noreferrer">
                  <div className="flex flex-row gap-1 items-center justify-start">
                    <div className="text-left text-sm text-slate-500 break-all w-fit">
                      {role.account}
                    </div> 
                      <ArrowUpRightIcon
                        className="w-4 h-4 text-slate-500"
                        />
                    </div>
                  </a>
                </td>
                <td className="pe-8 text-right text-slate-500">{role.since}</td>
              </tr> 
            )
          }
        </tbody>
      </table>
      </div>
    </main>
  );
}


