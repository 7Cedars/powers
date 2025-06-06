"use client";

import React, { useEffect } from "react";
import { useActionStore, useChecksStore } from "@/context/store";
import { Powers, Proposal, Law, Checks } from "@/context/types";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { ProposeBox } from "./ProposeBox";
import { useWallets } from "@privy-io/react-auth";
import { useChecks } from "@/hooks/useChecks";

const Page = () => {
  const { powers, fetchPowers, status } = usePowers()
  const { wallets } = useWallets();
  const { chainChecks } = useChecksStore();
  const { fetchChainChecks } = useChecks(powers as Powers);
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()  
  const action = useActionStore(); 
  const law = powers?.laws?.find(law => law.index == action.lawId)
  // Get checks for this specific law from Zustand store
  const checks = law ? chainChecks?.get(String(law.index)) : undefined

  // console.log("Proposals/new: ", {powers, law, checks, action})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`) 
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (powers) {
      console.log("@proposals/new, fetchChainChecks: ", {law, action, wallets, powers})
      fetchChainChecks(BigInt(law?.index || 0), action.callData, BigInt(action.nonce), wallets, powers)
    }
  }, [, powers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll">
        <div className="w-full flex my-2 px-4 pe-12 min-h-fit"> 
          { powers && law && <ProposeBox 
              law = {law} 
              powers = {powers as Powers} 
              proposalExists = {checks?.proposalExists || false} 
              authorised = {checks?.authorised || false}  
              /> 
            }
        </div>
    </main>
  )
}

export default Page 
