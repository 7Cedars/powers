"use client";

import React, { useEffect } from "react";
import { ArrowPathIcon, ArrowUpRightIcon, GiftIcon } from "@heroicons/react/24/outline";
import { supportedChains } from "@/context/chains";
import { useReadContracts } from "wagmi";
import { erc1155Abi, erc20Abi } from "@/context/abi";
import { useAssets } from "@/hooks/useAssets";
import { Token, Powers, Status } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";

export function AssetList({powers, status: statusPowers}: {powers: Powers | undefined, status: Status}) {
  const { chainId } = useParams<{ chainId: string }>()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))
  const {status, error, tokens, native, fetchTokens} = useAssets(powers)

  useEffect(() => {
    if (supportedChain && statusPowers == "success" && powers) {
      // console.log("FetchTokens triggered:" , {supportedChain, statusPowers, powers})
      fetchTokens(powers) 
    }
  }, [powers, statusPowers, fetchTokens])

  return (
  <div className="w-full h-full flex flex-col justify-start items-center gap-6 overflow-x-scroll">   

    {/* Ether + owned assets table  */}
    <section className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-200 rounded-md overflow-hidden">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center py-4 px-6 border-b border-slate-200">
        <div className="text-slate-900 text-center font-bold text-lg">
          Treasury
        </div>
        {supportedChain && powers &&
        <button 
          className="w-fit h-fit p-1 border border-opacity-0 hover:border-opacity-100 rounded-md border-slate-500 aria-selected:animate-spin"
          onClick = {() => fetchTokens(powers)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={status && status == 'pending'}
              />
        </button>
        }
      </div>
      {/* table laws  */}
      <div className="w-full h-full overflow-x-scroll overflow-y-hidden">
      { status && status == 'pending' ? 
        <div className="w-full h-full flex flex-row justify-center items-center p-4">
          <LoadingBox />
        </div>
      :
      <table className="w-full table-auto ">
        <thead className="w-full border-b border-slate-200">
          <tr className="text-xs font-light text-slate-500 text-left">
              {/* name, possibly later also icon */}
              {/* any N/A should just be shown with a simple '-' */}
              <th className="ps-6  py-2 font-light"> Asset </th> 
              <th className="font-light"> Symbol </th>
              <th className="font-light"> Address </th>
              <th className="font-light"> Quantity </th>
              <th className="font-light"> {`Value (${native?.symbol})`} </th>
              {/* here add button to switch between USD, EUR and GBP + maybe YEN, ? other currency */}
              <th className="font-light"> Value </th> 
          </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {native &&
            <tr className={`text-sm text-left text-slate-500 h-16 overflow-x-scroll py-2`}>
                <td className="ps-6 px-2"> {supportedChain?.nativeCurrency?.name} </td>
                <td className=""> {native?.symbol} </td>
                <td className=""> - </td>
                <td className=""> {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))} </td>
                <td className=""> {String((Number(native?.value)/ 10 ** Number(native?.decimals)).toFixed(4))} </td>
            </tr>
          }
          {
            tokens?.map((token: Token, i) => 
              <tr className={`text-sm text-left text-slate-500 h-16 overflow-x-scroll`} key = {i}>
                <td className="ps-6 pe-4"> {token.name} </td>
                <td className="pe-4"> {token.symbol} </td>
                <td className="pe-4">
                  <a
                    href={`${supportedChain?.blockExplorerUrl}/address/${token.address}#code`} target="_blank" rel="noopener noreferrer"
                    className="w-full flex flex-row gap-1 py-2 items-start justify-start"
                  >
                    {token.address?.slice(0, 6)}...{token.address?.slice(-6)}
                    <ArrowUpRightIcon
                    className="w-4 h-4 text-slate-500"
                    />
                  </a>
                </td>
                <td className=""> {String((Number(token.balance)/ 10 ** Number(token.decimals)).toFixed(4))} </td>
                <td className=""> {token.valueNative  ? token.valueNative : ` - `} </td>
                <td className=""> {` - `} </td>
              </tr>
              )
            }
      </tbody>
      </table>
      }
      </div>
    </section>
    </div> 
  );
}
