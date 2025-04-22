import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Checks, Status, LawSimulation, Execution, LogExtended, Powers } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { useChainId, useWaitForTransactionReceipt } from "wagmi";
import { useWallets } from "@privy-io/react-auth";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { supportedChains } from "@/context/chains";
import { sepolia } from "@wagmi/core/chains";

export const useChecks = (powers: Powers) => {
  const {data: blockNumber, error: errorBlockNumber} = useBlockNumber({ // this needs to be dynamic, for use in different chains! £todo
    chainId: sepolia.id, // NB: reading blocks from sepolia, because arbitrum One & sepolia reference these block numbers, not their own. 
  })
  const {ready, wallets} = useWallets();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  // console.log("@fetchChecks useChecks called: ", {action, blockNumberError, blockNumber})

  const checkAccountAuthorised = useCallback(
    async (law: Law) => {
      if (ready && wallets[0]) {
        try {
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'canCallLaw', 
                  args: [wallets[0].address, law.index],
                })
          return result ? result as boolean : false
        } catch (error) {
            setStatus("error") 
            setError(error)
            return false
        } 
      } else { 
        return false 
      }         
  }, [])

  const checkProposalExists = (nonce: bigint, calldata: `0x${string}`, law: Law) => {
    const selectedProposal = powers?.proposals?.find(proposal => 
      proposal.lawId == law.index && 
      proposal.action.callData == calldata && 
      proposal.action.nonce == nonce
    ) 
    // console.log("@checkProposalExists: ", {selectedProposal})

    return selectedProposal
  }

  const checkProposalStatus = useCallback(
    async (nonce: bigint, calldata: `0x${string}`, stateToCheck: number[], law: Law) => {
      const selectedProposal = checkProposalExists(nonce, calldata, law)

      // console.log("@checkProposalStatus: ", {selectedProposal})
    
      if (selectedProposal) {
        try {
          const state =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.action.actionId],
                })
          const result = stateToCheck.includes(Number(state)) 
          return result 
        } catch (error) {
          setStatus("error")
          setError(error)
          return false 
        }
      } else {
        return false 
      }
  }, []) 


  const checkDelayedExecution = (nonce: bigint, calldata: `0x${string}`, law: Law) => {
    // console.log("CheckDelayedExecution triggered")
    const selectedProposal = powers?.proposals?.find(proposal => 
      proposal.lawId == law.index && 
      proposal.action.callData === calldata && 
      proposal.action.nonce === nonce
    ) 
    // console.log("waypoint 1, CheckDelayedExecution: ", {selectedProposal, blockNumber})
    const result = Number(selectedProposal?.voteEnd) + Number(law.conditions.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const fetchExecutions = async (lawId: bigint) => {
    if (publicClient) {
      try {
          if (powers?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              address: powers.contractAddress as `0x${string}`,
              abi: powersAbi, 
              eventName: 'ActionRequested',
              fromBlock: supportedChain?.genesisBlock,
              args: {lawId: lawId}
            })
            const fetchedLogs = parseEventLogs({
                        abi: powersAbi,
                        eventName: 'ActionRequested',
                        logs
                      })
            const fetchedLogsTyped = fetchedLogs as unknown[] as LogExtended[]  
            // console.log({fetchedLogsTyped})
            return (
              fetchedLogsTyped.sort((a: LogExtended, b: LogExtended) => (
                a.blockNumber ? Number(a.blockNumber) : 0
              ) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)) as LogExtended[]
          } 
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const checkThrottledExecution = useCallback( async (law: Law) => {
    const fetchedExecutions = await fetchExecutions(law.index)

    if (fetchedExecutions && fetchedExecutions.length > 0) {
      const result = Number(fetchedExecutions[0].blockNumber) + Number(law.conditions.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkNotCompleted = useCallback( 
    async (nonce: bigint, calldata: `0x${string}`, lawIndex: bigint) => {
      
      const fetchedExecutions = await fetchExecutions(lawIndex)
      const selectedExecution = fetchedExecutions && fetchedExecutions.find(execution => execution.args?.nonce == nonce && execution.args?.lawCalldata == calldata)

      return selectedExecution == undefined; 
  }, [] ) 

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint) => {
      // console.log("fetchChecks triggered")
        let results: boolean[] = new Array<boolean>(8)
        setError(null)
        setStatus("pending")
        
        results[0] = checkDelayedExecution(nonce, callData, law)
        results[1] = await checkThrottledExecution(law)
        results[2] = await checkAccountAuthorised(law)
        results[3] = await checkProposalStatus(nonce, callData, [3, 4], law)
        results[4] = await checkNotCompleted(nonce, callData, law.index)
        results[5] = await checkNotCompleted(nonce, callData, law.conditions.needCompleted)
        results[6] = await checkNotCompleted(nonce, callData, law.conditions.needNotCompleted)
        results[7] = checkProposalExists(nonce, callData, law) != undefined

        // console.log("@fetchChecks: ", {results})

        if (!results.find(result => !result) && law.conditions) {// check if all results have come through 
          let newChecks: Checks =  {
            delayPassed: law.conditions.delayExecution == 0n ? true : results[0],
            throttlePassed: law.conditions.throttleExecution == 0n ? true : results[1],
            authorised: results[2],
            proposalExists: law.conditions.quorum == 0n ? true : results[7],
            proposalPassed: law.conditions.quorum == 0n ? true : results[3],
            proposalNotCompleted: results[4],
            lawCompleted: law.conditions.needCompleted == 0n ? true : results[5] == false, 
            lawNotCompleted: law.conditions.needNotCompleted == 0n ? true : results[6]
          } 
          newChecks.allPassed =  
            newChecks.delayPassed && 
            newChecks.throttlePassed && 
            newChecks.authorised && 
            newChecks.proposalExists && 
            newChecks.proposalPassed && 
            newChecks.proposalNotCompleted && 
            newChecks.lawCompleted &&
            newChecks.lawNotCompleted ? true : false, 
          
            setChecks(newChecks)
        }
 
        setStatus("success") //NB note: after checking status, sets the status back to idle! 
  }, [ ])

  return {status, error, checks, fetchChecks, checkProposalExists}
}
