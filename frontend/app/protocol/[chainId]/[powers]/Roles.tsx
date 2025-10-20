"use client"

import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { bigintToRole } from "@/utils/bigintTo";
import { Powers, Status } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";

type RolesProps = {
  powers: Powers | undefined;
  status: Status;
}

export function Roles({powers, status}: RolesProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()

  // Count laws for each role
  const getLawCountForRole = (roleId: bigint) => {
    if (!powers?.laws) return 0;
    const ActiveLaws = powers.laws.filter(law => law.active)
    return ActiveLaws.filter(law => law.conditions?.allowedRole === roleId).length;
  };

  return (
    <div className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden">
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
      powers?.roles && powers?.roles.length > 0 ? 
        <div className="w-full h-fit lg:max-h-56 max-h-48 flex flex-col justify-start items-center overflow-hidden">
          <div className="w-full overflow-x-auto overflow-y-auto">
            <table className="w-full table-auto text-sm">
              <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                <tr className="w-full text-xs font-light text-left text-slate-500">
                  <th className="pl-2 pr-1 py-3 font-light"> Role </th>
                  <th className="pl-1 pr-2 py-3 font-light text-right"> Laws </th>
                </tr>
              </thead>
              <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                {powers?.roles?.map((role, i) => (
                  <tr
                    key={i}
                    className="text-sm text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                    onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/roles/${role.roleId}`)}
                  >
                    <td className="pl-2 pr-1 py-3">
                      <div className="text-xs text-slate-800">
                        {role.roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n 
                          ? 'Public' 
                          : bigintToRole(role.roleId as bigint, powers as Powers)
                        }
                      </div>
                    </td>
                    <td className="pl-1 pr-2 py-3">
                      <div className="text-xs text-slate-500 text-right">
                        {getLawCountForRole(role.roleId as bigint)}
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
  )
}
