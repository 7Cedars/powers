"use client";

import React, { useEffect, useState } from "react";
import { ProposalBox } from "../../../../../../components/ProposalBox";
import { Voting } from "../../../../../../components/Voting"; 
import { Votes } from "../../../../../../components/Votes";
import { setAction, useActionStore, useChecksStore } from "@/context/store";
import { Powers, Checks, Action, Law } from "@/context/types";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { useChecks } from "@/hooks/useChecks";
import { LawLink } from "@/components/LawLink";
import { useAction } from "@/hooks/useAction";
import { TitleText } from "@/components/StandardFonts";

const Page = () => {
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { wallets } = useWallets();
  const { fetchChecks, status: statusChecks } = useChecks();
  const { fetchActionData, action: actionData, status: statusAction } = useAction();
  const { chainChecks } = useChecksStore();
  const action = useActionStore(); 
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()
  const law = powers?.laws?.find(law => law.index == actionData?.lawId)

  const handleCheck = async (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => {
    // console.log("@Proposal page: waypoint 2", {lawId, action, wallets, powers})
    fetchChecks(law, action.callData as `0x${string}`, BigInt(action.nonce as string), wallets, powers)
  }

  // console.log("@Proposal page: waypoint 0", {actionData, action})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (actionId) {
      fetchActionData({actionId: actionId, lawId: BigInt(actionId)}, powers as Powers)
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
        onCheck = {() => handleCheck(law as Law, action, wallets, powers as Powers)} 
        proposalStatus = {actionData?.state ? actionData.state : 0} /> 
        }
      { actionData?.lawId && powers && <LawLink lawId = {actionData?.lawId} powers = {powers as Powers}/> }
      { actionData?.lawId && <Voting action = {action} powers = {powers} status = {statusChecks}/> }
      { <Votes actionId = {actionId} action = {action} powers = {powers} status = {statusChecks}/> }
    </main>
)
}

export default Page
