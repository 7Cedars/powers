"use client";

import React from "react";
import { Button } from "@/components/Button";
import { useRouter, useParams } from "next/navigation";
import { Law, Powers } from "@/context/types";

import { bigintToRole } from "@/utils/bigintTo";
import { setRole, useRoleStore } from "@/context/store";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { LoadingBox } from "@/components/LoadingBox";
import { shorterDescription } from "@/utils/parsers";

export function LawList({powers, status, onRefresh}: {powers: Powers | undefined, status: string, onRefresh?: () => void}) {
  const router = useRouter();
  const {deselectedRoles} = useRoleStore()
  const { chainId } = useParams<{ chainId: string }>()

  // console.log("@LawList: ", {deselectedRoles, powers, status})
  
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
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Header with roles - matching LogsList.tsx structure */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-4 overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Laws
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

      {/* Table content - matching LogsList.tsx structure */}
      {status == "pending" ?  
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        :
        powers?.activeLaws && powers?.activeLaws.length > 0 ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-16"> Id </th>
                    <th className="px-2 py-3 font-light w-auto"> Description </th>
                    <th className="px-2 py-3 font-light w-32"> Address </th>
                    <th className="px-2 py-3 font-light w-20"> Role </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    powers?.activeLaws?.filter(law => law.conditions?.allowedRole != undefined && !deselectedRoles?.includes(BigInt(`${law.conditions?.allowedRole}`)))?.map((law: Law, i) => 
                      <tr
                        key={i}
                        className="text-xs text-left text-slate-800"
                      >
                        {/* ID */}
                        <td className="ps-4 px-2 py-3 w-16">
                          <div className="text-slate-500 text-xs">
                            {Number(law.index)}
                          </div>
                        </td>
                        
                        {/* Description */}
                        <td className="px-2 py-3 w-auto">
                          <Button
                            showBorder={true}
                            role={
                              law.conditions?.allowedRole == 115792089237316195423570985008687907853269984665640564039457584007913129639935n
                                ? 6
                                : law.conditions?.allowedRole == 0n
                                ? 0
                                : Number(law.conditions?.allowedRole)
                            }
                            onClick={() => { router.push(`/${chainId}/${powers?.contractAddress}/laws/${law.index}`); }}
                            align={0}
                            selected={true}
                            filled={false}
                            size={0}
                          >
                            <div className="text-xs py-1 px-1">
                              {shorterDescription(law.nameDescription, "short")}
                            </div>
                          </Button>
                        </td>
                        
                        {/* Address */}
                        <td className="px-2 py-3 w-32">
                          <div className="truncate text-slate-500 text-xs">
                            {law.lawAddress && 
                              <a 
                                href={`https://sepolia.etherscan.io/address/${law.lawAddress}`} 
                                target="_blank" 
                                rel="noopener noreferrer"
                                className="flex flex-row items-center gap-1 hover:text-slate-700 transition-colors"
                              >
                                <span>{`${law.lawAddress.slice(0, 6)}...${law.lawAddress.slice(-4)}`}</span>
                                <ArrowUpRightIcon className="w-3 h-3" />
                              </a>
                            }
                          </div>
                        </td>
                        
                        {/* Role */}
                        <td className="px-2 py-3 w-20">
                          <div className="truncate text-slate-500 text-xs">
                            {law.conditions?.allowedRole != undefined ? bigintToRole(law.conditions?.allowedRole, powers) : "-"}
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
          No active laws found
        </div>
      }
    </div>
  );
}
