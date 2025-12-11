"use client";

import { useEffect, useState } from "react"
import { parseChainId } from "@/utils/parsers";
import { Powers, Status, ActionVote, Action } from "@/context/types";
import { CheckIcon, XMarkIcon, ArrowPathIcon} from "@heroicons/react/24/outline";
import { useBlockNumber, useChains, usePublicClient } from "wagmi";
import { useParams } from "next/navigation";
import { getConstants } from "@/context/constants";
import { useActionStore } from "@/context/store";
import { wagmiConfig } from "@/context/wagmiConfig"
import { powersAbi } from "@/context/abi"
import { useBlocks } from "@/hooks/useBlocks"
import { toFullDateFormat, toEurTimeFormat } from "@/utils/toDates"
import { getEnsName } from "@wagmi/core"
import { LoadingBox } from "@/components/LoadingBox"
import { useLaw } from "@/hooks/useLaw";

// Helper function to truncate addresses, preferring ENS names
const truncateAddress = (address: string | undefined, ensName: string | null | undefined): string => {
  if (ensName) return ensName
  if (!address) return 'Unknown'
  if (address.length < 10) return address
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

// Vote type mapping
const getVoteTypeLabel = (support: number): string => {
  switch (support) {
    case 0: return 'Against'
    case 1: return 'For'
    case 2: return 'Abstain'
    default: return 'Unknown'
  }
}

const getVoteTypeColor = (support: number): string => {
  switch (support) {
    case 0: return 'text-red-600' // Against
    case 1: return 'text-green-600' // For
    case 2: return 'text-yellow-600' // Abstain
    default: return 'text-slate-600'
  }
}

type VoteData = {
  voter: `0x${string}`
  support: number
  blockNumber: bigint
  transactionHash: `0x${string}`
  ensName: string | null
}

export const Voting = ({ powers }: {powers: Powers | undefined}) => {
  const { chainId } = useParams<{ chainId: string }>()
  const { data: blockNumber } = useBlockNumber()
  const constants = getConstants(parseChainId(chainId) as number)
  const action = useActionStore()
  const law = powers?.laws?.find(law => law.index == action?.lawId)
  const roleHolders = Number(powers?.roles?.find(role => BigInt(role.roleId) == BigInt(law?.conditions?.allowedRole || 0))?.amountHolders) || 0
  const [populatedAction, setPopulatedAction] = useState<Action | undefined>()
  const {actionVote, fetchVoteData} = useLaw();

  console.log("@Voting: waypoint 0", {actionVote, action, populatedAction})

  // Votes state
  const { timestamps, fetchTimestamps } = useBlocks()
  const [votes, setVotes] = useState<VoteData[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const publicClient = usePublicClient()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const voteEnd = law?.conditions?.votingPeriod ? populatedAction?.proposedAt ? populatedAction.proposedAt + law.conditions.votingPeriod : 0 : 0

  // console.log("@Voting: waypoint 0", {action, actionVote})

  // Use updated action data if available, otherwise use prop
  const allVotes = Number(actionVote?.forVotes || 0) + Number(actionVote?.againstVotes || 0) + Number(actionVote?.abstainVotes || 0)
  const quorum = roleHolders > 0 ? Math.floor((roleHolders * Number(law?.conditions?.quorum || 0)) / 100) : 0
  const threshold = roleHolders > 0 ? Math.floor((roleHolders * Number(law?.conditions?.succeedAt || 0)) / 100) : 0
  const deadline = Number(actionVote?.voteEnd || 0)
  const layout = `w-full flex flex-row justify-center items-center px-2 py-1 text-bold rounded-md`

  // resetting action state when action is changed,
  useEffect(() => {
    if (action) {
      const newPopulatedAction = law?.actions?.find(a => BigInt(a.actionId) == BigInt(action.actionId));
      setPopulatedAction(newPopulatedAction);
    }
  }, [action.actionId, law]);

  // useEffect(() => {
  //   if (powers && law && populatedAction) {
  //     fetchVotes()
  //   }
  // }, [powers, law, populatedAction])

  const fetchVotes = async () => {
    if (!populatedAction?.actionId) return;
    
    setLoading(true)
    fetchVoteData(populatedAction as Action, powers as Powers)
    
    try {
      // Fetch VoteCast event logs between voteStart and voteEnd blocks
      const logs = await publicClient?.getContractEvents({
        address: powers?.contractAddress as `0x${string}`,
        abi: powersAbi,
        eventName: 'VoteCast',
        args: {actionId: BigInt(populatedAction.actionId)},
        fromBlock: BigInt(populatedAction?.proposedAt ? populatedAction.proposedAt : 0),
        toBlock: BigInt(voteEnd ? voteEnd : 0)
      })

      console.log('Fetched vote logs:', logs)

      // Process logs and fetch ENS names
      const votePromises = logs?.map(async (log: any): Promise<VoteData> => {
        let ensName: string | null = null
        
        try {
          ensName = await getEnsName(wagmiConfig, {
            address: log.args.voter as `0x${string}`
          })
        } catch (ensError) {
          // ENS lookup failed, continue without ENS name
          console.log('ENS lookup failed for:', log.args.voter)
        }

        return {
          voter: log.args.voter as `0x${string}`,
          support: log.args.support as number,
          blockNumber: log.blockNumber as bigint,
          transactionHash: log.transactionHash as `0x${string}`,
          ensName
        }
      })

      const votesData = await Promise.all(votePromises || [])
      
      // Filter out any votes with invalid data
      const validVotes = votesData.filter((vote: VoteData): vote is VoteData => 
        vote.blockNumber !== null && 
        vote.transactionHash !== null &&
        typeof vote.blockNumber === 'bigint' &&
        typeof vote.transactionHash === 'string'
      )
      
      // Sort by block number (newest first)
      validVotes.sort((a: VoteData, b: VoteData) => Number(b.blockNumber - a.blockNumber))
      
      setVotes(validVotes)

      // Fetch timestamps for all vote blocks
      const blockNumbers = validVotes.map((vote: VoteData) => vote.blockNumber)
      if (blockNumbers.length > 0) {
        fetchTimestamps(blockNumbers, chainId)
      }

    } catch (err) {
      console.error('Error fetching votes:', err)
      setError('Failed to fetch votes')
    } finally {
      setLoading(false)
    }
  }

  return (
      <div className="w-full h-fit flex flex-col gap-3 justify-start items-center bg-slate-50">
      <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600 border border-slate-300 rounded-md overflow-hidden" > 
        <div className="w-full p-2 bg-slate-100">
          <div className="w-full flex flex-row gap-6 items-center justify-between">
            <div className="text-left text-sm text-slate-600">
              Voting
            </div>
              <button
              onClick={fetchVotes}
              disabled={loading}
              className="flex items-center justify-center rounded-md p-1.5 hover:bg-slate-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              title="Refresh Votes"
            >
              <ArrowPathIcon 
                className={`w-4 h-4 text-slate-600 ${loading ? 'animate-spin' : ''}`}
              />
            </button>
          </div>
        </div>

        <div className = "w-full h-full flex flex-col lg:min-h-fit overflow-x-scroll divide-y divide-slate-300 max-h-full overflow-y-scroll">
        
        {/* Proposal state block */}
        <div className = "w-full flex flex-col justify-center items-center p-4 py-3"> 
            { 
              populatedAction?.state === undefined || populatedAction?.state === null ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> No Proposal Found </div>
              :
              populatedAction?.state === 3 ? 
                <div className={`${layout} text-blue-500 bg-blue-100`}> Active </div>
              :
              populatedAction?.state === 2 ? 
                <div className={`${layout} text-orange-500 bg-orange-100`}> Cancelled </div>
              :
              populatedAction?.state === 4 ? 
                <div className={`${layout} text-red-500 bg-red-100`}> Defeated </div>
              :
              populatedAction?.state === 5 ? 
                <div className={`${layout} text-green-500 bg-green-100`}> Succeeded </div>
              :
              populatedAction?.state === 6 ? 
                <div className={`${layout} text-slate-700 bg-slate-200`}> Requested </div>
              :
              populatedAction?.state === 7 ? 
                <div className={`${layout} text-green-800 bg-green-200`}> Fulfilled </div>
              :
              populatedAction?.state === 0 ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> NonExistent </div>
              :
              null 
            }
        </div>
        
 
        {populatedAction?.state != undefined && populatedAction?.state != null && (
          <>
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { Number(actionVote?.forVotes || 0) + Number(actionVote?.abstainVotes || 0) >= quorum ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { Number(actionVote?.forVotes || 0) + Number(actionVote?.abstainVotes || 0) >= quorum ? "Quorum passed" : "Quorum not passed"}
            </div>
          </div>
          <div className={`relative w-full leading-none rounded-sm h-3 border border-slate-300 overflow-hidden`}>
            <div 
              className={`absolute bottom-0 leading-none h-3 bg-slate-400`}
              style={{width:`${quorum > 0 ? ((Number(actionVote?.forVotes || 0) + Number(actionVote?.abstainVotes || 0)) * 100) / quorum : 0 }%`}}> 
            </div>
          </div>
          <div className="w-full text-sm text-left text-slate-500"> 
           {roleHolders > 0 ? `${Number(actionVote?.forVotes || 0) + Number(actionVote?.abstainVotes || 0) } / ${quorum} votes` : "Loading..."}
          </div>
        </div>

 
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { Number(actionVote?.forVotes || 0) >= threshold ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { Number(actionVote?.forVotes || 0) >= threshold ? "Threshold passed" : "Threshold not passed"}
            </div>
          </div>
          <div className={`relative w-full flex flex-row justify-start leading-none rounded-sm h-3 border border-slate-300`}>
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-gray-400`} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-red-400`} style={{width:`${allVotes > 0 ? ((Number(actionVote?.forVotes || 0) + Number(actionVote?.againstVotes || 0)) / allVotes)*100 : 0}%`}} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-green-400`} style={{width:`${allVotes > 0 ? ((Number(actionVote?.forVotes || 0)) / allVotes)*100 : 0}%`}} />
            <div className={`absolute -top-2 w-full leading-none h-6 border-r-4 border-green-500`} style={{width:`${law?.conditions?.succeedAt}%`}} />
          </div>
          <div className="w-full flex flex-row justify-between items-center"> 
            <div className="w-fit text-sm text-center text-green-500">
              {roleHolders > 0 ? `${Number(actionVote?.forVotes || 0)} for` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-red-500">
              {roleHolders > 0 ? `${Number(actionVote?.againstVotes || 0)} against` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-gray-500">
            {roleHolders > 0 ? `${Number(actionVote?.abstainVotes || 0)} abstain` : "na"}
            </div>
          </div>
        </div>

        {/* Vote still active block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { blockNumber && blockNumber <= deadline ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { blockNumber && blockNumber >= deadline ? "Vote has closed" : "Vote still active"}
            </div>
          </div>
          {blockNumber && blockNumber < deadline &&  
            <div className = "w-full flex flex-row justify-between items-center">
              {`Vote will end in ${Math.floor((deadline - Number(blockNumber)) * 60 / constants.BLOCKS_PER_HOUR)} minutes`}
            </div>  
          }
        </div>
        </>
        )}
        </div> 
      </section>

      {/* Votes Cast Section */}
      <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600 border border-slate-300 rounded-md overflow-hidden">
        <div className="w-full p-2 bg-slate-100">
          <div className="w-full flex flex-row gap-6 items-center justify-between">
            <div className="text-left text-sm text-slate-600">
              Votes Cast ({votes.length})
            </div>
          </div>
        </div>

        {loading ? (
          <div className="w-full flex flex-col justify-center items-center p-6">
            <LoadingBox />
          </div>
        ) : error ? (
          <div className="w-full flex flex-row gap-1 text-sm text-red-500 justify-center items-center text-center p-3">
            {error}
          </div>
        ) : votes.length > 0 ? (
          <div className="w-full h-fit max-h-56 flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <thead className="w-full border-b border-slate-200 sticky top-0 bg-slate-50">
                  <tr className="w-full text-xs font-light text-left text-slate-500">
                    <th className="px-2 py-3 font-light w-32">Date</th>
                    <th className="px-2 py-3 font-light w-24">Voter</th>
                    <th className="px-2 py-3 font-light w-20">Vote</th>
                    <th className="px-2 py-3 font-light w-24">Tx Hash</th>
                  </tr>
                </thead>
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {votes.map((vote, index) => (
                    <tr key={index} className="text-sm text-left text-slate-800">
                      {/* Vote timestamp */}
                      <td className="px-2 py-3 w-32">
                        <div className="text-xs whitespace-nowrap">
                          {(() => {
                            const timestampData = timestamps.get(`${chainId}:${vote.blockNumber}`)
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
                              console.error('Date formatting error:', error)
                              return 'Date error'
                            }
                          })()}
                        </div>
                      </td>

                      {/* Voter */}
                      <td className="px-2 py-3 w-24">
                        <div className="truncate text-slate-500 text-xs font-mono">
                          {truncateAddress(vote.voter, vote.ensName)}
                        </div>
                      </td>

                      {/* Vote type */}
                      <td className="px-2 py-3 w-20">
                        <div className={`text-xs font-medium ${getVoteTypeColor(vote.support)}`}>
                          {getVoteTypeLabel(vote.support)}
                        </div>
                      </td>

                      {/* Transaction hash */}
                      <td className="px-2 py-3 w-24">
                        <a
                          href={`${supportedChain?.blockExplorers?.default.url}/tx/${vote.transactionHash}#code`} 
                          target="_blank"
                          rel="noopener noreferrer"
                          className="truncate text-slate-600 hover:text-slate-700 text-xs font-mono underline"
                        >
                          {vote.transactionHash.slice(0, 6)}...{vote.transactionHash.slice(-4)}
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ) : (
          <div className="w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
            No votes cast yet
          </div>
        )}
      </section>
    </div>
  )
}