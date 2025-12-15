"use client";

import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId } from "@/utils/parsers";
import { Checks, DataType, Execution, Mandate, Powers, Status } from "@/context/types";
import { useParams } from "next/navigation";
import HeaderMandate from '@/components/HeaderMandate';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicForm } from '@/components/DynamicForm';
import { DynamicActionButton } from "./DynamicActionButton";
import { useChecks } from "@/hooks/useChecks";

type MandateBoxProps = {
  powers: Powers;
  mandate: Mandate;
  params: {
    varName: string;
    dataType: DataType;
    }[]; 
  selectedExecution?: Execution | undefined;
  status: Status; 
};

export function MandateBox({powers, mandate, params, status, selectedExecution }: MandateBoxProps) {
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const { fetchChecks, checks } = useChecks();

  return (
    <main className="w-full" help-nav-item="mandate-input">
      <section className={`w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 pb-4`} >
      {/* title - replaced with HeaderMandate */}
      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
        <HeaderMandate
          powers={powers}
          mandateName={mandate?.nameDescription ? `#${Number(mandate.index)}: ${mandate.nameDescription.split(':')[0]}` : `#${Number(mandate.index)}`}
          roleName={mandate?.conditions && powers ? bigintToRole(mandate.conditions.allowedRole, powers) : ''}
          numHolders={mandate?.conditions && powers ? bigintToRoleHolders(mandate.conditions.allowedRole, powers).toString() : ''}
          description={mandate?.nameDescription ? mandate.nameDescription.split(':')[1] || '' : ''}
          contractAddress={mandate.mandateAddress}
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
      <DynamicForm mandate={mandate} params={params} status={status} checks={checks as Checks} onCheck={fetchChecks} />

      {/* Here dynamic button conditional on status of action  */}
      <DynamicActionButton checks={checks as Checks} /> 

      </section>
    </main>
  );
}