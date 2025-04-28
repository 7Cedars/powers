"use client";

import React from "react";
import { Button } from "@/components/Button";
import { useRouter } from "next/navigation";
import { Law, Powers } from "@/context/types";

import { bigintToRole } from "@/utils/bigintToRole";
import { setRole, useRoleStore } from "@/context/store";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { LoadingBox } from "@/components/LoadingBox";
import { shorterDescription } from "@/utils/parsers";

export function LawList({powers, onUpdatePowers, status}: {powers: Powers | undefined, onUpdatePowers: () => void, status: string}) {
  const router = useRouter();
  const {deselectedRoles} = useRoleStore()

  console.log("LawList: ", {deselectedRoles, powers})
  
  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (deselectedRoles?.includes(role)) {
      newDeselection = deselectedRoles?.filter(oldRole => oldRole != role)
    } else if (deselectedRoles != undefined) {
      newDeselection = [...deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    setRole({deselectedRoles: newDeselection})
  };

  return (
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md">
      {/* table banner  */}
      <div className="w-full min-h-16 flex flex-row gap-3 justify-between items-center py-3 px-4 overflow-y-scroll border-b slate-300">
        <div className="text-slate-900 text-center font-bold text-lg">
          Laws
        </div>
        {powers?.roles?.map((role, i) => 
            <div className="flex flex-row w-full min-w-fit h-8" key={i}>
              <Button
                size={0}
                showBorder={true}
                role={role == 4294967295n ? 6 : Number(role)}
                selected={!deselectedRoles?.includes(BigInt(role))}
                onClick={() => handleRoleSelection(BigInt(role))}
              >
                {bigintToRole(role, powers)} 
              </Button>
            </div>
        )}
        { powers && 
          <button 
            className="w-fit min-h-fit p-1 rounded-md border-slate-500"
            onClick = {() => {
              onUpdatePowers()
            }}
            disabled={status == 'pending'}
            >
              <ArrowPathIcon
                className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
                aria-selected={status == 'pending'}
                />
          </button>
        }
      </div>
      {/* table laws  */}
      {status == "pending" || status == "idle" ?  
      <div className="w-full h-full flex flex-col justify-start text-sm text-slate-500 items-start p-3">
        <LoadingBox /> 
      </div>
      :
      <div className="w-full overflow-scroll">
      {/* border border-t-0 */}
      <table className="w-full table-auto"> 
        <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500 ">
                <th className="ps-4 py-2 font-light rounded-tl-md"> Description </th>
                <th className="font-light"> Address </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full h-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {
            powers?.activeLaws?.filter(law => law.conditions.allowedRole != undefined && !deselectedRoles?.includes(BigInt(`${law.conditions.allowedRole}`)))?.map((law: Law, i) => 
              <tr
                key={i}
                className={`text-sm text-left text-slate-800 h-16 p-2`}
              >
                <td className="max-h-12 text-left px-2 min-w-44 max-w-52 overflow-x-scroll">
                  <Button
                    showBorder={true}
                    role={
                      law.conditions.allowedRole == 4294967295n
                        ? 6
                        : law.conditions.allowedRole == 0n
                        ? 0
                        : Number(law.conditions.allowedRole)
                    }
                    onClick={() => { router.push(`/${powers?.contractAddress}/laws/${law.index}`); }}
                    align={0}
                    selected={true}
                  >
                    {shorterDescription(law.description, "short")}
                  </Button>
                </td>
                <td className="pe-4 text-slate-500 h-full min-w-fit">
                  {law.lawAddress && 
                    <div className="flex flex-row justify-start items-center">
                      <a href={`https://sepolia.etherscan.io/address/${law.lawAddress}`} target="_blank" rel="noopener noreferrer">
                        {`${law.lawAddress.slice(0, 8)}...${law.lawAddress.slice(-6)}`}
                      </a>
                      <ArrowUpRightIcon
                        className="w-4 h-4 text-slate-500"
                      />
                    </div>
                  }
                </td>
                <td className="pe-4 min-w-20 text-slate-500"> {law.conditions.allowedRole != undefined ? bigintToRole(law.conditions.allowedRole, powers) : "-"}
                </td>
              </tr>
            )
          }
        </tbody>
      </table>
      </div>
      }
    </div>
  );
}
