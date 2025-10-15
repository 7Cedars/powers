"use client";

import React, { useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { Law, Powers } from "@/context/types";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import HeaderLawSmall from "@/components/HeaderLawSmall";
import { useChains } from "wagmi";

export function LawList({powers, status}: {powers: Powers | undefined, status: string, onRefresh?: () => void}) {
  const router = useRouter();
  const chains = useChains();
  const { chainId } = useParams<{ chainId: string }>()
  const [deselectedRoles, setDeselectedRoles] = useState<bigint[]>([])
  const ActiveLaws = powers?.laws?.filter(law => law.active)

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (deselectedRoles?.includes(role)) {
      newDeselection = deselectedRoles?.filter(oldRole => oldRole != role)
    } else {
      newDeselection = [...deselectedRoles, role]
    }
    setDeselectedRoles(newDeselection)
  };

  const blockExplorerUrl = chains.find(chain => chain.id === parseInt(chainId))?.blockExplorers?.default.url;

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Role filter bar - matching ActionsList.tsx structure */}
      <div className="w-full flex flex-row gap-12 justify-start items-center py-4 overflow-x-auto border-b border-slate-200 p-4 pe-8">
        {powers?.roles?.map((role, i) => (
          <button 
            key={i}
            onClick={() => handleRoleSelection(BigInt(role.roleId))}
            className="w-fit h-full hover:text-slate-400 text-sm aria-selected:text-slate-800 text-slate-300 whitespace-nowrap"
            aria-selected={!deselectedRoles?.includes(BigInt(role.roleId))}
          >  
            <p className="text-sm text-left">{bigintToRole(role.roleId, powers)}</p>
          </button>
        ))}
      </div>

      {/* Table content */}
      {status == "pending" ?  
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        :
        ActiveLaws && ActiveLaws.length > 0 ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {ActiveLaws
                    ?.filter(law => law.conditions?.allowedRole != undefined && !deselectedRoles?.includes(BigInt(`${law.conditions?.allowedRole}`)))
                    ?.map((law: Law, i) => {
                      const roleName = law.conditions?.allowedRole != undefined ? bigintToRole(law.conditions?.allowedRole, powers as Powers) : "-";
                      const numHolders = "-"; // You can add actual holder count if available
                      
                      return (
                        <tr 
                          key={i}
                          className="text-xs text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                          onClick={() => { router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${law.index}`); }}
                        >
                          <td className="ps-4 px-2 py-3 w-auto">
                            <HeaderLawSmall
                              powers={powers as Powers}
                              lawName={law.nameDescription || `Law #${law.index}`}
                              roleName={roleName}
                              numHolders={numHolders}
                              contractAddress={law.lawAddress || ""}
                              blockExplorerUrl={blockExplorerUrl}
                            />
                          </td>
                        </tr>
                      );
                    })
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
