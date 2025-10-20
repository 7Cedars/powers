"use client"

import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { Powers, Status, Law } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import { bigintToRole } from "@/utils/bigintTo";

type LawsProps = {
  powers: Powers | undefined;
  status: Status;
}

export function Laws({powers, status}: LawsProps) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()

  const activeLaws = powers?.laws && powers?.laws?.length > 0 ? powers?.laws?.filter(law => law.active) : [];

  return (
    <div className="w-fullflex flex-col justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden">
      <button
        onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws`) } 
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600 w-32">
            Active Laws
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
      activeLaws && activeLaws.length > 0 ? 
        <div className="w-full h-fit lg:max-h-56 max-h-48 flex flex-col justify-start items-center overflow-hidden">
          <div className="w-full overflow-x-auto overflow-y-auto">
            <table className="w-full table-fixed text-sm">
              <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                <tr className="w-full text-xs font-light text-left text-slate-500">
                  <th className="px-2 py-3 font-light w-10"> ID </th>
                  <th className="px-2 py-3 font-light"> Law </th>
                  <th className="px-2 py-3 font-light w-16"> Role </th>
                </tr>
              </thead>
              <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                {activeLaws.map((law: Law, i) => {
                  const lawName = law.nameDescription || `Law #${law.index}`;
                  // Cut off at double colon if present
                  const nameBeforeColon = lawName.includes('::') ? lawName.split('::')[0] : lawName;
                  const truncatedName = nameBeforeColon.length > 40 ? `${nameBeforeColon.slice(0, 40)}...` : nameBeforeColon;
                  const roleName = law.conditions?.allowedRole != undefined 
                    ? bigintToRole(law.conditions?.allowedRole, powers as Powers) 
                    : "-";
                  
                  return (
                    <tr
                      key={i}
                      className="text-sm text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                      onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${law.index}`)}
                    >
                      <td className="px-2 py-3 w-10">
                        <div className="text-xs text-slate-500 font-mono">
                          {law.index.toString()}
                        </div>
                      </td>
                      <td className="px-2 py-3">
                        <div className="truncate text-slate-800 text-xs">
                          {truncatedName}
                        </div>
                      </td>
                      <td className="px-2 py-3 w-16">
                        <div className="truncate text-slate-500 text-xs">
                          {roleName}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      :
        <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
          No laws found
        </div>
      }
    </div>
  )
}

