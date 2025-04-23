import { useCallback, useEffect, useRef, useState } from "react";
import { powersAbi } from "../context/abi";
import { Powers, Proposal, Status } from "../context/types";
import { GetBlockReturnType, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { readContract } from "wagmi/actions";
import { publicClient } from "@/context/clients";
import { parseEventLogs, ParseEventLogsReturnType } from "viem";
import { useChainId } from 'wagmi'
import { supportedChains } from "@/context/chains";
import { getBlock } from '@wagmi/core'
import { mainnet, sepolia } from "@wagmi/core/chains";

export const useProposal = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const [proposals, setProposals] = useState<Proposal[] | undefined>()
  const [hasVoted, setHasVoted] = useState<boolean | undefined>()
  const [error, setError] = useState<any | null>(null)
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })
  
  // Status //
  // I think it should be possible to only update proposals that have not been saved yet.. 
  const getProposals = async (powers: Powers) => {
      if (publicClient) {
        try {
            if (powers?.contractAddress) {
              const logs = await publicClient.getContractEvents({ 
                address: powers.contractAddress as `0x${string}`,
                abi: powersAbi, 
                eventName: 'ProposedActionCreated',
                fromBlock: supportedChain?.genesisBlock  // 
              })
              const fetchedLogs = parseEventLogs({
                          abi: powersAbi,
                          eventName: 'ProposedActionCreated',
                          logs
                        })
              const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
              const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
              fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart  > b.voteStart ? -1 : 1)
              return fetchedProposals
            }
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
    }
  
  
  const getProposalsState = async (proposals: Proposal[], powers: Powers) => {
    let proposal: Proposal
    let state: number[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.actionId) {
              const fetchedState = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: powers.contractAddress,
                functionName: 'state', 
                args: [proposal.actionId]
              })
              state.push(Number(fetchedState)) // = 5 is a non-existent state
            }
        } 
        return state
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }


  const getBlockData = async (proposals: Proposal[], powers: Powers) => {
    let proposal: Proposal
    let blocksData: GetBlockReturnType[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          const existingProposal = powers.proposals?.find(p => p.actionId == proposal.actionId)
          if (!existingProposal || !existingProposal.voteStartBlockData?.chainId) {
            // console.log("@getBlockData, waypoint 1: ", {proposal})
            const fetchedBlockData = await getBlock(wagmiConfig, {
              blockNumber: proposal.voteStart,
              chainId: sepolia.id, // NB This needs to be made dynamic. In this case need to read of sepolia because arbitrum uses mainnet block numbers.  
            })
            const blockDataParsed = fetchedBlockData as GetBlockReturnType
            // console.log("@getBlockData, waypoint 2: ", {blockDataParsed})
            blocksData.push(blockDataParsed)
          } else {
            blocksData.push(existingProposal.voteStartBlockData ? existingProposal.voteStartBlockData : {} as GetBlockReturnType)
          }
        } 
        // console.log("@getBlockData, waypoint 3: ", {blocksData})
        return blocksData
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchProposals = useCallback(
    async (powers: Powers) => {
      // console.log("fetchProposals called, waypoint 1: ", {organisation})

      let proposals: Proposal[] | undefined = [];
      let states: number[] | undefined = []; 
      let blocks: GetBlockReturnType[] | undefined = [];
      let proposalsFull: Proposal[] | undefined = [];

      setError(null)
      setStatus("pending")

      proposals = await getProposals(powers)
      // console.log("fetchProposals called, waypoint 2: ", {proposals})
      if (proposals && proposals.length > 0) {
        states = await getProposalsState(proposals, powers)
        blocks = await getBlockData(proposals, powers)
      } 
      // console.log("fetchProposals called, waypoint 3: ", {states, blocks})
      if (states && blocks) { // + votes later.. 
        proposalsFull = proposals?.map((proposal, index) => {
          return ( 
            {...proposal, state: states[index], voteStartBlockData: blocks[index]}
          )
        })
      }  
      // console.log("fetchProposals called, waypoint 4: ", {proposalsFull})
      setProposals(proposalsFull)
      setStatus("success") 
  }, [ ]) 

  const updateActionState = useCallback(
    async (proposal: Proposal, powers: Powers) => {
      setError(null)
      setStatus("pending")    

      const newState = await getProposalsState([proposal], powers)

      if (newState) {
        const oldProposals = proposals
        const updatedProposal = {...proposal, state: newState[0]}
        const updatedProposals = oldProposals?.map(p => p.actionId == updatedProposal.actionId ? updatedProposal : p) 
        setProposals(updatedProposals)
      }
      setStatus("success") 
      
  }, [ ]) 

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

  return {status, error, proposals, hasVoted, transactionHash, fetchProposals, updateActionState, propose, cancel, castVote, checkHasVoted}
}
