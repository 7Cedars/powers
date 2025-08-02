import { useCallback, useEffect, useRef, useState } from "react";
import { powersAbi } from "../context/abi";
import { Powers, Action, Status } from "../context/types";
import { simulateContract, writeContract } from "@wagmi/core";
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
  const { chainId, powers: address } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })
  const [proposalsState, setProposalsState] = useState<{
    actionId: string,
    state: number
  }[]>([])

  // console.log("@useProposal: ", {proposalsState, status})

    // function to save powers to local storage
  const savePowers = (powers: Powers) => {
    let localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
    const existing = saved.find(item => item.contractAddress == address)
    if (existing) {
      saved.splice(saved.indexOf(existing), 1)
    }
    saved.push(powers)
    localStorage.setItem("powersProtocols", JSON.stringify(saved, (key, value) =>
      typeof value === "bigint" ? value.toString() : value,
    ));
  }
  
  // Status //
  const getProposalsState = async (powers: Powers) => {
    // console.log("@getProposalsState: waypoint 0", {powers})
    let proposal: Action
    let oldProposals: Action[] = powers.proposals || []
    let newProposals: Action[] = []
    let state: {
      actionId: string,
      state: number
    }[] = []

    // console.log("@getProposalsState: waypoint 1", {oldProposals})

    if (publicClient && powers.proposals) {
      try {
        for await (proposal of oldProposals) {
          if (proposal?.actionId) {
            let fetchedState: any
            if (proposal.state != 5) { // proposal.state != 2 && 
              fetchedState = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: powers.contractAddress as `0x${string}`,
                functionName: 'state', 
                args: [proposal.actionId]
              })
              proposal.state = Number(fetchedState)
            }
          }
          newProposals.push(proposal)
          // console.log("@getProposalsState: waypoint 2", {proposal})
        } 
        savePowers({...powers, proposals: newProposals})
        setProposalsState(state)
        // console.log("@getProposalsState: waypoint 3", {state})
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
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress,
            functionName: 'propose',
            args: [lawId, lawCalldata, nonce, description]
          })
          if (request) {
            const result = await writeContract(wagmiConfig, request)
            setTransactionHash(result)
            setStatus("success")
          }
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
