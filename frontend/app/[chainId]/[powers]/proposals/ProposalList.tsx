"use client";

import React, { useEffect, useState } from "react";
import { setAction, setRole, useRoleStore  } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter, useParams } from "next/navigation";
import { Powers, Action } from "@/context/types";
import { parseProposalStatus, parseRole, shorterDescription } from "@/utils/parsers";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintToRole";
import { LoadingBox } from "@/components/LoadingBox";
import { useProposal } from "@/hooks/useProposal";
import { useBlocks } from "@/hooks/useBlocks";
import { useChecks } from "@/hooks/useChecks";

// NB: need to delete action from store? Just in case? 
export function ProposalList({powers, status}: {powers: Powers | undefined, status: string}) {
  const router = useRouter();
  const {getProposalsState} = useProposal()
  const { deselectedRoles } = useRoleStore()
  const [ deselectedStatus, setDeselectedStatus] = useState<string[]>([])
  const { chainId } = useParams<{ chainId: string }>()
  const possibleStatus: string[] = ['0', '1', '2', '3', '4', '5']; 
  const { timestamps, fetchTimestamps } = useBlocks()
  
  useEffect(() => {
    if (powers) {
      getProposalsState(powers)
    }
  }, [powers])

  console.log("@ProposalList: waypoint 0", {powers, timestamps})

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
      
      console.log("@ProposalList: waypoint 1", {blocks})
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks as bigint[], chainId)
      }
    }
  }, [powers?.proposals])

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (deselectedRoles?.includes(role)) {
      newDeselection = deselectedRoles?.filter((oldRole: bigint) => oldRole != role)
    } else if (deselectedRoles != undefined) {
      newDeselection = [...deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    setRole({deselectedRoles: newDeselection})
  };

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
    <div className="w-full min-w-96 flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-y-scroll">
      {/* table banner:roles  */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-6 overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Proposals
        </div>
        {powers?.roles?.map((role, i) => 
            <div className="flex flex-row w-full min-w-fit h-8" key={i}>
            <Button
              size={0}
              showBorder={true}
              role={role == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(role)}
              selected={!deselectedRoles?.includes(BigInt(role))}
              onClick={() => handleRoleSelection(BigInt(role))}
            >
              {bigintToRole(role, powers)} 
            </Button>
            </div>
        )}
      </div>

      {/* table banner:status  */}
      <div className="w-full flex flex-row gap-6 justify-between items-between py-2 overflow-y-scroll border-b border-slate-200 px-6">
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

      {/* table laws  */}

      <div className="w-full overflow-scroll">
      {status == "pending" ? 
      <div className="w-full h-full min-h-fit flex flex-col justify-start text-sm text-slate-500 items-start p-3">
        <LoadingBox /> 
      </div>
      :
      <table className="w-full table-auto">
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Vote ends </th>
                <th className="font-light"> Law </th>
                <th className="font-light"> Status </th>
                <th className="font-light min-w-48"> Description </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
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
              // console.log("timeStamp: ", proposal.voteStartBlockData?.timestamp)
              return (
                law && 
                law.conditions?.allowedRole != undefined && 
                !deselectedRoles?.includes(BigInt(`${law.conditions?.allowedRole}`)) && 
                !deselectedStatus.includes(String(proposal.state) ? String(proposal.state) : '9') 
                ? 
                <tr
                  key={i}
                  className={`text-sm text-left text-slate-800 h-full w-full p-2 overflow-x-scroll`}
                >
                  <td className="h-full w-full max-w-48 flex flex-col text-center justify-center items-center py-3 px-4">
                      <Button
                        showBorder={true}
                        size={0}
                        role={parseRole(law.conditions?.allowedRole)}
                        filled={false}
                        onClick={() => {
                          router.push(`/${chainId}/${powers?.contractAddress}/proposals/${proposal.actionId}`);
                        }}
                        align={0}
                        selected={true}
                      > <div className = "flex flex-row gap-3 w-fit min-w-48 text-center p-1">
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
                        </div>
                      </Button>
                  </td>
                  <td className="pe-4 text-slate-500 min-w-56">{shorterDescription(law.nameDescription, "short")}</td>
                  <td className="pe-4 text-slate-500">{parseProposalStatus(String(proposal.state))}</td>
                  <td className="pe-4 text-slate-500 min-w-fit">
                    <a 
                      href={proposal.description}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="pe-4 text-slate-500 min-w-fit">{
                      proposal.description.length > 30 ? `${proposal.description.slice(0, 30)}...` : proposal.description
                    }
                    </a>
                  </td>
                  <td className="pe-4 min-w-20 text-slate-500"> {bigintToRole(law.conditions?.allowedRole, powers)}
                  </td>
                </tr>
                : 
                null
              )
            }
          )}
        </tbody>
        </table>
      }
      </div>
    </div>
  );
}
