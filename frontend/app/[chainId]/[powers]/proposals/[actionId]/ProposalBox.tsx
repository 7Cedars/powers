"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useActionStore, setAction, setError } from "@/context/store";
import { Button } from "@/components/Button";
import { useLaw } from "@/hooks/useLaw";
import { parseRole } from "@/utils/parsers";
import { Action, Checks, Law, Powers, Proposal, Status } from "@/context/types";
import { StaticInput } from "../../../../../components/StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { SectionText } from "@/components/StandardFonts";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlockNumber } from "wagmi";
import { useChecks } from "@/hooks/useChecks";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { powersAbi } from "@/context/abi";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600",
]

export function ProposalBox({
  powers, 
  law, 
  checks, 
  status, 
  onCheck, 
  proposalStatus
}: {
  powers?: Powers, 
  law?: Law, 
  checks?: Checks, 
  status: Status, 
  onCheck: (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => void, 
  proposalStatus: number,
}) {
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposal, error, hasVoted, castVote, checkHasVoted} = useProposal();
  const [voteReceived, setVoteReceived] = useState<boolean>(false);

  const [logSupport, setLogSupport] = useState<bigint>()
  const {wallets} = useWallets();
  const {data: blockNumber} = useBlockNumber();
  console.log("@proposalBox: ", {law, action, checks, statusProposal, hasVoted})

  const handleCastVote = async (action: Action, support: bigint) => { 
    if (action) {
      setLogSupport(support)
      castVote(
          BigInt(action.actionId),
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
        BigInt(action.nonce),
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
      setVoteReceived(true)
    }
  }, [statusProposal])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[parseRole(law?.conditions?.allowedRole) % roleColour.length]} mt-2 rounded-md overflow-hidden`} >
      <>
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={`Proposal: ${law?.nameDescription}`}
          subtext={law?.nameDescription}
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
              value={action.nonce.toString()}
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
                value={action.uri}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 bg-slate-100 pl-3 text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      <div className="w-full flex flex-row justify-center items-center p-6 py-2">
      <Button 
            size={1} 
            showBorder={true} 
            role={law?.conditions?.allowedRole == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(law?.conditions?.allowedRole)}
            filled={false}
            selected={true}
            onClick={() => 
              onCheck(law as Law, action, wallets, powers as Powers)
            } 
            statusButton={
                action.uri && action.uri.length > 0 ? status : 'disabled'
              }> 
            Check 
          </Button>
      </div>

      {law && simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> } 

      {/* execute button */}
        <div className="w-full h-fit p-6">
          { proposalStatus != 0 ?  
              <div className = "w-full flex flex-row justify-center items-center gap-2 text-slate-400"> 
                Vote has closed  
              </div>
              :
              hasVoted || voteReceived ? 
              <div className = "w-full flex flex-row justify-center items-center gap-2 text-slate-400"> 
                Account has voted  
              </div>
              :
              <div className = "w-full flex flex-row gap-2"> 
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(action, 1n)} 
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
                  onClick={() => handleCastVote(action, 0n)} 
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
                  onClick={() => handleCastVote(action, 2n)} 
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
      </section>
    </main>
  );
}
