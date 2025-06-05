"use client";

import React, { useEffect, useState } from "react";
import { ProposalBox } from "./ProposalBox";
import { Votes } from "./Votes"; 
import { useChecks } from "@/hooks/useChecks";
import { setAction, useActionStore } from "@/context/store";
import { Powers, Proposal, Law, Status } from "@/context/types";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { useWallets } from "@privy-io/react-auth";
import { parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { useProposal } from "@/hooks/useProposal";

const Page = () => {
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { wallets } = useWallets();
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()
  // NB: proposal might not have been loaded!  
  const proposal = powers?.proposals?.find(proposal => proposal.actionId == actionId)
  const law = powers?.laws?.find(law => law.index == proposal?.lawId)
  // 
  const action = useActionStore(); 
  const {checks, fetchChecks, status: statusChecks} = useChecks(powers as Powers);

  // console.log("@proposal, waypoint 1", {proposal, actionId, powers, action})

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
          uri: proposal.description,
          callData: proposal.executeCalldata,
          upToDate: true
        })
      } catch {
        setAction({...action, upToDate: false })
      }
      fetchChecks(law, proposal.executeCalldata, BigInt(proposal.nonce), wallets, powers as Powers) 
      // fetchProposal(proposal, powers as Powers)
    }
  }, [proposal])

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-4 pt-16 overflow-x-scroll ps-4 pe-12">
      { proposal && <ProposalBox proposal = {proposal} powers = {powers} law = {law} checks = {checks} status = {statusChecks} /> }
      { proposal && <Votes proposal = {proposal} powers = {powers} status = {statusChecks}/> }
    </main>
  )
}

export default Page 
