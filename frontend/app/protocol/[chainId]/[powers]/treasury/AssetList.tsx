"use client";

import React, { useEffect } from "react";
import { ArrowPathIcon, ArrowUpRightIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useChains, useReadContracts } from "wagmi";
import { erc1155Abi, erc20Abi } from "@/context/abi";
import { useAssets } from "@/hooks/useAssets";
import { Token, Powers, Status } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";
import { Button } from "@/components/Button";

export function AssetList({powers, status: statusPowers}: {powers: Powers | undefined, status: Status}) {
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const {status, error, tokens, native, fetchTokens} = useAssets(powers)

  // console.log("@AssetList: waypoint 0", {powers, statusPowers, status, error, tokens, native})

  useEffect(() => {
    if (supportedChain && statusPowers == "success" && powers) {
      fetchTokens(powers) 
    }
  }, [powers, statusPowers, fetchTokens])

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Header - matching LogsList.tsx structure */}
      <div className="w-full flex flex-row gap-3 justify-between items-center pt-3 px-4">
        <div className="text-slate-800 text-center text-lg">
          Assets
        </div>
        <div className="flex flex-row gap-2 items-center">
          {supportedChain && powers && (
            <div className="w-8 h-8">
              <button
                onClick={() => {
                  if (powers) {
                    fetchTokens(powers)
                  }
                }}
                className={`w-full h-full flex justify-center items-center rounded-md border border-slate-400 py-1 px-2`}  
              >
                <ArrowPathIcon 
                  className="w-5 h-5 text-slate-500 aria-selected:animate-spin"
                  aria-selected={status == "pending"}
                />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Table content - matching LogsList.tsx structure */}
      {status && status == 'pending' ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox />
        </div>
        :
        (native || (tokens && tokens.length > 0)) ?
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-auto"> Asset </th>
                    <th className="px-2 py-3 font-light w-20"> Symbol </th>
                    <th className="px-2 py-3 font-light w-32"> Address </th>
                    <th className="px-2 py-3 font-light w-24"> Quantity </th>
                    <th className="px-2 py-3 font-light w-24"> {`Value (${native?.symbol})`} </th>
                    <th className="px-2 py-3 font-light w-20"> Value </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {native && (
                    <tr className="text-xs text-left text-slate-800">
                      {/* Asset */}
                      <td className="ps-4 px-2 py-3 w-auto">
                        <div className="text-slate-500 text-xs">
                          {supportedChain?.nativeCurrency?.name}
                        </div>
                      </td>
                      
                      {/* Symbol */}
                      <td className="px-2 py-3 w-20">
                        <div className="text-slate-500 text-xs">
                          {native?.symbol}
                        </div>
                      </td>
                      
                      {/* Address */}
                      <td className="px-2 py-3 w-32">
                        <div className="text-slate-500 text-xs">
                          -
                        </div>
                      </td>
                      
                      {/* Quantity */}
                      <td className="px-2 py-3 w-24">
                        <div className="text-slate-500 text-xs">
                          {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))}
                        </div>
                      </td>
                      
                      {/* Value (Native) */}
                      <td className="px-2 py-3 w-24">
                        <div className="text-slate-500 text-xs">
                          {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))}
                        </div>
                      </td>
                      
                      {/* Value */}
                      <td className="px-2 py-3 w-20">
                        <div className="text-slate-500 text-xs">
                          -
                        </div>
                      </td>
                    </tr>
                  )}
                  {
                    tokens?.map((token: Token, i) => 
                      <tr className="text-xs text-left text-slate-800" key={i}>
                        {/* Asset */}
                        <td className="ps-4 px-2 py-3 w-auto">
                          <div className="truncate text-slate-500 text-xs">
                            {token.name}
                          </div>
                        </td>
                        
                        {/* Symbol */}
                        <td className="px-2 py-3 w-20">
                          <div className="truncate text-slate-500 text-xs">
                            {token.symbol}
                          </div>
                        </td>
                        
                        {/* Address */}
                        <td className="px-2 py-3 w-32">
                          <div className="truncate text-slate-500 text-xs">
                            <a
                              href={`${supportedChain?.blockExplorers?.default.url}/address/${token.address}#code`} 
                              target="_blank" 
                              rel="noopener noreferrer"
                              className="flex flex-row items-center gap-1 hover:text-slate-700 transition-colors"
                            >
                              <span>{token.address?.slice(0, 6)}...{token.address?.slice(-4)}</span>
                              <ArrowUpRightIcon className="w-3 h-3" />
                            </a>
                          </div>
                        </td>
                        
                        {/* Quantity */}
                        <td className="px-2 py-3 w-24">
                          <div className="text-slate-500 text-xs">
                            {String((Number(token.balance)/ 10 ** Number(token.decimals)).toFixed(4))}
                          </div>
                        </td>
                        
                        {/* Value (Native) */}
                        <td className="px-2 py-3 w-24">
                          <div className="text-slate-500 text-xs">
                            {token.valueNative ? token.valueNative : '-'}
                          </div>
                        </td>
                        
                        {/* Value */}
                        <td className="px-2 py-3 w-20">
                          <div className="text-slate-500 text-xs">
                            -
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
          No assets found
        </div>
      }
    </div>
  );
}
