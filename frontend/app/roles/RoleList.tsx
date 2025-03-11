"use client";

import React, { useCallback, useEffect, useState } from "react";
import {  useOrgStore } from "../../context/store";
import { Button } from "@/components/Button";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Roles, Status } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { powersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { setRole } from "@/context/store"
import { useOrganisations } from "@/hooks/useOrganisations";
import { bigintToRole } from "@/utils/bigintToRole";

export function RoleList() {
  const organisation = useOrgStore();
  const { status: statusUpdate, updateOrg } = useOrganisations()
  const router = useRouter();

  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roles, setRoles ] = useState<Roles[]>([])

  const fetchRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      let roleId: bigint; 
      let rolesFetched: Roles[] = []; 
      let lawsFetched: number[]; 

      const roleIdsParsed = roleIds.map(roleId => roleId)

      setError(null)
      setStatus("pending")

      if (publicClient) {
        try {
          for await (roleId of roleIdsParsed) {
            const fetchedRoleHolders = await readContract(wagmiConfig, {
              abi: powersAbi,
              address: organisation.contractAddress,
              functionName: 'getAmountRoleHolders', 
              args: [roleId]
            })
            const laws = organisation.laws?.filter(law => law.allowedRole == BigInt(roleId))
            rolesFetched.push({roleId, holders: Number(fetchedRoleHolders), laws})
            }
          } catch (error) {
            setStatus("error") 
            setError(error)
          }
      }
      const rolesSorted = rolesFetched.sort((a: Roles, b: Roles) => a.roleId > b.roleId ? 1 : -1)
      setRoles(rolesSorted)
      setStatus("success")
  }, [ ]) 

  useEffect(() => {
    fetchRoleHolders(organisation.roles)
  }, [])

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full min-h-16 flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Roles
        </div>
        <button 
          className="w-fit h-fit p-1 rounded-md border-slate-500"
          onClick = {() => updateOrg(organisation)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={statusUpdate == 'pending'}
              />
        </button>
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
            roles?.map((role: Roles, i: number) =>
              <tr key = {i}>
                <td className="flex flex-col w-full max-w-60 min-w-40 justify-center items-start text-left rounded-bl-md px-4 py-3 w-fit">
                 <Button
                    showBorder={true}
                    selected={true}
                    filled={true}
                    role={parseRole(BigInt(role.roleId))}
                    onClick={() => {
                      setRole(role);
                      router.push("/roles/role");
                    }}
                    align={0}
                  >
                  {bigintToRole(role.roleId, organisation)} 
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
