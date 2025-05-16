"use client";
 
import React, { useCallback, useEffect, useState } from "react";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { MyProposals } from "./MyProposals";
import { Status } from "@/context/types";
import { wagmiConfig } from "@/context/wagmiConfig";
import { getBlock, GetBlockReturnType, readContract } from "@wagmi/core";
import { powersAbi } from "@/context/abi";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { MyRoles } from "./MyRoles";
import { Assets } from "./Assets";
import { Overview } from "./Overview";
import { useParams } from 'next/navigation'
import { usePowers } from "@/hooks/usePowers";
import { LoadingBox } from "@/components/LoadingBox";
import { parseChainId } from "@/utils/parsers";import { useChains } from "wagmi";
;

export default function Page() {
    const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()  
    const { fetchPowers, status: statusPowers, powers } = usePowers()
    const { wallets } = useWallets()
    const { authenticated } = usePrivy(); 
    const [status, setStatus] = useState<Status>()
    const [error, setError] = useState<any | null>(null)
    const [hasRoles, setHasRoles] = useState<{role: bigint; since: bigint}[]>([])
    const chains = useChains()
    const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
    
    console.log("@home:", {chains, supportedChain})

    const fetchMyRoles = useCallback(
      async (account: `0x${string}`, roles: bigint[]) => {
        let role: bigint; 
        let fetchedHasRole: {role: bigint; since: bigint}[] = []; 

        try {
          for await (role of roles) {
            const fetchedSince = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: addressPowers as `0x${string}`,
                functionName: 'hasRoleSince', 
                args: [account, role]
                })
              fetchedHasRole.push({role, since: fetchedSince as bigint})
              }
              setHasRoles(fetchedHasRole)
          } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }, [])

    useEffect(() => {
      if (wallets && wallets[0]) {
        fetchMyRoles(wallets[0].address as `0x${string}`, powers?.roles || [])
      }
    }, [wallets?.[0]?.address, fetchMyRoles, powers?.roles])

    useEffect(() => {
      if (addressPowers) {
        fetchPowers(addressPowers as `0x${string}`)
      }
    }, [addressPowers, fetchPowers]) // updateProposals

    return (
      <main className="w-full h-full flex flex-col justify-start items-center gap-3 px-2 overflow-x-scroll pt-20">
        {/* hero banner  */}
        <section className={`w-full min-h-64 flex flex-col justify-between items-end text-slate-50 text-5xl bg-gradient-to-br to-indigo-600 from-emerald-300 rounded-md`}>
          <div className="w-full max-w-fit h-full max-h-fit text-lg p-6">
            {supportedChain && supportedChain.name }
          </div>
          <div className="w-full max-w-fit h-full max-h-fit text-6xl p-6">
            {powers?.name}
          </div>
        </section>
        
        {/* Description + link to powers protocol deployment */}  
        <section className="w-full h-fit flex flex-col gap-2 justify-left items-center border border-slate-200 rounded-md bg-slate-50 lg:max-w-full max-w-3xl p-4">
          {statusPowers == "pending" || statusPowers == "idle" ? <LoadingBox /> : 
          <>
          <div className="w-full text-slate-800 text-left text-pretty">
             {powers?.metadatas?.description} 
          </div>
          <a
            href={`${supportedChain?.blockExplorers?.default.url}/address/${addressPowers as `0x${string}`}#code`} target="_blank" rel="noopener noreferrer"
            className="w-full"
          >
          <div className="flex flex-row gap-1 items-center justify-start">
            <div className="text-left text-sm text-slate-500 break-all w-fit">
              {addressPowers as `0x${string}`}
            </div> 
              <ArrowUpRightIcon
                className="w-4 h-4 text-slate-500"
                />
            </div>
          </a>
          </>
          }
        </section>
        
        {/* main body  */}
        <section className="w-full lg:max-w-full h-full flex max-w-3xl lg:flex-row flex-col-reverse justify-end items-start">
          {/* left / bottom panel  */}
          <div className = {"w-full min-h-fit pb-16"}>
            <Overview powers = {powers} onUpdatePowers = {() => {fetchPowers(addressPowers as `0x${string}`)}} status = {statusPowers} /> 
          </div>
          {/* right / top panel  */} 
          <div className = {"w-full pb-2 flex flex-wrap flex-col lg:flex-nowrap max-h-48 min-h-48 lg:max-h-full lg:w-96 lg:flex-col lg:overflow-hidden lg:ps-2 gap-3 overflow-y-hidden overflow-x-scroll scroll-snap-x"}> 

            <Assets status = {statusPowers} powers = {powers}/> 

            <MyProposals hasRoles = {hasRoles} authenticated = {authenticated} proposals = {powers?.proposals || []} powers = {powers} status = {statusPowers} /> 

            <MyRoles hasRoles = {hasRoles} authenticated = {authenticated} powers = {powers} status = {statusPowers}/>
          </div>
        </section>
      </main>
    )

}
