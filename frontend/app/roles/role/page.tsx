"use client";

import React, { useCallback, useEffect, useState } from "react";
import {  useOrgStore, useRoleStore } from "@/context/store";
import { useRouter } from "next/navigation";
import { Role, Status } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { parseEventLogs, ParseEventLogsReturnType } from "viem"
import { useChainId } from 'wagmi'
import { supportedChains } from "@/context/chains";
import { bigintToRole } from "@/utils/bigintToRole";

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
  const organisation = useOrgStore();
  const role = useRoleStore();
  const router = useRouter();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roleInfo, setRoleInfo ] = useState<Role[]>()

  const getRolesSet = async () => {
      if (publicClient) {
        try {
          const logs = await publicClient.getContractEvents({ 
            address: organisation.contractAddress,
            abi: powersAbi, 
            eventName: 'RoleSet',
            fromBlock: supportedChain?.genesisBlock,
            args: {
              roleId: role.roleId,
              access: true
            },
          })
          const fetchedLogs = parseEventLogs({
            abi: powersAbi,
            eventName: 'RoleSet',
            logs
          })
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
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
                address: organisation.contractAddress,
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

        setRoleInfo(roles) 
        setStatus("success")
      }, [])
  
    useEffect(() => {
      fetchRoleInfo()
    }, [])

  return (
    <main className={`w-full overflow-hidden pt-20 px-2`}>
      {/* table banner  */}
      <div className={`w-full flex flex-row gap-3 justify-between items-center bg-slate-50 slate-300 mt-2 py-4 px-6 border rounded-t-md ${roleColour[parseRole(BigInt(role.roleId))]} border-b-slate-300`}>
        <div className="text-slate-900 text-center font-bold text-lg">
         {bigintToRole(role.roleId, organisation)}
        </div>
      </div>
      {/* table laws  */}
      <div className={`w-full border ${roleColour[parseRole(BigInt(role.roleId))]} border-t-0 rounded-b-md overflow-scroll`}>
      <table className={`w-full table-auto`}>
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Address / ENS </th>
                <th className="font-light text-right pe-8"> Has Role Since </th>
                {/* <th className="font-light text-right pe-8"> Actions </th>
                <th className="font-light text-right pe-8"> Proposals </th> */}
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
          {
            roleInfo?.map((role: Role, index: number) =>
              <tr className="text-sm text-left text-slate-800 h-16 p-2 overflow-x-scroll" key = {index}>
                <td className="ps-6 pe-4 text-slate-500 min-w-60">{role.account}</td>
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


