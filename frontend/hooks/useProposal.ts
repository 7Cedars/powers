import { useCallback, useEffect, useRef, useState } from "react";
import { powersAbi } from "../context/abi";
import { Powers, Proposal, Status } from "../context/types";
import { GetBlockReturnType, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
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
  const [hasVoted, setHasVoted] = useState<boolean | undefined>()
  const [error, setError] = useState<any | null>(null)
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  
  // Status //
  // I think it should be possible to only update proposals that have not been saved yet.. 
  const getProposals = async (powers: Powers, fromBlock: bigint) => {
      if (publicClient) {
        try {
            if (powers?.contractAddress) {
              const logs = await publicClient.getContractEvents({ 
                address: powers.contractAddress as `0x${string}`,
                abi: powersAbi, 
                eventName: 'ProposedActionCreated',
                fromBlock: fromBlock // 
              })
              const fetchedLogs = parseEventLogs({
                          abi: powersAbi,
                          eventName: 'ProposedActionCreated',
                          logs
                        })
              const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
              const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
              return fetchedProposals
            }
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
    }
  
    const getProposalsState = async (proposals: Proposal[], address: `0x${string}`) => {
      let proposal: Proposal
      let state: number[] = []
  
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
                state.push(Number(fetchedState)) // = 5 is a non-existent state
              }
          } 
          console.log("@getProposalsState: waypoint 1", {state})
          return state
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
    }

    const getBlockData = async (proposals: Proposal[], address: `0x${string}`) => {
      let proposal: Proposal
      let blocksData: GetBlockReturnType[] = []

      let localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore ? JSON.parse(localStore) : []
      const powers = saved.find(item => item.contractAddress == address)
  
      if (publicClient) {
        try {
          for await (proposal of proposals) {
            const existingProposal = powers?.proposals?.find(p => p.actionId == proposal.actionId)
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
          return blocksData
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
    }

  const updateProposal = useCallback(
    async (proposal: Proposal, powers: Powers) => {
      setError(null)
      setStatus("pending")

      let localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore ? JSON.parse(localStore) : []
      const powersToUpdate = saved.find(item => item.contractAddress == powers.contractAddress)

      if (powersToUpdate) {
        const states = await getProposalsState([proposal], powersToUpdate.contractAddress)
        const blocks = await getBlockData([proposal], powersToUpdate.contractAddress)

        if (states && blocks) {
          const updatedProposal = {...proposal, state: states[0], voteStartBlockData: blocks[0]}
          const updatedProposals = powersToUpdate.proposals?.map(p => p.actionId == updatedProposal.actionId ? updatedProposal : p) 
          
          const allPowers = saved.map(power => power.contractAddress == powers.contractAddress ? {...power, proposals: updatedProposals} : power)
          localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ));
        } 
      }
      setStatus("success") 
  }, [ ]) 

  const addProposals = useCallback(
    async (powers: Powers, fromBlock: bigint) => {
      setError(null)
      setStatus("pending")

      let localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore ? JSON.parse(localStore) : []
      const powersToUpdate = saved.find(item => item.contractAddress == powers.contractAddress)

      let proposals: Proposal[] | undefined = [];
      let states: number[] | undefined = []; 
      let blocks: GetBlockReturnType[] | undefined = [];
      let proposalsFull: Proposal[] | undefined = [];

      proposals = await getProposals(powers, fromBlock)
      const newProposals = proposals?.filter(p => !powers.proposals?.some(p2 => p2.actionId == p.actionId))

      if (newProposals && newProposals.length > 0) {
        states = await getProposalsState(newProposals, powers.contractAddress)
        blocks = await getBlockData(newProposals, powers.contractAddress)
      } 

      if (states && blocks) { // + votes later.. 
        proposalsFull = newProposals?.map((proposal, index) => {
          return ( 
            {...proposal, state: states[index], voteStartBlockData: {...blocks[index], chainId: sepolia.id}}
          )
        })
        const updatedActionIds = proposalsFull ? proposalsFull.map(p => p.actionId) : [] 
        const updatedProposals = powersToUpdate && powersToUpdate.proposals?.map((p, index) => updatedActionIds.includes(p.actionId) ? {...p, state: states[index], voteStartBlockData: {...blocks[index], chainId: sepolia.id}} : p) 
        const allPowers = saved.map(power => power.contractAddress == powers.contractAddress ? {...power, proposals: updatedProposals} : power)
        localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
          typeof value === "bigint" ? value.toString() : value,
        ));
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

  return {status, error, hasVoted, transactionHash, updateProposal, addProposals, propose, cancel, castVote, checkHasVoted}
}
