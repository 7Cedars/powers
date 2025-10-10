import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Law, Powers, Action } from "../context/types"
import { getConnectorClient, readContract, readContracts, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { parseChainId } from "@/utils/parsers";
import { useParams } from "next/navigation";

type VoteData = {
  actionId: string
  voteStart: bigint
  voteDuration: bigint
  voteEnd: bigint
  againstVotes: bigint
  forVotes: bigint
  abstainVotes: bigint
  state: number
}

export const useLaw = () => {
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>() 
  const [hasVoted, setHasVoted] = useState<boolean | undefined>()
  const [actionVote, setActionVote] = useState<VoteData | undefined>()
 
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })
 
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
    ) => {
        setStatus("pending")
        try {
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'propose',
            args: [lawId, lawCalldata, nonce, description],
            chainId: parseChainId(chainId)
          })
          if (request) {
            const result = await writeContract(wagmiConfig, request)
            setTransactionHash(result)
            setStatus("success")
          }
        } catch (error) {
            setStatus("error") 
            setError(error as Error)
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
            args: [lawId, lawCalldata, nonce],
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
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
            args: [actionId, support], 
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
          setStatus("success")
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
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
            args: [actionId, account],
            chainId: parseChainId(chainId)
          })
          setHasVoted(result as boolean )
          setStatus("idle") 
      } catch (error) {
          setStatus("error") 
          setError(error as Error)
      }
  }, [ ])

  const fetchVoteData = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ) => {
      setError(null)
      setStatus("pending")
      
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

        const [voteStart, voteDuration, voteEnd, againstVotes, forVotes, abstainVotes] = voteData as unknown as [
          bigint, bigint, bigint, bigint, bigint, bigint
        ]

        const vote: VoteData = {
          actionId: actionObject.actionId as string,
          state: state ? state as number : 0,
          voteStart: voteStart as bigint,
          voteDuration: voteDuration as bigint,
          voteEnd: voteEnd as bigint,
          againstVotes: againstVotes as bigint,
          forVotes: forVotes as bigint,
          abstainVotes: abstainVotes as bigint,
        }

        setActionVote(vote)
        setStatus("success")
        return vote
      } catch (error) {
        setStatus("error")
        setError(error as Error)
        return undefined
      }
    }, [ ])
  
  const simulate = useCallback( 
    async (caller: `0x${string}`, lawCalldata: `0x${string}`, nonce: bigint, law: Law) => {
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
        } catch (error) {
          setStatus("error") 
          setError(error as Error)
          console.log("@simulate: ERROR", {error})
        }
        setStatus("idle")
  }, [ ])

  const request = useCallback( 
    async (
      law: Law,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string
    ) => {
        // console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError(null)
        setStatus("pending")
        try {
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: law.powers as `0x${string}`,
            functionName: 'request',
            args: [law.index, lawCalldata, nonce, description]
          })

          // console.log("@execute: waypoint 1", {request})
          const client = await getConnectorClient(wagmiConfig)
          // console.log("@execute: waypoint 2", {client})
          
          if (request) {
            // console.log("@execute: waypoint 3", {request})
            const result = await writeContract(wagmiConfig, request)
            setTransactionHash(result)
            // console.log("@execute: waypoint 4", {result})
          }
        } catch (error) {
          setStatus("error") 
          setError(error as Error)
          // console.log("@execute: waypoint 5", {error}) 
      }
  }, [ ])

  return {status, error, simulation, hasVoted, actionVote, transactionHash, resetStatus, simulate, request, propose, cancel, castVote, checkHasVoted, fetchVoteData}
}