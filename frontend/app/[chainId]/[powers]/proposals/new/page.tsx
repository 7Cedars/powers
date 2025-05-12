"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useChecks } from "@/hooks/useChecks";
import { useActionStore } from "@/context/store";
import { Powers, Proposal, Law } from "@/context/types";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { ProposeBox } from "./ProposeBox";
import { LawLink } from "../[actionId]/LawLink";
import { ChecksBox } from "./ChecksBox"; 
import { useWallets } from "@privy-io/react-auth";
import { useReadContract } from "wagmi";
import { powersAbi } from "@/context/abi";

const Page = () => {
  const { powers, fetchPowers, status } = usePowers()
  const { wallets } = useWallets();
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()  
  const {checkProposalExists, checkAccountAuthorised, checks, fetchChecks, status: statusChecks} = useChecks(powers as Powers);
  const action = useActionStore(); 
  const law = powers?.laws?.find(law => law.index == action.lawId)
  const proposalExists = checkProposalExists(action.nonce, action.callData, law as Law, powers as Powers) != undefined  
  
  const authorised = useReadContract({
    abi: powersAbi,
    address: powers?.contractAddress as `0x${string}`,
    functionName: 'canCallLaw', 
    args: [wallets[0]?.address, law?.index]
  })
  
  console.log("@New Proposal page: ", {law, action, wallets, powers, checks, proposalExists, authorised: authorised.data})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers() // addressPowers as `0x${string}`
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (statusChecks == "success" && powers) {
      fetchChecks(law as Law, action.callData, action.nonce, wallets, powers as Powers)
    }
  }, [statusChecks, powers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll">
      <div className = "h-fit w-full pt-2">
      { <GovernanceOverview law = {law} powers = {powers}/> }
      </div> 
      {/* main body  */}
      <section className="w-full px-4 lg:max-w-full h-full flex lg:flex-row flex-col-reverse justify-end items-start">

        {/* left panel  */}
        <div className="lg:w-5/6 max-w-3xl w-full flex my-2 pb-16 min-h-fit"> 
        { powers && <ProposeBox law = {law} powers = {powers as Powers} proposalExists = {!proposalExists} authorised = {authorised.data as boolean} /> }
        </div>

         {/* right panel  */}
         <div className="flex flex-col flex-wrap lg:flex-nowrap lg:max-h-full max-h-48 min-h-48 lg:w-96 lg:my-4 my-0 lg:overflow-hidden w-full flex-row gap-4 justify-center items-center overflow-x-scroll scroll-snap-x overflow-y-hidden"> 
      
        <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72">
          { law && <LawLink law = {law} powers = {powers} status = {status} /> }
        </div>
        <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72"> 
          { checks && <ChecksBox powers = {powers} law = {law} checks = {checks} status = {status} /> }  
        </div>
      </div>
      </section>
    </main>
  )
}

export default Page 
