import { useCallback, useEffect, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Law, Powers, Action, ActionVote } from "../context/types"
import { readContract, readContracts, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { parseChainId } from "@/utils/parsers";
import { useParams } from "next/navigation";

export const useLaw = () => {
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>() 
  const [hasVoted, setHasVoted] = useState<boolean | undefined>()
  const [actionVote, setActionVote] = useState<ActionVote | undefined>()
 
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })

  // console.log("@useLaw, waypoint 0", {actionVote, statusReceipt})
 
  useEffect(() => {
    if (statusReceipt === "success") setStatus("success")
    if (statusReceipt === "error") setStatus("error")
  }, [statusReceipt])

  // reset // 
  const resetStatus = () => {
    setStatus("idle")
    setError(null)
    setTransactionHash(undefined)
  }
  
  // Actions //  
  const propose = useCallback( 
    async (
      lawId: bigint,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string,
      powers: Powers
    ): Promise<boolean> => {
        setStatus("pending")
        try {
          const { request: simulatedRequest } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'propose',
            args: [lawId, lawCalldata, nonce, description],
            chainId: parseChainId(chainId)
          })
          if (simulatedRequest) {
            const result = await writeContract(wagmiConfig, simulatedRequest)
            setTransactionHash(result)
            setStatus("success")
            return true
          }
        } catch (error) {
            setStatus("error") 
            setError(error as Error)
        }
        return false
  }, [ ])

  const cancel = useCallback( 
    async (
      lawId: bigint,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      powers: Powers
    ): Promise<boolean> => {
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'cancel', 
            args: [lawId, lawCalldata, nonce],
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
          setStatus("success")
          return true
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
          return false
      }
  }, [ ])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const castVote = useCallback( 
    async (
      actionId: bigint,
      support: bigint,
      powers: Powers
    ): Promise<boolean> => {
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'castVote', 
            args: [actionId, support], 
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
          setStatus("success")
          return true
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
          return false
      }
  }, [ ])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const checkHasVoted = useCallback( 
    async (
      actionId: bigint,
      account: `0x${string}`,
      powers: Powers
    ): Promise<boolean> => {
      // console.log("checkHasVoted triggered")
        setStatus("pending")
        try {
          const result = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'hasVoted', 
            args: [actionId, account],
            chainId: parseChainId(chainId)
          })
          setHasVoted(result as boolean )
          setStatus("idle") 
          return result as boolean
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
          return false
      }
  }, [ ])

  const fetchVoteData = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ): Promise<ActionVote | undefined> => {
      setError(null)
      setStatus("pending")

      console.log("@fetchVoteData, waypoint 0", {actionObject, powers})
      
      try {
        const [{ result: voteData }, { result: state }] = await readContracts(wagmiConfig, {
          contracts: [
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionVoteData',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            },
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionState',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            }
          ]
        })

        console.log("@fetchVoteData, waypoint 1", {voteData, state})

        const [voteStart, voteDuration, voteEnd, againstVotes, forVotes, abstainVotes] = voteData as unknown as [
          bigint, bigint, bigint, bigint, bigint, bigint
        ]

        const vote: ActionVote = {
          actionId: actionObject.actionId as string,
          state: state ? state as number : 0,
          voteStart: voteStart as bigint,
          voteDuration: voteDuration as bigint,
          voteEnd: voteEnd as bigint,
          againstVotes: againstVotes as bigint,
          forVotes: forVotes as bigint,
          abstainVotes: abstainVotes as bigint,
        }

        console.log("@fetchVoteData, waypoint 2", {vote})

        setActionVote(vote)
        setStatus("success")
        return vote
      } catch (error) {
        console.log("@fetchVoteData, waypoint 3", {error})
        setStatus("error")
        setError(error as Error)
        return undefined
      }
    }, [ ])
  
  const simulate = useCallback( 
    async (caller: `0x${string}`, lawCalldata: `0x${string}`, nonce: bigint, law: Law): Promise<boolean> => {
      // console.log("@simulate: waypoint 1", {caller, lawCalldata, nonce, law})
      setError(null)
      setStatus("pending")

      try {
          const result = await readContract(wagmiConfig, {
            abi: lawAbi,
            address: law.lawAddress as `0x${string}`,
            functionName: 'handleRequest', 
            args: [caller, law.powers, law.index, lawCalldata, nonce],
            chainId: parseChainId(chainId)
            })
          // console.log("@simulate: waypoint 2a", {result})
          // console.log("@simulate: waypoint 2b", {result: result as LawSimulation})
          setSimulation(result as LawSimulation)
          setStatus("success")
          return true
        } catch (error) {
          setStatus("error") 
          setError(error as Error)
          console.log("@simulate: ERROR", {error})
          return false
        }
        setStatus("idle")
  }, [ ])

  const request = useCallback( 
    async (
      law: Law,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string
    ): Promise<boolean> => {
        // console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError(null)
        setStatus("pending")
        try {
          const { request: simulatedRequest } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: law.powers as `0x${string}`,
            functionName: 'request',
            args: [law.index, lawCalldata, nonce, description]
          })
          
          if (simulatedRequest) {
            // console.log("@execute: waypoint 3", {request})
            const result = await writeContract(wagmiConfig, simulatedRequest)
            setTransactionHash(result)
            // console.log("@execute: waypoint 4", {result})
            return true
          }
        } catch (error) {
          setStatus("error") 
          setError(error as Error)
          // console.log("@execute: waypoint 5", {error}) 
          return false
        }
        setStatus("idle")
        return false
      }, [ ])

  return {status, error, simulation, hasVoted, actionVote, transactionHash, resetStatus, simulate, request, propose, cancel, castVote, checkHasVoted, fetchVoteData}
}