`use client`

import { Powers, Status } from "@/context/types";
import { useAssets } from "@/hooks/useAssets";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { useEffect } from "react";

export function Assets({powers}: {status: Status, powers: Powers | undefined}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const {status, tokens, native, fetchTokens} = useAssets(powers)

  useEffect(() => {
    if (chainId && powers) {
      fetchTokens(powers as Powers)   
    }
  }, [powers, fetchTokens, chainId])

  // Mock asset data - replace with actual asset data when available
  const assets = [
    { symbol: 'ETH', amount: '0', value: '0 USD' },
    // Add more assets as needed
  ];
  
  return (
    <div className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden">
      <button
        onClick={() => 
          { 
             // here have to set deselectedRoles
            router.push(`/protocol/${chainId}/${powers?.contractAddress}/treasury`)
          }
        } 
        className="w-full border-b border-slate-300 p-2 bg-slate-100"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between">
        <div className="text-left text-sm text-slate-600 w-32">
          Treasury
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
      
      {powers?.treasury && powers.treasury != '0x0000000000000000000000000000000000000000' ? (
        <div className="w-full h-fit lg:max-h-48 max-h-32 flex flex-col justify-start items-center overflow-hidden">
          <div className="w-full overflow-x-auto overflow-y-auto">
            <table className="w-full table-auto text-sm">
              <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                <tr className="w-full text-xs font-light text-left text-slate-500">
                  <th className="px-2 py-3 font-light w-20"> Asset </th>
                  <th className="px-2 py-3 font-light w-24"> Amount </th>
                  <th className="px-2 py-3 font-light w-auto"> Value (ETH) </th>
                </tr>
              </thead>
              <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                {native && (
                  <tr
                    className="text-sm text-left text-slate-800"
                  >
                    {/* Asset Symbol */}
                    <td className="px-2 py-3 w-20">
                      <div className="text-xs font-mono text-slate-800">
                        {native.symbol}
                      </div>
                    </td>
                    
                    {/* Quantity */}
                    <td className="px-2 py-3 w-24">
                      <div className="text-xs text-slate-500 font-mono">
                        {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))}
                      </div>
                    </td>
                    
                    {/* Value */}
                    <td className="px-2 py-3 w-auto">
                      <div className="text-xs text-slate-500">
                        {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))}
                      </div>
                    </td>
                  </tr>
                )}
                {tokens && tokens.map((token, i) => (
                  <tr
                    key={i}
                    className="text-sm text-left text-slate-800"
                  >
                    {/* Asset Symbol */}
                    <td className="px-2 py-3 w-20">
                      <div className="text-xs font-mono text-slate-800">
                        {token.symbol}
                      </div>
                    </td>
                    
                    {/* Amount */}
                    <td className="px-2 py-3 w-24">
                      <div className="text-xs text-slate-500 font-mono">
                        {String((Number(token.balance)/ 10 ** Number(token.decimals)).toFixed(4))}
                      </div>
                    </td>
                    
                    {/* Value */}
                    <td className="px-2 py-3 w-auto">
                      <div className="text-xs text-slate-500">
                        {token.valueNative ? token.valueNative : '-'}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No treasury set
        </div>
      )}
    </div>
  )
}
