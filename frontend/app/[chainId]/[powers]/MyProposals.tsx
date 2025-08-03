`use client`

import { setAction } from "@/context/store";
import { Law, Powers, Status, Action } from "@/context/types";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { useBlocks } from "@/hooks/useBlocks";
import { useEffect, useRef } from "react";
import { toFullDateFormat, toEurTimeFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

type MyProposalProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  proposals: Action[] | undefined; 
  powers: Powers | undefined;
  status: Status;
  onFetchProposals: () => void;
}

type ProposalAndLaw = {
  proposal: Action; 
  law: Law; 
}

export function MyProposals({ hasRoles, authenticated, proposals, powers, status, onFetchProposals}: MyProposalProps ) {
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.role > 0).map(hasRole => hasRole.role)
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const hasFetchedRef = useRef(false)

  // console.log("@MyProposals: waypoint 0", {hasRoles, authenticated, proposals, powers, status})

  // Auto-fetch proposals on initialization
  useEffect(() => {
    if (powers && authenticated && !hasFetchedRef.current) {
      hasFetchedRef.current = true
      onFetchProposals()
    }
  }, [powers, authenticated])

  useEffect(() => {
      // Ensure consistent block number handling - convert to bigint for both storage and lookup
      const blocks = proposals?.map(proposal => {
        // Handle different possible types for voteEnd
        const voteStartValue = typeof proposal.voteStart === 'bigint' 
          ? proposal.voteStart 
          : BigInt(proposal.voteStart as unknown as string)
        return voteStartValue
      }).filter(block => block !== undefined)
      
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks as bigint[], chainId)
      }
  }, [proposals, chainId])


  // bit convoluted, can be optimised. // £todo
  const active = proposals?.map((proposal: Action) => {
    const law = powers?.laws?.find(law => law.index == proposal.lawId)
    if (law && law.conditions && law.conditions.allowedRole != undefined && myRoles.includes(law.conditions.allowedRole) && proposal.state == 0) {
      return {
        proposal: proposal, 
        law: law
      } as ProposalAndLaw
    }
  }) 
  const activeProposals = active?.filter(item => item != undefined)
  // console.log("@MyProposals: waypoint 1", {activeProposals})

  const handleSelectProposal = (item: ProposalAndLaw) => {
    setAction({
      description: item.proposal.description,
      callData: item.proposal.callData,
      nonce: item.proposal.nonce,
      lawId: item.proposal.lawId,
      caller: item.proposal.caller as `0x${string}`,
      dataTypes: item.law.params?.map(param => param.dataType),
      upToDate: true
    })
    router.push(`/${chainId}/${powers?.contractAddress}/proposals/${item.proposal.actionId}`)
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-68 overflow-hidden"> 
      <div className="w-full border-b border-slate-300 p-2 bg-slate-100">
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600 w-44">
            Active proposals
          </div>
          <div className="flex flex-row gap-2">
            <button
              onClick={() => {
                onFetchProposals()
              }}
              className={`w-full h-full flex justify-center items-center py-1`}  
            >
              <ArrowPathIcon 
                className="w-4 h-4 text-slate-800 aria-selected:animate-spin"
                aria-selected={status == "pending"}
              />
            </button>
            <button
              onClick={() => 
                { 
                  // here have to set deselectedRoles
                  router.push(`/${chainId}/${powers?.contractAddress}/proposals`)
                }
              }  
            > 
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
              />
          </button> 
      </div>
      </div> 
      </div>
       {
        activeProposals && activeProposals.length > 0 ? 
          <div className="w-full h-fit lg:max-h-48 max-h-32 flex flex-col justify-start items-center overflow-hidden">
           <div className="w-full overflow-x-auto overflow-y-auto">
            <table className="w-full table-auto text-sm">
            <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
            <tr className="w-full text-xs font-light text-left text-slate-500">
                <th className="px-2 py-3 font-light w-32"> Date </th>
                <th className="px-2 py-3 font-light w-auto"> Law </th>
                <th className="px-2 py-3 font-light w-24"> Action ID </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
          {
            activeProposals?.map((item: ProposalAndLaw, i) => 
                <tr
                  key={i}
                  className="text-sm text-left text-slate-800"
                >
                  {/* Vote End Date */}
                  <td className="px-2 py-3 w-32">
                    <a
                      href="#"
                      onClick={e => { e.preventDefault(); handleSelectProposal(item); }}
                      className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                    >
                      {(() => {
                        // Ensure consistent block number format for lookup
                        const voteEndBlock = typeof item.proposal.voteEnd === 'bigint' 
                          ? item.proposal.voteEnd 
                          : BigInt(item.proposal.voteEnd as unknown as string)
                        
                        const timestampData = timestamps.get(`${chainId}:${voteEndBlock}`)
                        const timestamp = timestampData?.timestamp
                        
                        if (!timestamp || timestamp <= 0n) {
                          return 'Loading...'
                        }
                        
                        const timestampNumber = Number(timestamp)
                        if (isNaN(timestampNumber) || timestampNumber <= 0) {
                          return 'Invalid date'
                        }
                        
                        try {
                          return `${toFullDateFormat(timestampNumber)}: ${toEurTimeFormat(timestampNumber)}`
                        } catch (error) {
                          console.error('Date formatting error:', error, { timestamp, timestampNumber })
                          return 'Date error'
                        }
                      })()}
                    </a>
                  </td>
                  
                  {/* Law */}
                  <td className="px-2 py-3 w-auto">
                    <div className="truncate text-slate-500 text-xs">
                      {shorterDescription(item.law.nameDescription, "short")}
                    </div>
                  </td>
                  
                  {/* Action ID */}
                  <td className="px-2 py-3 w-24">
                    <div className="truncate text-slate-500 text-xs font-mono">
                      {item.proposal.actionId.toString()}
                    </div>
                  </td>
                </tr>
            )
          }
        </tbody>
        </table>
           </div>
          </div>
      :
      <div className = "w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
        No active proposals found
      </div>
    }
    </div>
  )
}