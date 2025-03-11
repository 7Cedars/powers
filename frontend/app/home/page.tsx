"use client";
 
import React, { useCallback, useEffect, useState } from "react";
import { setLaw, useOrgStore } from "../../context/store";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { LawList } from "@/app/laws/LawList";
import { MyProposals } from "./MyProposals";
import { Status } from "@/context/types";
import { publicClient } from "@/context/clients";
import { wagmiConfig } from "@/context/wagmiConfig";
import { getBlock, GetBlockReturnType, readContract } from "@wagmi/core";
import { powersAbi } from "@/context/abi";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { MyRoles } from "./MyRoles";
import { Assets } from "./Assets";
import { useChainId } from "wagmi";
import { supportedChains } from "@/context/chains";
import { useProposal } from "@/hooks/useProposal";
import { Overview } from "./Overview";
import {  sepolia } from "@wagmi/core/chains";

const colourScheme = [
  "from-indigo-500 to-emerald-500", 
  "from-blue-500 to-red-500", 
  "from-indigo-300 to-emerald-900",
  "from-emerald-400 to-indigo-700 ",
  "from-red-200 to-blue-400",
  "from-red-800 to-blue-400"
]

export default function Page() {
    const organisation = useOrgStore()
    const {wallets} = useWallets()
    const { proposals, fetchProposals } = useProposal();
    const { authenticated } = usePrivy();
    const [status, setStatus] = useState<Status>()
    const [error, setError] = useState<any | null>(null)
    const [hasRoles, setHasRoles] = useState<{role: bigint; since: bigint; blockData: GetBlockReturnType}[]>([])
    const chainId = useChainId();
    const supportedChain = supportedChains.find(chain => chain.id == chainId)

    // console.log("@home:", {organisation})

    const fetchMyRoles = useCallback(
      async (account: `0x${string}`, roles: bigint[]) => {
        let role: bigint; 
        let fetchedHasRole: {role: bigint; since: bigint; blockData: GetBlockReturnType}[] = []; 
        let blockData: GetBlockReturnType = {} as GetBlockReturnType;

        if (publicClient) {
          try {
            for await (role of roles) {
              const fetchedSince = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: organisation.contractAddress,
                functionName: 'hasRoleSince', 
                args: [account, role]
                })
                if (fetchedSince) {
                const fetchedBlockData = await getBlock(wagmiConfig, {
                  blockNumber: fetchedSince as bigint,
                  chainId: sepolia.id, // NB This needs to be made dynamic. In this case need to read of sepolia because arbitrum uses mainnet block numbers.  
                })
                blockData = fetchedBlockData as GetBlockReturnType
              }
              fetchedHasRole.push({role, since: fetchedSince as bigint, blockData: blockData as GetBlockReturnType})
              }
              setHasRoles(fetchedHasRole)
          } catch (error) {
            setStatus("error") 
            setError(error)
          }
        }
    }, [])

    useEffect(() => {
      if (wallets && wallets[0]) {
        fetchMyRoles(wallets[0].address as `0x${string}`, organisation.roles)
      }
    }, [wallets?.[0]?.address, fetchMyRoles, organisation.roles])

    useEffect(() => {
      if (organisation) {
        fetchProposals(organisation);
      }
    }, [ ])
 
    return (
      <main className="w-full h-full flex flex-col justify-start items-center gap-3 px-2 overflow-y-scroll pt-20">
        {/* hero banner  */}
        <section className={`w-full min-h-64 flex flex-col justify-center items-center text-center text-slate-50 text-5xl bg-gradient-to-bl ${colourScheme[organisation.colourScheme] } rounded-md`}> 
          {organisation?.name}
        </section>
        
        {/* Description + link to powers protocol deployment */}
        { organisation?.metadatas?.description &&  
        <section className="w-full h-fit flex flex-col gap-2 justify-left items-center border border-slate-200 rounded-md bg-slate-50 lg:max-w-full max-w-3xl p-4">
          <div className="w-full text-slate-800 text-left text-pretty">
            {organisation.metadatas.description}
          </div>
          <a
            href={`${supportedChain?.blockExplorerUrl}/address/${organisation.contractAddress}#code`} target="_blank" rel="noopener noreferrer"
            className="w-full"
          >
          <div className="flex flex-row gap-1 items-center justify-start">
            <div className="text-left text-sm text-slate-500 break-all w-fit">
              {organisation.contractAddress }
            </div> 
              <ArrowUpRightIcon
                className="w-4 h-4 text-slate-500"
                />
            </div>
          </a>
        </section>
        }

        
        {/* main body  */}
        <section className="w-full lg:max-w-full h-full flex max-w-3xl lg:flex-row flex-col-reverse justify-end items-start">
          {/* left / bottom panel  */}
          <div className = {"w-full h-full min-h-fit pb-16"}>
            <Overview /> 
          </div>
          {/* right / top panel  */} 
          <div className = {"w-full pb-2 flex flex-wrap flex-col lg:flex-nowrap max-h-48 min-h-48 lg:max-h-full lg:w-96 lg:flex-col lg:overflow-hidden lg:ps-2 gap-3 overflow-y-hidden overflow-x-scroll scroll-snap-x"}> 
            <Assets /> 
            
            <MyProposals hasRoles = {hasRoles} authenticated = {authenticated} proposals = {proposals} /> 

            <MyRoles hasRoles = {hasRoles} authenticated = {authenticated}/>
          </div>
        </section>
      </main>
    )

}
