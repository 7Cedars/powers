"use client";

import React, { useEffect, useState } from "react";
import { setAction } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter, useParams } from "next/navigation";
import { Powers, Action } from "@/context/types";
import { parseProposalStatus, parseRole, shorterDescription } from "@/utils/parsers";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintTo";
import { LoadingBox } from "@/components/LoadingBox";
import { useProposal } from "@/hooks/useProposal";
import { useBlocks } from "@/hooks/useBlocks";
import { useChecks } from "@/hooks/useChecks";

// NB: need to delete action from store? Just in case? 
export function ProposalList({powers, status, onRefresh}: {powers: Powers | undefined, status: string, onRefresh?: () => void}) {
  const router = useRouter();
  const {getProposalsState} = useProposal()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { chainId } = useParams<{ chainId: string }>()
  const possibleStatus: string[] = ['0', '1', '2', '3', '4', '5']; 
  const [ deselectedStatus, setDeselectedStatus] = useState<string[]>([])
  
  useEffect(() => {
    if (powers) {
      getProposalsState(powers)
    }
  }, [powers])

  // console.log("@ProposalList: waypoint 0", {powers, timestamps})

  useEffect(() => {
    if (powers?.proposals) {
      // Ensure consistent block number handling - convert to bigint for both storage and lookup
      const blocks = powers?.proposals?.map(proposal => {
        // Handle different possible types for voteEnd
        const voteEndValue = typeof proposal.voteEnd === 'bigint' 
          ? proposal.voteEnd 
          : BigInt(proposal.voteEnd as unknown as string)
        return voteEndValue
      }).filter(block => block !== undefined)
      
      // console.log("@ProposalList: waypoint 1", {blocks})
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks as bigint[], chainId)
      }
    }
  }, [powers?.proposals])

  const handleStatusSelection = (proposalStatus: string) => {
    let newDeselection: string[] = []
    if (deselectedStatus.includes(proposalStatus)) {
      newDeselection = deselectedStatus.filter(option => option !== proposalStatus)
    } else {
      newDeselection = [...deselectedStatus, proposalStatus]
    }
    setDeselectedStatus(newDeselection)
  };

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Header with roles - matching LogsList.tsx structure */}
      {/* <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-4 overflow-y-scroll"> */}
        {/* <div className="text-slate-800 text-center text-lg">
          Proposals history
        </div> */}
        {/* {onRefresh && (
          <div className="w-8 h-8">
            <Button
              size={0}
              showBorder={true}
              onClick={onRefresh}
            >
              <ArrowPathIcon className="w-5 h-5" />
            </Button>
          </div>
        )} */}
      {/* </div> */}

      {/* Status filter bar */}
      <div className="w-full flex flex-row gap-6 justify-between items-center py-4 overflow-y-scroll border-b border-slate-200 px-4">
      {
        possibleStatus.map((option, i) => {
          return (
            <button 
            key = {i}
            onClick={() => handleStatusSelection(option)}
            className="w-fit h-full hover:text-slate-400 text-sm aria-selected:text-slate-800 text-slate-300"
            aria-selected = {!deselectedStatus?.includes(option)}
            >  
              <p className="text-sm text-left"> {parseProposalStatus(option)} </p>
          </button>
          )
        })
      }
      </div>

      {/* Table content - matching LogsList.tsx structure */}
      {status == "pending" ? 
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox /> 
        </div>
        : 
        powers?.proposals && powers?.proposals.length > 0 ? 
          <div className="w-full h-fit max-h-full flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="ps-4 px-2 py-3 font-light w-32"> Vote ends </th>
                    <th className="px-2 py-3 font-light w-auto"> Law </th>
                    <th className="px-2 py-3 font-light w-24"> Status </th>
                    <th className="px-2 py-3 font-light w-auto"> Description </th>
                    <th className="px-2 py-3 font-light w-20"> Role </th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {
                    powers?.proposals
                      ?.slice() // Create a copy to avoid mutating the original array
                      ?.sort((a: Action, b: Action) => {
                        // Sort by voteEnd in descending order (newest first)
                        const aVoteEnd = typeof a.voteEnd === 'bigint' ? a.voteEnd : BigInt(a.voteEnd as unknown as string)
                        const bVoteEnd = typeof b.voteEnd === 'bigint' ? b.voteEnd : BigInt(b.voteEnd as unknown as string)
                        return aVoteEnd > bVoteEnd ? -1 : aVoteEnd < bVoteEnd ? 1 : 0
                      })
                      ?.map((proposal: Action, i) => {
                      const law = powers?.laws?.find(law => law.index == proposal.lawId)
                      return (
                        law && 
                        law.conditions?.allowedRole != undefined && 
                        !deselectedStatus.includes(String(proposal.state) ? String(proposal.state) : '9') 
                        ? 
                        <tr
                          key={i}
                          className="text-xs text-left text-slate-800"
                        >
                          {/* Vote ends */}
                          <td className="ps-4 px-2 py-3 w-32">
                            <a
                              href="#"
                              onClick={e => { e.preventDefault(); router.push(`/${chainId}/${powers?.contractAddress}/proposals/${proposal.actionId}`); }}
                              className="text-xs whitespace-nowrap py-1 px-1 underline text-slate-600 hover:text-slate-800 cursor-pointer"
                            >
                              {(() => {
                                // Ensure consistent block number format for lookup
                                const voteEndBlock = typeof proposal.voteEnd === 'bigint' 
                                  ? proposal.voteEnd 
                                  : BigInt(proposal.voteEnd as unknown as string)
                                
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
                              {shorterDescription(law.nameDescription, "short")}
                            </div>
                          </td>
                          
                          {/* Status */}
                          <td className="px-2 py-3 w-24">
                            <div className="truncate text-slate-500 text-xs">
                              {parseProposalStatus(String(proposal.state))}
                            </div>
                          </td>
                          
                          {/* Description */}
                          <td className="px-2 py-3 w-auto">
                            <div className="truncate text-slate-500 text-xs">
                              <a 
                                href={proposal.description}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="hover:text-slate-700 transition-colors"
                              >
                                {proposal.description.length > 30 ? `${proposal.description.slice(0, 30)}...` : proposal.description}
                              </a>
                            </div>
                          </td>

                          {/* Role */}
                          <td className="px-2 py-3 w-20">
                            <div className="truncate text-slate-500 text-xs">
                              {bigintToRole(law.conditions?.allowedRole, powers)}
                            </div>
                          </td>
                        </tr>
                        : 
                        null
                      )
                    })
                  }
                </tbody>
              </table>
            </div>
          </div>
        :
        <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
          No proposals found
        </div>
      }
    </div>
  );
}
