"use client";

import React, { useEffect, useState } from "react"; 
import { useChains } from 'wagmi';
import { Mandate, Powers } from "@/context/types";
import HeaderMandate from '@/components/HeaderMandate';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';
import { useBlocks } from '@/hooks/useBlocks';
import { toEurTimeFormat, toFullDateFormat } from '@/utils/toDates';
import { useActionStore } from "@/context/store";

type UserItemProps = {
  powers: Powers;
  mandate: Mandate;
  actionId?: bigint;
  chainId: string;
  showLowerSection?: boolean;
  isEnabledAction?: boolean;
  children?: React.ReactNode;
};

export function UserItem({
  powers,
  mandate, 
  actionId,
  chainId, 
  showLowerSection = false,
  isEnabledAction = false,
  children 
}: UserItemProps) {
  const chains = useChains();
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId));
  const { timestamps, fetchTimestamps } = useBlocks();
  const [executionData, setExecutionData] = useState<{
    actionId: bigint;
    executedAt: bigint;
    fulfilled: boolean;
  } | null>(null);
  const [executionTimestamp, setExecutionTimestamp] = useState<number | null>(null);
  const action = useActionStore(); 
 

  // Find execution data for the specific actionId from powers.executedActions
  useEffect(() => {
    if (powers?.mandates) {
      const mandateExecutions = powers.mandates && powers.mandates?.length > 0 ? powers.mandates.flatMap(l => l.actions).filter(action => action?.mandateId == mandate.index) : []
      
      if (mandateExecutions) {
        let targetActionId: bigint | null = null;
        
        // If we have an actionId prop, use that
        if (actionId) {
          targetActionId = actionId;
        }
        
        if (targetActionId) {
          // Find the specific action in the executions
          const actionIndex = mandateExecutions.findIndex(action => BigInt(action?.actionId as string) === targetActionId);
          if (actionIndex !== -1) {
            const executedAt = mandateExecutions[actionIndex]?.fulfilledAt;
            if (executedAt) {
              setExecutionData({
                actionId: targetActionId,
                executedAt: executedAt,
                fulfilled: true // If it's in executedActions, it's fulfilled
              });
            }
          }
        }
      }
    }
  }, [actionId, powers?.mandates, mandate.index]);

  // Fetch timestamp for execution block
  useEffect(() => {
    if (executionData?.executedAt) {
      fetchTimestamps([executionData.executedAt], chainId);
    }
  }, [executionData?.executedAt, chainId, fetchTimestamps]);

  // Get timestamp from fetched data
  useEffect(() => {
    if (executionData?.executedAt) {
      const timestampData = timestamps.get(`${chainId}:${executionData.executedAt}`);
      if (timestampData?.timestamp) {
        setExecutionTimestamp(Number(timestampData.timestamp));
      }
    }
  }, [executionData?.executedAt, timestamps, chainId]);

  // Helper function to abbreviate transaction hash
  const abbreviateTxHash = (hash: string) => {
    return `${hash.slice(0, 8)}...${hash.slice(-6)}`;
  };

  return (
    <div className="w-full">
      <section className="w-full rounded-md overflow-hidden">
        {/* Two-column layout */}
        <div className="w-full flex flex-col lg:flex-row">
          {/* Left column - Mandate data */}
          <div className="w-full lg:w-1/2 py-2 ps-4 pe-2">
            <HeaderMandate
              powers={powers}
              mandateName={mandate?.nameDescription ? `#${Number(mandate.index)}: ${mandate.nameDescription.split(':')[0]}` : `#${Number(mandate.index)}`}
              roleName={mandate?.conditions && powers ? bigintToRole(mandate.conditions.allowedRole, powers) : ''}
              numHolders={mandate?.conditions && powers ? bigintToRoleHolders(mandate.conditions.allowedRole, powers).toString() : ''}
              description={mandate?.nameDescription ? mandate.nameDescription.split(':')[1] || '' : ''}
              contractAddress={mandate.mandateAddress}
              blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
            />
          </div>

          {/* Right column - Execution data or Enabled Action */}
          <div className="w-full lg:w-1/2 py-2 ps-4 pe-2 text-right flex flex-col">
            
            {/* Enabled Action display */}
            {isEnabledAction ? (
                <div className="flex items-start justify-end mb-1">
                  <span className="text-xs font-medium text-yellow-600 bg-yellow-100 px-2 py-1 rounded">
                    ENABLED ACTION
                  </span>
                </div>
            ) : (
              <>
                {/* Transaction date and time */}
                {executionTimestamp && (
                  <div className="mb-4 py-1">
                    <div className="text-base text-slate-800">
                      {toFullDateFormat(executionTimestamp)} at {toEurTimeFormat(executionTimestamp)}
                    </div>
                  </div>
                )}

                {/* Transaction hash with link */}
                {executionData && (
                  <div className="mt-auto ">
                    {/* <a
                      href={`${supportedChain?.blockExplorers?.default.url}/tx/${executionData.actionId.toString()}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-800"
                    > */}
                    <div className="inline-flex items-center gap-1 text-xs text-slate-500">
                      Action ID: {abbreviateTxHash(executionData.actionId.toString())}
                      {/* <ArrowUpRightIcon className="w-3 h-3" /> */}
                    {/* </a> */}
                    </div>
                  </div>
                )}

                {/* Proposal status */}
                {/* {actionId && !executionData && (
                  <div className="flex justify-end">
                    {(() => {
                      // const proposal = powers?.mandates && powers.mandates?.length > 0 ? powers.mandates.flatMap(l => l.actions).find(a => BigInt(a?.actionId as string) === actionId) : undefined;
                      
                      const layout = "w-full max-w-36 h-6 flex flex-row justify-center items-center px-2 py-1 text-bold rounded-md text-xs";
                      
                      if (state === undefined || state === null) {
                        return <div className={`${layout} text-slate-500 bg-slate-100`}>Non Existent</div>;
                      } else if (state === 0) {
                        return <div className={`${layout} text-blue-500 bg-blue-100`}>Active</div>;
                      } else if (state === 3) {
                        return <div className={`${layout} text-green-500 bg-green-100`}>Succeeded</div>;
                      } else if (state === 1) {
                        return <div className={`${layout} text-orange-500 bg-orange-100`}>Cancelled</div>;
                      } else if (state === 2) {
                        return <div className={`${layout} text-red-500 bg-red-100`}>Defeated</div>;
                      } else if (state === 4) {
                        return <div className={`${layout} text-slate-700 bg-slate-200`}>Requested</div>;
                      } else if (state === 5) {
                        return <div className={`${layout} text-slate-700 bg-slate-200`}>Fulfilled</div>;
                      } else if (state === 6) {
                        return <div className={`${layout} text-slate-500 bg-slate-100`}>Non Existent</div>;
                      } else {
                        return <div className="text-xs text-slate-500">Non Existent</div>;
                      }
                    })()}
                  </div>
                )} */}
              </>
            )}
          </div>
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
