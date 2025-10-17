"use client";

import React, {  useEffect, useState } from "react";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation, Powers, Status } from "@/context/types";
import { SimulationBox } from "@/components/SimulationBox";
import { useParams } from "next/navigation";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicForm } from '@/components/DynamicForm';
import { useActionStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useWallets } from "@privy-io/react-auth";

type LawBoxProps = {
  powers: Powers;
  law: Law;
  checks: Checks;
  params: {
    varName: string;
    dataType: DataType;
    }[]; 
  simulation?: LawSimulation;
  selectedExecution?: Execution | undefined;
  status: Status; 
  // onChange: (input: InputType | InputType[]) => void;
  onChange: () => void;
  onSimulate: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
  onExecute: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
  onPropose: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
};

export function LawBox({powers, law, checks, params, status, simulation, selectedExecution, onChange, onSimulate, onExecute, onPropose}: LawBoxProps) {
  const action = useActionStore();
  const { chainId, powers: powersAddress } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const {wallets} = useWallets();
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const [logSupport, setLogSupport] = useState<bigint>()
  const { hasVoted, castVote, checkHasVoted } = useLaw(); 
  const populatedAction = law?.actions?.find(action => BigInt(action.actionId) == BigInt(action.actionId));

  // console.log("@LawBox, waypoint 0", {action, checks, law})

  useEffect(() => {
    if (action.actionId && wallets.length > 0 && powersAddress) {
      checkHasVoted(
        BigInt(action.actionId), 
        wallets[0].address as `0x${string}`,
        powersAddress as `0x${string}`
      )
    }
  }, [action.actionId, wallets, powersAddress, checkHasVoted])

  return (
    <main className="w-full" help-nav-item="law-input">
      <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 pb-4`} >
      {/* title - replaced with HeaderLaw */}
      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
        <HeaderLaw
          powers={powers}
          lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
          contractAddress={law.lawAddress}
          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
        />
        {selectedExecution && (
          <a
            href={`${supportedChain?.blockExplorers?.default.url}/tx/${selectedExecution.log.transactionHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full"
          >
            <div className="flex flex-row gap-1 items-center justify-start mt-1">
              <div className="text-left text-sm text-slate-500 break-all w-fit">
                Tx: {selectedExecution.log.transactionHash}
              </div>
              <ArrowUpRightIcon className="w-4 h-4 text-slate-500" />
            </div>
          </a>
        )}
      </div>

      {/* dynamic form */}
      <DynamicForm
        law={law}
        params={params}
        status={status}
        onChange={onChange}
        onSimulate={onSimulate} 
      />

      {/* fetchSimulation output. Only shows when action is uptodata */}
      {
      simulation && action?.upToDate && <SimulationBox law = {law} simulation = {simulation} />}

      {/* Here dynamic button conditional on status of action  */}
      <div className="w-full pt-4">
      {
      // option 1: When action does not exist, and needs a vote, create proposal button
      Number(law?.conditions?.quorum) > 0 && populatedAction?.state == 8 && action?.upToDate ? (
          <div className="w-full px-6 py-2" help-nav-item="propose-or-vote">          
            <div className="w-full">
              <Button 
                size={0} 
                role={6}
                onClick={() => { onPropose && onPropose(action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string) } }
                filled={false}
                selected={true}
                statusButton={
                  (checks?.authorised   ? status :  'disabled' )
                }
              >
                { !checks?.authorised ? "Not authorised to make proposal" : `Create proposal for '${shorterDescription(law?.nameDescription, "short")}'`} 
              </Button>
            </div>
          </div>
          ) 
        // option 2: When action does not exist and does not need a vote, execute button 
        : Number(law?.conditions?.quorum) == 0 && populatedAction?.state == 8 && action?.upToDate ? (
          <div className="w-full h-fit px-6 py-2 pb-6" help-nav-item="execute-action">
            <Button 
              size={0} 
              role={6}
              onClick={() => onExecute(action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string)}
              filled={false}
              selected={true}
              statusButton= {status}> 
              Execute
            </Button>
        </div>
        )
        // option 2: When action does exist and has a succeeded state, execute button
        :  Number(law?.conditions?.quorum) > 0 && action?.state == 5 && action?.upToDate ? (
          <div className="w-full h-fit px-6 py-2 pb-6" help-nav-item="execute-action">
            <Button 
              size={0} 
              role={6}
              onClick={() => onExecute(action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string)}
              filled={false}
              selected={true}
              statusButton= {status}> 
              Execute
            </Button>
        </div>
        )
        : 
        populatedAction?.state == 4 && action?.upToDate ?
        <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
          <div className = "w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500"> 
            Action defeated  
          </div>
        </div>
        // option 3: When action exists, and is active, show vote button
        : populatedAction?.state == 3 && action?.upToDate ? (
          <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
          { hasVoted ? 
              <div className = "w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500"> 
                Account has voted  
              </div>
              :
              <div className = "w-full flex flex-row gap-2"> 
                <Button 
                  size={0} 
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(BigInt(populatedAction.actionId), 1n, powers as Powers)
                    setLogSupport(1n)
                  }} 
                  statusButton={status == 'pending' && logSupport == 1n ? 'pending' : 'idle'}
                  > 
                  For
                </Button>
                <Button 
                  size={0} 
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(BigInt(populatedAction.actionId), 0n, powers as Powers)
                    setLogSupport(0n)
                  }} 
                  statusButton={status == 'pending' && logSupport == 0n ? 'pending' : 'idle'} 
                  >
                    Against
                </Button>
                <Button   
                  size={0} 
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(BigInt(populatedAction.actionId), 2n, powers as Powers)
                    setLogSupport(2n)
                  }} 
                  statusButton={status == 'pending' && logSupport == 2n ? 'pending' : 'idle'} 
                  > 
                    Abstain
                </Button>
              </div> 
          }
        </div>
        )
        : 
        null  
      }
      </div>
      </section>
    </main>
  );
}