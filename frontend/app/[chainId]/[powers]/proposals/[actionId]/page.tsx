"use client";

import React, { useEffect, useState } from "react";
import { ProposalBox } from "./ProposalBox";
import { ChecksBox } from "./ChecksBox"; 
import { StatusProposal } from "./StatusProposal"; 
import { Votes } from "./Votes"; 
import { useChecks } from "@/hooks/useChecks";
import { setAction, useActionStore } from "@/context/store";
import { Powers, Proposal, Law, Status } from "@/context/types";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { LawLink } from "./LawLink";
import { useWallets } from "@privy-io/react-auth";
import { parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { useProposal } from "@/hooks/useProposal";

const Page = () => {
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { wallets } = useWallets();
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()
  const proposal = powers?.proposals?.find(proposal => proposal.actionId == actionId)
  const law = powers?.laws?.find(law => law.index == proposal?.lawId)
  const action = useActionStore(); 
  const {checkProposalExists, checks, fetchChecks, status: statusChecks} = useChecks(powers as Powers);
  const {updateProposal} = useProposal();
  // console.log("@proposals page: ", {proposal, law, action, statusChecks})

  useEffect(() => {
    if (proposal && law) { 
      try {
        const values = decodeAbiParameters(parseAbiParameters(law?.params?.map(param => param.dataType).toString() || ""), proposal.executeCalldata as `0x${string}`);
        const valuesParsed = parseParamValues(values)

        setAction({
          actionId: proposal.actionId,
          lawId: proposal.lawId,
          caller: proposal.caller,
          dataTypes: law?.params?.map(param => param.dataType),
          paramValues: valuesParsed,
          nonce: proposal.nonce,
          description: proposal.description,
          callData: proposal.executeCalldata,
          upToDate: true
        })
      } catch {
        setAction({...action, upToDate: false })
      }
      fetchChecks(law, proposal.executeCalldata, proposal.nonce, wallets, powers as Powers)
      checkProposalExists(proposal.nonce, proposal.executeCalldata, law, powers as Powers)
      updateProposal(proposal, powers as Powers)
    }
  }, [, proposal])

  useEffect(() => {
    if (addressPowers) {
      fetchPowers() // addressPowers as `0x${string}`
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll max-w-6xl">
      <div className = "h-fit w-full pt-2">
        { <GovernanceOverview law = {law} powers = {powers}/> }
      </div> 

      <section className="w-full ps-4 pe-3 lg:max-w-full h-full flex lg:flex-row flex-col-reverse justify-end items-start">
      { proposal && 
        <div className="lg:w-5/6 max-w-3xl w-full flex my-2 pb-16 min-h-fit"> 
          <ProposalBox proposal = {proposal} powers = {powers} law = {law} checks = {checks} status = {statusChecks} /> 
        </div>
      }

        <div className="flex flex-col flex-wrap lg:flex-nowrap lg:max-h-full max-h-48 min-h-48 lg:w-96 lg:mt-4 lg:ml-4 my-0 lg:overflow-hidden w-full flex-row gap-4 justify-center items-center overflow-x-scroll scroll-snap-x overflow-y-hidden"> 
      
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72">
            { law && powers && <LawLink law = {law} powers = {powers} status = {statusChecks}/> }
          </div>
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72">
            { proposal && <StatusProposal proposal = {proposal} status = {statusChecks}/> }
          </div>
          
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72"> 
            <ChecksBox checks = {checks} powers = {powers} law = {law} status = {statusChecks}/>   
          </div>

            { proposal && <Votes proposal = {proposal} powers = {powers} status = {statusChecks}/> }
        
        </div>
        
      </section> 
    </main>
  )
}

export default Page 
