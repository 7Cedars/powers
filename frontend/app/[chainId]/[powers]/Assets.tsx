`use client`

import { LoadingBox } from "@/components/LoadingBox";
import { Powers, Status } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";

export function Assets({status, powers}: {status: Status, powers: Powers | undefined}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  
  // Mock asset data - replace with actual asset data when available
  const assets = [
    { symbol: 'ETH', amount: '0', value: '0 USD' },
    // Add more assets as needed
  ];
  
  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md lg:max-w-64 overflow-hidden">
      <button
        onClick={() => 
          { 
             // here have to set deselectedRoles
            router.push(`/${chainId}/${powers?.contractAddress}/treasury`)
          }
        } 
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between">
        <div className="text-left text-sm text-slate-600 w-44">
          Total Assets
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
      
      <div className="w-full h-fit lg:max-h-48 max-h-32 flex flex-col justify-start items-center overflow-hidden">
        <div className="w-full overflow-x-auto overflow-y-auto">
          <table className="w-full table-auto text-sm">
            <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
              <tr className="w-full text-xs font-light text-left text-slate-500">
                <th className="px-2 py-3 font-light w-20"> Asset </th>
                <th className="px-2 py-3 font-light w-24"> Amount </th>
                <th className="px-2 py-3 font-light w-auto"> Value </th>
              </tr>
            </thead>
            <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
              {assets.map((asset, i) => (
                <tr
                  key={i}
                  className="text-sm text-left text-slate-800"
                >
                  {/* Asset Symbol */}
                  <td className="px-2 py-3 w-20">
                    <div className="text-xs font-mono text-slate-800">
                      {asset.symbol}
                    </div>
                  </td>
                  
                  {/* Amount */}
                  <td className="px-2 py-3 w-24">
                    <div className="text-xs text-slate-500 font-mono">
                      {asset.amount}
                    </div>
                  </td>
                  
                  {/* Value */}
                  <td className="px-2 py-3 w-auto">
                    <div className="text-xs text-slate-500">
                      {asset.value}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
