"use client";

import React, {  useEffect, useState } from "react";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId } from "@/utils/parsers";
import { Action, Checks, DataType, Execution, Law, Powers, Status } from "@/context/types";
import { useParams } from "next/navigation";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicForm } from '@/components/DynamicForm';
import { useActionStore } from "@/context/store";
import { DynamicActionButton } from "./DynamicActionButton";
import { useChecks } from "@/hooks/useChecks";

type LawBoxProps = {
  powers: Powers;
  law: Law;
  params: {
    varName: string;
    dataType: DataType;
    }[]; 
  selectedExecution?: Execution | undefined;
  status: Status; 
};

export function LawBox({powers, law, params, status, selectedExecution }: LawBoxProps) {
  const action = useActionStore();
  const { chainId, powers: powersAddress } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const [populatedAction, setPopulatedAction] = useState<Action | undefined>(undefined);
  const { fetchChecks, checks } = useChecks();

  console.log("@LawBox, waypoint 0", {action, checks, law, populatedAction})

  useEffect(() => {
    if (action.upToDate && action.actionId) {
      // First try to find the action in law.actions (for actions that exist on chain)
      const actionFromLaw = law?.actions?.find(a => BigInt(a.actionId) == BigInt(action.actionId));
      
      // If found in law.actions, use it (it has full data from chain)
      // Otherwise, use the action from store (for newly simulated actions not yet on chain)
      if (actionFromLaw) {
        setPopulatedAction(actionFromLaw);
      } else {
        // Convert store action to Action type with state from store
        setPopulatedAction({
          ...action,
          state: action.state || 0,
          actionId: action.actionId
        } as Action);
      }
    }
  }, [action.upToDate, law?.actions, action.actionId, action.state, action])

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
      <DynamicForm law={law} params={params} status={status} checks={checks as Checks} onCheck={fetchChecks} />

      {/* Here dynamic button conditional on status of action  */}
      <DynamicActionButton checks={checks as Checks} /> 

      </section>
    </main>
  );
}