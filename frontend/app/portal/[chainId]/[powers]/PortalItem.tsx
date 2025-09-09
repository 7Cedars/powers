"use client";

import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChains } from 'wagmi';
import { Law, Powers } from "@/context/types";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';

type PortalItemProps = {
  powers: Powers;
  law: Law;
  selectedExecution?: {
    log: {
      transactionHash: string;
    };
  };
  chainId: string;
  showLowerSection?: boolean;
  children?: React.ReactNode;
};

export function PortalItem({
  powers, 
  law, 
  selectedExecution, 
  chainId, 
  showLowerSection = false, 
  children 
}: PortalItemProps) {
  const chains = useChains();
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId));

  return (
    <div className="w-full">
      <section className="w-full rounded-md overflow-hidden">
        {/* Header section - similar to LawBox */}
        <div className="w-full py-2 ps-4 pe-2">
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

        {/* Optional lower section */}
        {showLowerSection && (
          <div className="w-full bg-slate-50 p-6">
            {children || (
              <div className="text-center text-slate-500 text-sm">
                Content will be added here later
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
