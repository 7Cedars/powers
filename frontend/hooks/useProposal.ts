import { useCallback, useEffect, useRef, useState } from "react";
import { powersAbi } from "../context/abi";
import { Powers, Proposal, Status } from "../context/types";
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { readContract } from "wagmi/actions";
import { getPublicClient } from "wagmi/actions";
import { parseChainId } from "@/utils/parsers";
import { useParams } from "next/navigation";

export const useProposal = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const [hasVoted, setHasVoted] = useState<boolean | undefined>()
  const [error, setError] = useState<any | null>(null)
  const { chainId } = useParams<{ chainId: string }>()
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })
  const [proposalsState, setProposalsState] = useState<{
    actionId: string,
    state: number
  }[]>([])
  
  // Status //
  const getProposalsState = async (proposals: Proposal[], address: `0x${string}`) => {
    let proposal: Proposal
    let state: {
      actionId: string,
      state: number
    }[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.actionId) {
              const fetchedState = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: address,
                functionName: 'state', 
                args: [proposal.actionId]
              })
              state.push({actionId: proposal.actionId.toString(), state: Number(fetchedState)}) // = 5 is a non-existent state
            }
        } 
        setProposalsState(state)
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  // Actions // 
  const propose = useCallback( 
    async (
      lawId: bigint,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string,
      powers: Powers
    ) => {
        setStatus("pending")
        try {
            const result = await writeContract(wagmiConfig, {
              abi: powersAbi,
              address: powers.contractAddress,
              functionName: 'propose', 
              args: [lawId, lawCalldata, nonce, description]
            })
            setTransactionHash(result)
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
  }, [ ])

  const cancel = useCallback( 
    async (
      lawId: bigint,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      powers: Powers
    ) => {
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'cancel', 
            args: [lawId, lawCalldata, nonce]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const castVote = useCallback( 
    async (
      actionId: bigint,
      support: bigint,
      powers: Powers
    ) => {
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'castVote', 
            args: [actionId, support]
          })
          setTransactionHash(result)
          setStatus("success")
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])


  // note: I did not implement castVoteWithReason -- to much work for now. 
  const checkHasVoted = useCallback( 
    async (
      actionId: bigint,
      account: `0x${string}`,
      powers: Powers
    ) => {
      // console.log("checkHasVoted triggered")
        setStatus("pending")
        try {
          const result = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'hasVoted', 
            args: [actionId, account]
          })
          setHasVoted(result as boolean )
          setStatus("idle") 
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  return {status, error, hasVoted, transactionHash, proposalsState, propose, cancel, castVote, checkHasVoted, getProposalsState}
}
