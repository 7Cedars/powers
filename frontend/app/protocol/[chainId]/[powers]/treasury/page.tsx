"use client";

import React from "react";
import { AssetList } from "./AssetList";
import { AddAsset } from "./AddAsset";
import { TitleText } from "@/components/StandardFonts";
import { usePowersStore } from "@/context/store";
import { useChains } from "wagmi";
import { parseChainId } from "@/utils/parsers";
import { useParams } from "next/navigation";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";

export default function Page() {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()  
  const powers = usePowersStore(); 
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
   
  return (
    <main className="w-full h-fit flex flex-col gap-1 justify-start items-center pt-16 ps-4">  
      <TitleText
        title="Treasury"
        subtitle="View and manage the assets held by your Powers."
        size={2}
      />
      {powers.treasury && powers.treasury !== "0x0000000000000000000000000000000000000000" ? (
        <>
        <a
          href={`${supportedChain?.blockExplorers?.default.url}/address/${powers.treasury as `0x${string}`}#code`} target="_blank" rel="noopener noreferrer"
          className="w-full"
        >
        <div className="flex flex-row gap-1 items-center justify-start pb-3">
          <div className="text-left text-xs text-slate-500 break-all w-fit">
            {powers.treasury as `0x${string}`}
          </div> 
            <ArrowUpRightIcon
              className="w-3 h-3 text-slate-500"
              />
          </div>
        </a>
        <AssetList />
        <AddAsset /> 
       </>
      ) : (
        <div className="text-slate-500 p-6 italic ">
          No Treasury Address Set
        </div>
      )}

    </main>
  )
}
