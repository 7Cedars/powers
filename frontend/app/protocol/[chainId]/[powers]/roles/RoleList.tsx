"use client";

import React from "react";
import { useRouter, useParams } from "next/navigation";
import { Status, Powers, Role } from "@/context/types";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import DynamicThumbnail from "@/components/DynamicThumbnail";

type RoleListProps = {
  powers: Powers | undefined,
  status: Status,
}

// Need to add a refetch button ? 

export function RoleList({powers, status}: RoleListProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()

  const roles = powers?.roles

  console.log("@RoleList:", {roles, powers})

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
                    powers.roles?.map((role: Role, i: number) =>
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
                                  : `${role.amountHolders} ${Number(role.amountHolders) == 1 ? 'holder' : 'holders'}`
                                }
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
