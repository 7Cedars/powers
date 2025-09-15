'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Powers, Action, Law, Status } from '@/context/types'
import { ArrowPathIcon, ArrowLeftIcon } from '@heroicons/react/24/outline'
import { PortalItem } from './PortalItem'
import { useParams } from 'next/navigation'
import { useProposal } from '@/hooks/useProposal'
import { ProposalBox } from '@/components/ProposalBox'
import { Voting } from '@/components/Voting'
import { Votes } from '@/components/Votes'
import { useChecks } from '@/hooks/useChecks'
import { setAction } from '@/context/store'
import { useChains } from 'wagmi'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'


type IncomingProps = {
  hasRoles: {role: bigint, since: bigint}[]
  powers: Powers
  proposals: Action[]
  loading: boolean
  onRefresh: () => void
}

export default function Incoming({hasRoles, powers, proposals, loading, onRefresh}: IncomingProps) {
  const { chainId } = useParams<{ chainId: string }>()
  const { getProposalsState } = useProposal()
  const { fetchChainChecks, status: statusChecks } = useChecks()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))
  
  // State for selected proposal
  const [selectedProposal, setSelectedProposal] = useState<Action | null>(null)

  console.log("@Incoming, waypoint 0", {proposals, powers})

  useEffect(() => {
    if (powers) {
      getProposalsState(powers)
    }
  }, [powers])

  useEffect(() => {
    if (powers) {
      onRefresh()
    }
  }, [ ])

  // Handle proposal click
  const handleProposalClick = (proposal: Action) => {
    setSelectedProposal(proposal)
    // Set the action in the store for ProposalBox
    setAction(proposal)
  }

  // Wrapper for fetchChainChecks to match the expected signature
  const handleCheck = async (law: Law, action: Action, wallets: any[], powers: Powers) => {
    if (action && wallets.length > 0) {
      await fetchChainChecks(
        law.index,
        action.callData as `0x${string}`,
        BigInt(action.nonce),
        wallets,
        powers
      )
    }
  }

  // If a proposal is selected, show the unified item view
  if (selectedProposal) {
    const law = powers.laws?.find(law => law.index === BigInt(selectedProposal.lawId)) as Law
    
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSelectedProposal(null)}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to incoming proposals
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] overflow-y-auto">
            <div className="space-y-4">
              {/* ProposalBox section */}
              <section className="w-full">
                <ProposalBox
                  powers={powers}
                  lawId={BigInt(selectedProposal.lawId)}
                  checks={undefined} // Will be fetched by ProposalBox if needed
                  status={statusChecks}
                  onCheck={handleCheck}
                  proposalStatus={selectedProposal.state || 0}
                />
              </section>

              {/* Voting and Votes section - side by side on wide screens */}
              <div className="w-full flex flex-col lg:flex-row gap-4">
                <section className="w-full lg:w-1/2">
                  <Voting 
                    action={selectedProposal} 
                    powers={powers} 
                    status={statusChecks as Status}
                  />
                </section>

                <section className="w-full lg:w-1/2">
                  <Votes 
                    actionId={selectedProposal.actionId}
                    action={selectedProposal}
                    powers={powers}
                    status={statusChecks as Status}
                  />
                </section>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full mx-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-800">Incoming</h2>
              <p className="text-sm text-slate-600">Active proposals and enabled actions requiring your attention</p>
            </div>
            <button 
              onClick={onRefresh}
              disabled={loading}
              className="p-2 text-slate-500 hover:text-slate-700 transition-colors disabled:opacity-50"
            >
              <ArrowPathIcon className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
        
        {loading ? (
          <div className="p-4">
            <div className="flex items-center justify-center py-8">
              <div className="text-sm text-slate-500">Loading active proposals...</div>
            </div>
          </div>
        ) : proposals.length === 0 ? (
          <div className="p-4">
            <div className="text-center py-8">
              <p className="text-sm text-slate-500 italic">
                No active proposals requiring your attention
              </p>
            </div>
          </div>
        ) : (
          <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
            {powers.proposals?.map((proposal: Action) => (
              (proposal.state == 0 || proposal.state == 3) && (
              <div 
                key={`${proposal.actionId}-${proposal.lawId}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => handleProposalClick(proposal)}
              >
                <PortalItem
                  powers={powers}
                  law={powers.laws?.find(law => law.index === BigInt(proposal.lawId)) as Law}
                  chainId={chainId as string}
                  showLowerSection={false}
                  actionId={BigInt(proposal.actionId)}
                />
              </div>
              )
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
