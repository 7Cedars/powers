"use client";

import React, { useEffect } from "react";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation, Powers, Status } from "@/context/types";
import { useParams } from "next/navigation";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicForm } from '@/components/DynamicForm';
import { useActionStore } from "@/context/store";
import { useWallets } from "@privy-io/react-auth";
import { useLaw } from "@/hooks/useLaw";

type LawBoxProps = {
  powers: Powers;
  law: Law;
  checks: Checks;
  statusChecks: Status;
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
  onPropose?: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
};

export function LawBox({powers, law, checks, params, status, simulation, selectedExecution, onChange, onSimulate, onExecute, onPropose}: LawBoxProps) {
  const action = useActionStore();
  const {actionVote, fetchVoteData} = useLaw();
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const {wallets} = useWallets();

  useEffect(() => {
    if (action.actionId && wallets.length > 0) {
      fetchVoteData(action, powers as Powers)
    }
  }, [action, wallets])

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

      {/* Proposal Section - only show when quorum > 0 */}
      {law?.conditions?.quorum != 0n && (
        <div className="w-full px-6 py-2" help-nav-item="propose-or-vote">          
          <div className="w-full">
            <Button 
              size={0} 
              role={6} 
              onClick={() => onPropose && onPropose(action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string) }
              filled={false}
              selected={true}
              statusButton={
                (checks?.authorised && action?.upToDate && actionVote?.state == 0) ? status :  'disabled'
              }
            >
              {!action?.upToDate || !checks?.delayPassed || !checks?.throttlePassed || !checks?.actionNotFulfilled || !checks?.lawFulfilled || !checks?.lawNotFulfilled
                ? "Passed check needed to make proposal"
                : !checks?.authorised 
                  ? "Not authorised to make proposal"
                  : actionVote?.state != 0 
                    ? "Action already proposed"
                    : `Create proposal for '${shorterDescription(law?.nameDescription, "short")}'`
              }
            </Button>
          </div>
        </div>
      )}

      {/* execute button */}
        <div className="w-full h-fit px-6 py-2 pb-6" help-nav-item="execute-action">
          <Button 
            size={0} 
            role={6}
            onClick={() => {
              if (checks?.authorised && action) {
                onExecute(action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string)
              }
              // Do nothing if not authorized
            }} 
            filled={false}
            selected={true}
            statusButton={
              (action?.upToDate && checks?.delayPassed && checks?.throttlePassed && checks?.actionNotFulfilled && checks?.lawFulfilled && checks?.lawNotFulfilled && 
               (law?.conditions?.quorum == 0n || checks?.proposalPassed) && 
               checks?.authorised) ? status : 'disabled' 
              }> 
            {!action?.upToDate || !checks?.delayPassed || !checks?.throttlePassed || !checks?.actionNotFulfilled || !checks?.lawFulfilled || !checks?.lawNotFulfilled
              ? "Passed check needed to execute"
              : law?.conditions?.quorum != 0n && !checks?.proposalPassed
                ? "Passed proposal needed for execution"
                : !checks?.authorised 
                  ? "Not authorised to execute"
                  : "Execute"}
          </Button>
        </div>
      </section>
    </main>
  );
}