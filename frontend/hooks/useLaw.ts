import { useCallback, useEffect, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { LawSimulation, Law, Powers, Action, ActionVote, Status } from "../context/types"
import { readContract, readContracts, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useTransactionReceipt, useWaitForTransactionReceipt, useTransactionConfirmations } from "wagmi";
import { parseChainId } from "@/utils/parsers";
import { useParams } from "next/navigation";
import { setStatus, setError } from "@/context/store";
import { usePowers } from "./usePowers";

export const useLaw = () => {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const { fetchPowers } = usePowers();
  const [simulation, setSimulation ] = useState<LawSimulation>()  
  const [actionVote, setActionVote] = useState<ActionVote | undefined>() 
 
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const {data: dataReceipt, error: errorReceipt, status: statusReceipt} = useTransactionConfirmations({
    // confirmations: 1, 
    hash: transactionHash,
    chainId: parseChainId(chainId) 
  })

  // console.log("@useLaw, waypoint 0", {dataReceipt})
 
  // NB: here the powers object is updated after a transaction is successful.
  useEffect(() => {
    if (statusReceipt === "pending") {
      setStatus({status: "pending"})
      fetchPowers(addressPowers)
    }
    if (statusReceipt === "success") {
      setStatus({status: "success"})
      fetchPowers(addressPowers)
    }
    if (statusReceipt === "error") {
      setStatus({status: "error"})
      setError({error: errorReceipt as Error})
    }
  }, [statusReceipt])

  // reset // 
  const resetStatus = () => {
    setStatus({status: "idle"})
    setError({error: null})
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
        setStatus({status: "pending"})
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
            // setStatus({status: "success"})
            return true
          }
        } catch (error) {
            setStatus({status: "error"}) 
            setError({error: error as Error})
        }
        return false
  }, [chainId])

  const cancel = useCallback( 
    async (
      lawId: bigint,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      powers: Powers
    ): Promise<boolean> => {
        setStatus({status: "pending"})
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'cancel', 
            args: [lawId, lawCalldata, nonce],
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
          // setStatus({status: "success"})
          return true
      } catch (error) {
          setStatus({status: "error"}) 
          setError({error: error as Error})
          return false
      }
  }, [chainId])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const castVote = useCallback( 
    async (
      actionId: bigint,
      support: bigint,
      powers: Powers
    ): Promise<boolean> => {
        setStatus({status: "pending"})
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'castVote', 
            args: [actionId, support], 
            chainId: parseChainId(chainId)
          })
          setTransactionHash(result)
          // setStatus({status: "success"})
          return true
      } catch (error) {
          setStatus({status: "error"}) 
          setError({error: error as Error})
          return false
      }
  }, [chainId])

  const fetchVoteData = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ): Promise<ActionVote | undefined> => {
      setError({error: null})
      setStatus({status: "pending"})

      // console.log("@fetchVoteData, waypoint 0", {actionObject, powers})
      
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

        // console.log("@fetchVoteData, waypoint 1", {voteData, state})

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

        // console.log("@fetchVoteData, waypoint 2", {vote})

        setActionVote(vote)
        setStatus({status: "success"})
        return vote
      } catch (error) {
        // console.log("@fetchVoteData, waypoint 3", {error})
        setStatus({status: "error"})
        setError({error: error as Error})
        return undefined
      }
    }, [chainId])
  
  const simulate = useCallback( 
    async (caller: `0x${string}`, lawCalldata: `0x${string}`, nonce: bigint, law: Law): Promise<boolean> => {
      // console.log("@simulate: waypoint 1", {caller, lawCalldata, nonce, law})
      setError({error: null})
      setStatus({status: "pending"})

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
          setStatus({status: "success"})
          return true
        } catch (error) {
          setStatus({status: "error"}) 
          setError({error: error as Error})
          console.log("@simulate: ERROR", {error})
          return false
        } 
  }, [chainId])

  const request = useCallback( 
    async (
      law: Law,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string
    ): Promise<boolean> => {
        // console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError({error: null})
        setStatus({status: "pending"})
        try {
          const { request: simulatedRequest } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: law.powers as `0x${string}`,
            functionName: 'request',
            args: [law.index, lawCalldata, nonce, description],
            chainId: parseChainId(chainId)
          })
          
          if (simulatedRequest) {
            // console.log("@execute: waypoint 3", {request})
            const result = await writeContract(wagmiConfig, simulatedRequest)
            setTransactionHash(result)
            // console.log("@execute: waypoint 4", {result})
            return true
          }
        } catch (error) {
          // setStatus({status: "error"}) 
          setError({error: error as Error})
          // console.log("@execute: waypoint 5", {error}) 
          return false
        }
        setStatus({status: "idle"})
        return false
      }, [chainId])

  return {simulation, actionVote, transactionHash, resetStatus, simulate, request, propose, cancel, castVote, fetchVoteData}
}