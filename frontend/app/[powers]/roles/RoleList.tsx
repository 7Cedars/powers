"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/Button";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Roles, Status, Powers } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { setRole } from "@/context/store"
import { bigintToRole } from "@/utils/bigintToRole";

export function RoleList({powers}: {powers: Powers | undefined}) {
  const router = useRouter();
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roles, setRoles ] = useState<Roles[]>([])

  console.log("@RoleList: ", {powers, roles})

  const fetchRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      console.log("fetch role triggered", {roleIds})
      let roleId: bigint; 
      let rolesFetched: Roles[] = []; 

      setError(null)
      setStatus("pending")

      if (publicClient && powers) {
        try {
          for await (roleId of roleIds) {
            console.log("@fetchRoleHolders: ", {roleId}) 
            if (Number(roleId) < 4294967296) { 
            const fetchedRoleHolders = await readContract(wagmiConfig, {
              abi: powersAbi,
              address: powers?.contractAddress as `0x${string}`,
              functionName: 'getAmountRoleHolders', 
              args: [roleId]
              })
              console.log("@fetchRoleHolders, waypoint 1 ", {fetchedRoleHolders})
              const laws = powers?.laws?.filter(law => law.conditions.allowedRole == BigInt(roleId))
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
      fetchRoleHolders(powers.roles || [])
    }
  }, [powers, fetchRoleHolders])

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full min-h-16 flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Roles
        </div>
        {powers && 
          <button 
            className="w-fit h-fit p-1 rounded-md border-slate-500"
            onClick = {() => fetchRoleHolders(powers?.roles || [])}
            >
              <ArrowPathIcon
                className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
                aria-selected={status == 'pending'}
                />
          </button>
        }
      </div>
      {/* table laws  */}
      <table className="w-full table-auto border border-t-0">
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Role </th>
                <th className="font-light text-center"> Holders </th>
                <th className="font-light text-right pe-8"> Laws </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200 border-t-0 border-slate-200 rounded-b-md">
          {
            powers && roles && roles?.map((role: Roles, i: number) =>
              <tr key = {i}>
                <td className="flex flex-col w-full max-w-60 min-w-40 justify-center items-start text-left rounded-bl-md px-4 py-3 w-fit">
                 <Button
                    showBorder={true}
                    selected={true}
                    filled={true}
                    role={parseRole(BigInt(role.roleId))}
                    onClick={() => {
                      router.push(`/${powers?.contractAddress}/roles/${role.roleId}`);
                    }}
                    align={0}
                  >
                  {bigintToRole(role.roleId, powers)} 
                  </Button>
                </td>
                <td className="pe-4 text-left text-slate-500 text-center">{role.roleId == 4294967295n ? '-' : role.holders}</td>
                <td className="pe-4 text-right pe-8 text-slate-500">{role.laws?.length} </td>
              </tr> 
            )
          }
        </tbody>
      </table>
    </div>
  );
}
