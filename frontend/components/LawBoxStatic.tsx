"use client";

import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi'
import { parseChainId } from "@/utils/parsers";
import { Checks, Execution, Law, Powers } from "@/context/types";
import { useParams } from "next/navigation";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { DynamicActionButton } from "./DynamicActionButton";
import { StaticForm } from "./StaticForm";
import { useChecks } from "@/hooks/useChecks";

type LawBoxStaticProps = {
  powers: Powers;
  law: Law;
  selectedExecution?: Execution | undefined;
};

export function LawBoxStatic({powers, law, selectedExecution }: LawBoxStaticProps) {
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId)) 
  const { fetchChecks, checks } = useChecks();
  
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
      <StaticForm law={law} onCheck={fetchChecks} />

      {/* Here dynamic button conditional on status of action  */}
      <DynamicActionButton checks={checks as Checks} /> 

      </section>
    </main>
  );
}