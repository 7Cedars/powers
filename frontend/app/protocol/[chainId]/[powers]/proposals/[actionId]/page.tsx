"use client";

import React, { useEffect, useState } from "react";
import { ProposalBox } from "./ProposalBox";
import { Voting } from "./Voting"; 
import { Votes } from "./Votes";
import { setAction, setError, useActionStore, useChecksStore } from "@/context/store";
import { Powers, Law, Status, Checks, Action } from "@/context/types";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { useProposal } from "@/hooks/useProposal";
import { useChecks } from "@/hooks/useChecks";
import { readContract } from "wagmi/actions";
import { powersAbi } from "@/context/abi";
import { hashAction } from "@/utils/hashAction";
import { wagmiConfig } from "@/context/wagmiConfig";
import { LawLink } from "@/components/LawLink";
import { useReadContracts } from "wagmi";
import { useAction } from "@/hooks/useAction";
import { TitleText } from "@/components/StandardFonts";

const Page = () => {
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { wallets } = useWallets();
  const { fetchChainChecks, status: statusChecks } = useChecks();
  const { fetchActionData, data: actionData, status: statusAction } = useAction();
  const { chainChecks } = useChecksStore();
  const action = useActionStore(); 
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()

  const handleCheck = async (lawId: bigint, action: Action, wallets: ConnectedWallet[], powers: Powers) => {
    // console.log("@Proposal page: waypoint 2", {lawId, action, wallets, powers})
    fetchChainChecks(lawId, action.callData, BigInt(action.nonce), wallets, powers)
  }

  // console.log("@Proposal page: waypoint 0", {actionData, action})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (actionId) {
      fetchActionData(BigInt(actionId), powers as Powers)
    }
  }, [actionId, powers])

  useEffect(() => {
    if (actionData) {
      setAction(actionData)
    }
  }, [actionData])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center gap-3 pt-16 overflow-x-scroll ps-4 pe-12 pb-20">
      <TitleText 
        title="Vote"
        subtitle="Vote on a proposal."
        size={2}
      />
      { 
        actionData?.lawId && <ProposalBox 
        powers = {powers} 
        lawId = {actionData?.lawId} 
        checks = {chainChecks.get(String(actionData?.lawId)) as Checks} 
        status = {statusChecks} 
        onCheck = {() => handleCheck(actionData?.lawId as bigint, action, wallets, powers as Powers)} 
        proposalStatus = {actionData?.state ? actionData.state : 0} /> 
        }
      {actionData?.lawId && powers && <LawLink lawId = {actionData?.lawId} powers = {powers as Powers}/>}
      { actionData?.lawId && <Voting action = {action} powers = {powers} status = {statusChecks}/> }
      { <Votes actionId = {actionId} action = {action} powers = {powers} status = {statusChecks}/> }
    </main>
)
}

export default Page
