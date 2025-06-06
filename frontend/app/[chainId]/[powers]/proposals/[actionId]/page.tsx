"use client";

import React, { useEffect, useState } from "react";
import { ProposalBox } from "./ProposalBox";
import { Votes } from "./Votes"; 
import { setAction, setError, useActionStore, useChecksStore } from "@/context/store";
import { Powers, Proposal, Law, Status, Checks, Action } from "@/context/types";
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

const Page = () => {
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { wallets } = useWallets();
  const { chainChecks } = useChecksStore();
  const { fetchChainChecks, status: statusChecks } = useChecks(powers as Powers);
  const { powers: addressPowers, actionId } = useParams<{ powers: string, actionId: string }>()
  // NB: proposal might not have been loaded!  
  const proposal = powers?.proposals?.find(proposal => proposal.actionId == actionId)
  const law = powers?.laws?.find(law => law.index == proposal?.lawId)
  const [proposalStatus, setProposalStatus] = useState<number>(0)

  // 
  const action = useActionStore(); 
  // Get checks for this specific law from Zustand store
  const checks = law ? chainChecks?.get(String(law.index)) : undefined
  // const statusChecks: Status = 'success' // Since we're getting checks from global store, assume success

  console.log("@proposal, waypoint 1", {proposal, actionId, powers, action, law, checks, statusChecks})

  const checkActionStatus = async (law: Law, lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint) => {
      const actionId = hashAction(lawId, lawCalldata, nonce)

      try {
        const state =  await readContract(wagmiConfig, {
                abi: powersAbi,
                address: law.powers as `0x${string}`,
                functionName: 'state', 
                args: [actionId],
              })
         setProposalStatus(Number(state)) 
      } catch (error) {
        setProposalStatus(6)
        setError({error: error as Error})
      }
  } 

  useEffect(() => {
    console.log('Proposal page useEffect triggered', { proposal: !!proposal, law: !!law })
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
        checkActionStatus(law, proposal.lawId, proposal.executeCalldata, BigInt(proposal.nonce))

      } catch {
        setAction({...action, upToDate: false })
      }
      // Layout manages checks via Zustand store now
    }
  }, [proposal])

  const handleCheck = async (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => {
    setError({error: null})
    fetchChainChecks(law.index, action.callData, BigInt(action.nonce), wallets, powers)
  }

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (powers) {
      console.log("@proposals/[actionId], fetchChainChecks: ", {law, action, wallets, powers})
      fetchChainChecks(BigInt(law?.index || 0), action.callData, BigInt(action.nonce), wallets, powers as Powers)
    }
  }, [, powers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-4 pt-16 overflow-x-scroll ps-4 pe-12">
      { 
        law && <ProposalBox 
        powers = {powers} 
        law = {law} 
        checks = {checks} 
        status = {statusChecks} 
        onCheck = {() => handleCheck(law, action, wallets, powers as Powers)} 
        proposalStatus = {proposalStatus} /> 
        }
      { law && <Votes action = {action} powers = {powers} status = {statusChecks}/> }
    </main>
  )
}

export default Page 
