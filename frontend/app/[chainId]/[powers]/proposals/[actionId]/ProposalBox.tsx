"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useActionStore, setAction, setError } from "@/context/store";
import { Button } from "@/components/Button";
import { useLaw } from "@/hooks/useLaw";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { Action, Checks, Law, Powers, Status } from "@/context/types";
import { StaticInput } from "../../../../../components/StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { LoadingBox } from "@/components/LoadingBox";
import { useBlockNumber } from "wagmi";
import { useChecks } from "@/hooks/useChecks";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { powersAbi } from "@/context/abi";
import HeaderLaw from '@/components/HeaderLaw';
import { useChains } from 'wagmi';
import { parseChainId } from '@/utils/parsers';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';

const roleColor = [  
  "#007bff",
  "#dc3545",
  "#ffc107",
  "#6f42c1",
  "#28a745",
  "#fd7e14",
  "#17a2b8",
]

export function ProposalBox({
  powers, 
  lawId, 
  checks, 
  status, 
  onCheck, 
  proposalStatus
}: {
  powers?: Powers, 
  lawId: bigint, 
  checks?: Checks, 
  status: Status, 
  onCheck: (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => void, 
  proposalStatus: number,
}) {
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposal, error, hasVoted, castVote, checkHasVoted} = useProposal();
  const [voteReceived, setVoteReceived] = useState<boolean>(false);
  const law = powers?.laws?.find(law => law.index == lawId)
  const chains = useChains();
  const supportedChain = chains.find(chain => chain.id == parseChainId(powers?.contractAddress ? powers.contractAddress.slice(0, 10) : ''));

  const [logSupport, setLogSupport] = useState<bigint>()
  const {wallets} = useWallets();
  const {data: blockNumber} = useBlockNumber();
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
        <div className="w-full mt-4 flex flex-row justify-center items-center ps-3 pe-6 gap-3">
          <label htmlFor="nonce" className="text-xs text-slate-600 ps-3 min-w-20">Nonce</label>
          <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-2 outline outline-1 outline-slate-300">
            <input 
              type="text" 
              name="nonce"
              className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0"  
              id="nonce" 
              value={action.nonce.toString()}
              disabled={true}
              />
          </div>
        </div>
        
        {/* reason */}
        <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3 min-h-24">
          <label htmlFor="reason" className="text-xs text-slate-600 ps-3 min-w-20 pt-1">Description</label>
          <div className="w-full flex items-center rounded-md bg-white outline outline-1 outline-slate-300">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={25} 
                value={action.description}
                className="w-full py-1.5 ps-2 pe-3 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
                placeholder="Enter URI to file with notes on the action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      {law && simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> } 

      {/* execute button */}
        <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
          { proposalStatus != 0 ?  
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
