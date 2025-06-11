import { useEffect, useState } from "react"
import { useParams } from "next/navigation"
import { usePublicClient } from "wagmi"
import { wagmiConfig } from "@/context/wagmiConfig"
import { powersAbi } from "@/context/abi"
import { parseChainId } from "@/utils/parsers"
import { useActionDataStore } from "@/context/store"
import { useBlocks } from "@/hooks/useBlocks"
import { toFullDateFormat, toEurTimeFormat } from "@/utils/toDates"
import { getEnsName } from "@wagmi/core"
import { LoadingBox } from "@/components/LoadingBox"
import { Powers, Status } from "@/context/types"

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

type VotesProps = {
  actionId: string
  powers: Powers | undefined
  status: Status
}

export const Votes = ({ actionId, powers, status }: VotesProps) => {
  const { chainId } = useParams<{ chainId: string }>()
  const { actionData } = useActionDataStore()
  const { timestamps, fetchTimestamps } = useBlocks()
  const [votes, setVotes] = useState<VoteData[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const publicClient = usePublicClient()

  // Get the action data for this specific actionId
  const currentAction = actionData.get(actionId)

  useEffect(() => {
    if (!currentAction?.voteStart || !currentAction?.voteEnd || !powers?.contractAddress || !publicClient) {
      return
    }

    const fetchVotes = async () => {
      setLoading(true)
      setError(null)
      
      try {
        // Fetch VoteCast event logs between voteStart and voteEnd blocks
        const logs = await publicClient.getLogs({
          address: powers.contractAddress,
          event: {
            type: 'event',
            name: 'VoteCast',
            inputs: [
              { name: 'voter', type: 'address', indexed: true },
              { name: 'actionId', type: 'uint256', indexed: true },
              { name: 'support', type: 'uint8', indexed: false },
              { name: 'reason', type: 'string', indexed: false }
            ]
          },
          args: {
            actionId: BigInt(actionId)
          },
          fromBlock: currentAction.voteStart,
          toBlock: currentAction.voteEnd,
          strict: true
        })

        // Process logs and fetch ENS names
        const votePromises = logs.map(async (log: any): Promise<VoteData> => {
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

        const votesData = await Promise.all(votePromises)
        
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

    fetchVotes()
  }, [currentAction?.voteStart, currentAction?.voteEnd, powers?.contractAddress, actionId, chainId, fetchTimestamps, publicClient])

  if (!currentAction?.voteStart || !currentAction?.voteEnd) {
    return null // Don't render if no voting period data
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      <div className="w-full border-b border-slate-300 p-2 bg-slate-100">
        <div className="w-full flex flex-row gap-6 items-center justify-between">
          <div className="text-left text-sm text-slate-600">
            Votes Cast ({votes.length})
          </div>
        </div>
      </div>

      {loading || status === "pending" ? (
        <div className="w-full flex flex-col justify-center items-center p-6">
          <LoadingBox />
        </div>
      ) : error ? (
        <div className="w-full flex flex-row gap-1 text-sm text-red-500 justify-center items-center text-center p-3">
          {error}
        </div>
      ) : votes.length > 0 ? (
        <div className="w-full h-fit lg:max-h-80 max-h-56 flex flex-col justify-start items-center overflow-hidden">
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
                        href={`https://etherscan.io/tx/${vote.transactionHash}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="truncate text-blue-500 hover:text-blue-700 text-xs font-mono underline"
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
    </div>
  )
} 