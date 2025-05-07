"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useActionStore, setAction } from "@/context/store";
import { Button } from "@/components/Button";
import { useLaw } from "@/hooks/useLaw";
import { decodeAbiParameters,  keccak256, parseAbiParameters, toHex } from "viem";
import { bytesToParams, parseParamValues, parseRole } from "@/utils/parsers";
import { Checks, InputType, Law, Powers, Proposal, Status } from "@/context/types";
import { StaticInput } from "../../../../../components/StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { SectionText } from "@/components/StandardFonts";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { LoadingBox } from "@/components/LoadingBox";
// import { useChecks } from "@/hooks/useChecks";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600",
]

export function ProposalBox({proposal, powers, law, checks, status}: {proposal?: Proposal, powers?: Powers, law?: Law, checks?: Checks, status: Status, wallets?: ConnectedWallet[]}) {
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposal, error, hasVoted, castVote, checkHasVoted} = useProposal();

  const [logSupport, setLogSupport] = useState<bigint>()
  const {wallets} = useWallets();
  // console.log("@proposalBox: ", {law, action, checks, statusProposal, hasVoted, proposal})

  const handleCastVote = async (proposal: Proposal, support: bigint) => { 
    if (proposal) {
      setLogSupport(support)
      castVote(
          BigInt(proposal.actionId),
          support,
          powers as Powers
        )
    }
  };

  useEffect(() => {
    if (action.actionId && wallets.length > 0) {
      simulate(
        action.caller,
        action.callData,
        action.nonce,
        law as Law
        )

        checkHasVoted(
          BigInt(action.actionId), 
          wallets[0].address as `0x${string}`,
          powers as Powers
        )
      }
  }, [action, wallets])

  useEffect(() => {
    if (statusProposal == "success" && wallets.length > 0) {
      checkHasVoted(
        BigInt(action.actionId), 
        wallets[0].address as `0x${string}`,
        powers as Powers
      )
    }
  }, [statusProposal])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[parseRole(law?.conditions.allowedRole) % roleColour.length]} mt-2 rounded-md overflow-hidden`} >
      {status == "pending" || status == "idle" ?
      <div className = "w-full flex flex-col justify-center items-center p-2"> 
        <LoadingBox />
      </div>
      :
      <>
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={`Proposal: ${law?.description}`}
          subtext={law?.description}
          size = {0}
        /> 
      </div>

      {/* static form */}
      <form action="" method="get" className="w-full">
        {
          action && law?.params?.map((param, index) => 
            <StaticInput 
              dataType = {param.dataType} 
              varName = {param.varName} 
              values = {action.paramValues && action.paramValues[index] ? action.paramValues[index] : []} 
              key = {index}
              />)
        }
        {/* nonce */}
        <div className="w-full mt-4 flex flex-row justify-center items-start ps-2 pe-6 gap-3">
          <label htmlFor="nonce" className="text-sm text-slate-600 ps-4 pt-1 pe-7 ">Nonce</label>
          <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-slate-100 ps-3 outline outline-1 outline-slate-300">
            <input 
              type="text" 
              name="nonce"
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6"  
              id="nonce" 
              value={action.nonce as unknown as string}
              disabled={true}
              />
          </div>
        </div>
        
        {/* reason */}
        <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={25} 
                value={action.description}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 bg-slate-100 pl-3 text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      {law && simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> } 

      {/* execute button */}
        <div className="w-full h-fit p-6">
          { proposal && proposal.state && proposal != undefined && proposal.actionId != "0" && proposal.state != 0 ?  
              <div className = "w-full flex flex-row justify-center items-center gap-2 text-slate-400"> 
                Vote has closed  
              </div>
              :
              hasVoted ? 
              <div className = "w-full flex flex-row justify-center items-center gap-2 text-slate-400"> 
                Account has voted  
              </div>
              :
              proposal && 
              <div className = "w-full flex flex-row gap-2"> 
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(proposal, 1n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 1n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 1n ? 'disabled' 
                      : 
                      'idle'
                    }> 
                    For
                </Button>
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(proposal, 0n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 0n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 0n ? 'disabled' 
                      :
                      'idle'
                    }> 
                    Against
                </Button>
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(proposal, 2n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 2n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 2n ? 'disabled' 
                      :
                      'idle'
                    }> 
                    Abstain
                </Button>
              </div> 
          }
        </div>
      </>
      }
      </section>
    </main>
  );
}
