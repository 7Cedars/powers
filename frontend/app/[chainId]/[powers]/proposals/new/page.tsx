"use client";

import React, { useEffect } from "react";
import { setError, useActionStore, useChecksStore } from "@/context/store";
import { Powers, Law, Action } from "@/context/types";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { ProposeBox } from "./ProposeBox";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { useChecks } from "@/hooks/useChecks";
import { LawLink } from "@/components/LawLink";
import { TitleText } from "@/components/StandardFonts";

const Page = () => {
  const { powers, fetchPowers, status } = usePowers()
  const { chainChecks } = useChecksStore();
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()  
  const action = useActionStore(); 
  const law = powers?.laws?.find(law => law.index == action.lawId)
  // Get checks for this specific law from Zustand store
  const checks = law ? chainChecks?.get(String(law.index)) : undefined
  const { wallets } = useWallets();
  const { fetchChainChecks } = useChecks();

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`) 
    }
  }, [addressPowers, fetchPowers])

  const handleCheck = async (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => {
    setError({error: null})
    fetchChainChecks(law.index, action.callData, BigInt(action.nonce), wallets, powers)
  }

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 ps-4 pe-12 pt-16">
        <TitleText 
          title="Propose"
          subtitle="Propose a new action that other role holders can vote on."
          size={2}
        />
        <div className="w-full flex min-h-fit"> 
          { powers && law && <ProposeBox 
              law = {law} 
              powers = {powers as Powers} 
              proposalExists = {checks?.proposalExists || false} 
              authorised = {checks?.authorised || false}  
              status = {status}
              onCheck = {() => handleCheck(law as Law, action, wallets, powers as Powers)}
              /> 
            }
        </div>
        {law && powers && <LawLink lawId = {law.index} powers = {powers as Powers}/>}
    </main>
  )
}

export default Page 
