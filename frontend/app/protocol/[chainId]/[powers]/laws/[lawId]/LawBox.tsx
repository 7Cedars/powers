"use client";

import React from "react";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation, Powers, Status } from "@/context/types";
import { SimulationBox } from "@/components/SimulationBox";
import { useParams, useRouter } from "next/navigation";
import { hashAction } from "@/utils/hashAction";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicForm } from '@/components/DynamicForm';
import { useActionStore } from "@/context/store";

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
};

export function LawBox({powers, law, checks, params, status, simulation, selectedExecution, onChange, onSimulate, onExecute}: LawBoxProps) {
  const action = useActionStore();
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))

  return (
    <main className="w-full" help-nav-item="law-input">
      <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600`} >
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
        powers={powers}
        law={law}
        checks={checks}
        params={params}
        simulation={simulation}
        selectedExecution={selectedExecution}
        status={status}
        onChange={onChange}
        onSimulate={onSimulate}
        onExecute={onExecute}
      />

      {/* Proposal Section - only show when quorum > 0 */}
      {law?.conditions?.quorum != 0n && (
        <div className="w-full px-6 py-2" help-nav-item="propose-or-vote">          
          <div className="w-full">
            <Button 
              size={0} 
              role={6}
              onClick={() => {
                if (checks?.proposalExists && action) {
                  // console.log("@DynamicForm: Proposal section", {law, action})
                  const actionId = hashAction(law?.index, action.callData, BigInt(action.nonce))
                  // Navigate to view the existing proposal
                  router.push(`/protocol/${chainId}/${law?.powers}/proposals/${actionId}`)
                } else if (checks?.authorised) {
                  // Navigate to create a new proposal
                  router.push(`/protocol/${chainId}/${law?.powers}/proposals/new`)
                }
                // Do nothing if not authorized and no proposal exists
              }}
              filled={false}
              selected={true}
              statusButton={
                (action?.upToDate && checks?.delayPassed && checks?.throttlePassed && checks?.actionNotCompleted && checks?.lawCompleted && checks?.lawNotCompleted && checks?.authorised) ? 'idle' :  'disabled'
              }
            >
              {!action?.upToDate || !checks?.delayPassed || !checks?.throttlePassed || !checks?.actionNotCompleted || !checks?.lawCompleted || !checks?.lawNotCompleted
                ? "Passed check needed to make proposal"
                : !checks?.authorised 
                  ? "Not authorised to make proposal"
                  : checks?.proposalExists 
                    ? "View proposal"
                    : `Create proposal for '${shorterDescription(law?.nameDescription, "short")}'`
              }
            </Button>
          </div>
        </div>
      )}

      {/* fetchSimulation output */}
      {simulation && <SimulationBox law = {law} simulation = {simulation} />}

      {/* execute button */}
        <div className="w-full h-fit px-6 py-2 pb-6" help-nav-item="execute-action">
          <Button 
            size={0} 
            role={6}
            onClick={() => {
              if (checks?.authorised && action) {
                onExecute(action.paramValues ? action.paramValues : [], BigInt(action.nonce), action.description)
              }
              // Do nothing if not authorized
            }} 
            filled={false}
            selected={true}
            statusButton={
              (action?.upToDate && checks?.delayPassed && checks?.throttlePassed && checks?.actionNotCompleted && checks?.lawCompleted && checks?.lawNotCompleted && 
               (law?.conditions?.quorum == 0n || checks?.proposalPassed) && 
               checks?.authorised) ? status : 'disabled' 
              }> 
            {!action?.upToDate || !checks?.delayPassed || !checks?.throttlePassed || !checks?.actionNotCompleted || !checks?.lawCompleted || !checks?.lawNotCompleted
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