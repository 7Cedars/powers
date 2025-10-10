"use client";

import React, { useEffect, useState } from "react";
import { useActionStore } from "@/context/store";
import { Button } from "@/components/Button";
import { useLaw } from "@/hooks/useLaw";
import { Action, Checks, Law, Powers } from "@/context/types";
import { SimulationBox } from "@/components/SimulationBox";
import { useWallets } from "@privy-io/react-auth";
import HeaderLaw from '@/components/HeaderLaw';
import { useChains } from 'wagmi';
import { parseChainId } from '@/utils/parsers';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { StaticForm } from "@/components/StaticForm";

export function ProposalBox({
  powers, 
  lawId, 
  checks, 
  proposalStatus
}: {
  powers?: Powers, 
  lawId: bigint, 
  checks?: Checks, 
  proposalStatus: number,
}) {
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposal, hasVoted, castVote, checkHasVoted} = useLaw();
  const [voteReceived, setVoteReceived] = useState<boolean>(false);
  const law = powers?.laws?.find(law => law.index == lawId)
  const chains = useChains();
  const supportedChain = chains.find(chain => chain.id == parseChainId(powers?.contractAddress ? powers.contractAddress.slice(0, 10) : ''));

  const [logSupport, setLogSupport] = useState<bigint>()
  const {wallets} = useWallets();
  // console.log("@proposalBox: ", {lawId, action, checks, statusProposal, hasVoted})

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
        action.caller as `0x${string}`,
        action.callData as `0x${string}`,
        BigInt(action.nonce as string),
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
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border-2 border-slate-600 rounded-md overflow-hidden`}>
      <>
      {/* title - replaced with HeaderLaw */}
      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
        <HeaderLaw
          powers={powers as Powers}
          lawName={law?.nameDescription ? `#${Number(law?.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law?.index)}`}
          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
          contractAddress={law?.lawAddress || ''}
          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
        />
      </div>

      {/* static form */}
      <StaticForm law={law} />

      {law && simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> } 

      {/* execute button */}
        <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
          { proposalStatus != 3 ?  
              <div className = "w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500"> 
                Vote has closed  
              </div>
              :
              hasVoted || voteReceived ? 
              <div className = "w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500"> 
                Account has voted  
              </div>
              :
              <div className = "w-full flex flex-row gap-2"> 
                <Button 
                  size={0} 
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
                  size={0} 
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
                  size={0} 
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
