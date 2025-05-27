"use client";

import React, { useEffect, useState } from "react";
import { setAction, setRole, useRoleStore  } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter, useParams } from "next/navigation";
import { Powers, PowersExecutions } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintToRole";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlocks } from "@/hooks/useBlocks";

export function LogsList({powers, status}: {powers: Powers | undefined, status: string}) {
  const router = useRouter();
  const {deselectedRoles} = useRoleStore()
  const { chainId } = useParams<{ chainId: string }>()
  const { data: blocks, fetchBlocks } = useBlocks()

  useEffect(() => {
    if (powers?.executedActions && powers?.executedActions.length > 0) {
      // For actions, we'll use the current block number since we don't have a specific end time
      fetchBlocks(powers?.executedActions.map(action => BigInt(action.actionId)), chainId)
    }
  }, [powers?.executedActions, chainId, fetchBlocks])

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (deselectedRoles?.includes(role)) {
      newDeselection = deselectedRoles?.filter((oldRole: bigint) => oldRole != role)
    } else if (deselectedRoles != undefined) {
      newDeselection = [...deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    setRole({deselectedRoles: newDeselection})
  };

  return (
    <div className="w-full min-w-96 flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-y-scroll">
      {/* table banner:roles  */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-6 overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Logs
        </div>
        {powers?.roles?.map((role, i) => 
            <div className="flex flex-row w-full min-w-fit h-8" key={i}>
            <Button
              size={0}
              showBorder={true}
              role={role == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(role)}
              selected={!deselectedRoles?.includes(BigInt(role))}
              onClick={() => handleRoleSelection(BigInt(role))}
            >
              {bigintToRole(role, powers)} 
            </Button>
            </div>
        )}
      </div>

      {/* table laws  */}
      <div className="w-full overflow-scroll">
      {status == "pending" ? 
      <div className="w-full h-full min-h-fit flex flex-col justify-start text-sm text-slate-500 items-start p-3">
        <LoadingBox /> 
      </div>
      :
      <table className="w-full table-auto">
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Action ID </th>
                <th className="font-light"> Law </th>
                <th className="font-light min-w-44"> Targets </th>
                <th className="font-light"> Values </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {
            powers?.executedActions?.map((action: PowersExecutions, i) => {
              const law = powers?.laws?.find(law => law.index == action.lawId)
              return (
                law && 
                law.conditions?.allowedRole != undefined && 
                !deselectedRoles?.includes(BigInt(`${law.conditions?.allowedRole}`))
                ? 
                <tr
                  key={i}
                  className={`text-sm text-left text-slate-800 h-full w-full p-2 overflow-x-scroll`}
                >
                  <td className="h-full w-full max-w-48 flex flex-col text-center justify-center items-center py-3 px-4">
                      <Button
                        showBorder={true}
                        role={parseRole(law.conditions?.allowedRole)}
                        onClick={() => {
                          router.push(`/${chainId}/${powers?.contractAddress}/actions/${action.actionId}`);
                        }}
                        align={0}
                        selected={true}
                      > 
                        <div className="flex flex-row gap-3 w-fit min-w-48 text-center">
                          {action.actionId.toString()}
                        </div>
                      </Button>
                  </td>
                  <td className="pe-4 text-slate-500 min-w-56">{law.nameDescription}</td>
                  <td className="pe-4 text-slate-500 min-w-48">
                    {action.targets.map((target, i) => (
                      <div key={i}>{target}</div>
                    ))}
                  </td>
                  <td className="pe-4 text-slate-500">
                    {action.values.map((value, i) => (
                      <div key={i}>{value.toString()}</div>
                    ))}
                  </td>
                  <td className="pe-4 min-w-20 text-slate-500">
                    {bigintToRole(law.conditions?.allowedRole, powers)}
                  </td>
                </tr>
                : 
                null
              )
            }
          )}
        </tbody>
        </table>
      }
      </div>
    </div>
  );
} 