import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Checks, Status, LawSimulation, Execution, LogExtended, Powers } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { ConnectedWallet, useWallets, Wallet } from "@privy-io/react-auth";
import { getPublicClient, readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { supportedChains } from "@/context/chains";
import { sepolia } from "@wagmi/core/chains";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";

export const useChecks = (powers: Powers) => {
  const {data: blockNumber, error: errorBlockNumber} = useBlockNumber({ // this needs to be dynamic, for use in different chains! £todo
    chainId: sepolia.id, // NB: reading blocks from sepolia, because arbitrum One & sepolia reference these block numbers, not their own. 
  })
  const { chainId } = useParams<{ chainId: string }>()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  // console.log("@fetchChecks useChecks called: ", {checks, status, error, powers})

  const checkAccountAuthorised = useCallback(
    async (law: Law, powers: Powers, wallets: ConnectedWallet[]) => {
        try {
          console.log("@checkAccountAuthorised: waypoint 0", {law, powers})
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'canCallLaw', 
                  args: [wallets[0].address, law.index],
                })
          console.log("@checkAccountAuthorised: waypoint 1", {result})
          return result as boolean 
        } catch (error) {
            setStatus("error") 
            setError(error)
            console.log("@checkAccountAuthorised: waypoint 2", {error})
        }
  }, [])

  const checkProposalExists = (nonce: bigint, lawCalldata: `0x${string}`, law: Law, powers: Powers) => {
    console.log("@checkProposalExists: waypoint 0", {law, lawCalldata, nonce, powers})
    if (powers && powers.proposals) {
      const selectedProposal = powers.proposals.find(proposal => 
        proposal.lawId == law.index && 
        proposal.executeCalldata == lawCalldata && 
        proposal.nonce == nonce
      ) 
      console.log("@checkProposalExists: waypoint 1", {selectedProposal, proposals: powers.proposals})

      return selectedProposal 
    } 
  }

  const checkProposalStatus = useCallback(
    async (law: Law, lawCalldata: `0x${string}`, nonce: bigint, stateToCheck: number[]): Promise<boolean | undefined> => {
      const selectedProposal = checkProposalExists(nonce, lawCalldata, law, powers)

      if (selectedProposal) {
        try {
          const state =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.actionId],
                })
          const result = stateToCheck.includes(Number(state)) 
          return result 
        } catch (error) {
          setStatus("error")
          setError(error)
        }
      } else {
        return false 
      }
  }, []) 


  const checkDelayedExecution = (nonce: bigint, calldata: `0x${string}`, law: Law, powers: Powers) => {
    // console.log("CheckDelayedExecution triggered")
    const selectedProposal = checkProposalExists(nonce, calldata, law, powers)
    // console.log("waypoint 1, CheckDelayedExecution: ", {selectedProposal, blockNumber})
    const result = Number(selectedProposal?.voteEnd) + Number(law.conditions.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const fetchExecutions = async (lawId: bigint) => {
    // console.log("@fetchExecutions: waypoint 0", {lawId})
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
            // console.log("@fetchExecutions: waypoint 1", {lawId, fetchedLogs})
            const fetchedLogsTyped = fetchedLogs as unknown[] as LogExtended[]  
            // console.log("@fetchExecutions: waypoint 2", {lawId, fetchedLogsTyped})
            return (
              fetchedLogsTyped.sort((a: LogExtended, b: LogExtended) => (
                a.blockNumber ? Number(a.blockNumber) : 0
              ) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)) as LogExtended[]
          } 
      } catch (error) {
        // console.log("@fetchExecutions: waypoint 4", {lawId, error})
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
    async (nonce: bigint, calldata: `0x${string}`, lawIndex: bigint): Promise<boolean | undefined> => {
      // console.log("@checkNotCompleted: waypoint 0", {nonce, calldata, lawIndex, powers: powers?.contractAddress})

      if (publicClient) {
        try {
              const logs = await publicClient.getContractEvents({ 
                address: powers?.contractAddress as `0x${string}`,
                abi: powersAbi, 
                eventName: 'ActionRequested',
                fromBlock: supportedChain?.genesisBlock,
                args: {lawId: lawIndex}
              })
              const fetchedLogs = parseEventLogs({
                          abi: powersAbi,
                          eventName: 'ActionRequested',
                          logs
                        })
              // console.log("@checkNotCompleted: waypoint 1", {lawIndex, fetchedLogs})
              if (fetchedLogs) {
              const fetchedLogsTyped = fetchedLogs as unknown[] as LogExtended[]  
              
              // console.log("@checkNotCompleted: waypoint 2", {lawIndex, fetchedLogsTyped})
              
              const executionExists = fetchedLogsTyped.some(
                execution => execution.args?.nonce == nonce && execution.args?.lawCalldata == calldata
              )
              // console.log("@checkNotCompleted: waypoint 3", {lawIndex, executionExists})
              // console.log("@checkNotCompleted: waypoint 4", {lawIndex, returnvalue: executionExists == undefined})
              return (!executionExists)
            }
          } 
          catch (error) {
          // console.log("@checkNotCompleted: waypoint 4", {lawIndex, error})
          setStatus("error") 
          setError(error) 
          return undefined
        }
      } else {
        // console.log("@checkNotCompleted: waypoint 5", {lawIndex, returnvalue: undefined})
        return undefined
      }
  }, [ ] ) 

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      console.log("fetchChecks triggered, waypoint 0", {law, callData, nonce, wallets, powers})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && powers?.proposals) {
          
          const throttled = await checkThrottledExecution(law)
          const authorised = await checkAccountAuthorised(law, powers, wallets)
          const proposalStatus = await checkProposalStatus(law, callData, nonce, [3, 4, 5])
          const proposalExists = checkProposalExists(nonce, callData, law, powers) != undefined
          const delayed = checkDelayedExecution(nonce, callData, law, powers)

          const notCompleted1 = await checkNotCompleted(nonce, callData, law.index)
          const notCompleted2 = await checkNotCompleted(nonce, callData, law.conditions.needCompleted)
          const notCompleted3 = await checkNotCompleted(nonce, callData, law.conditions.needNotCompleted)
          

          console.log("fetchChecks triggered, waypoint 1", {delayed, throttled, authorised, proposalStatus, proposalExists, notCompleted1, notCompleted2, notCompleted3})

          if (delayed != undefined && throttled != undefined && authorised != undefined && proposalStatus != undefined && proposalExists != undefined && notCompleted1 != undefined && notCompleted2 != undefined && notCompleted3 != undefined) {// check if all results have come through 
            console.log("fetchChecks triggered, waypoint 1.1", {delayed, throttled, authorised, proposalStatus, proposalExists, notCompleted1, notCompleted2, notCompleted3})

            let newChecks: Checks =  {
              delayPassed: law.conditions.delayExecution == 0n ? true : delayed,
              throttlePassed: law.conditions.throttleExecution == 0n ? true : throttled,
              authorised: authorised,
              proposalExists: law.conditions.quorum == 0n ? true : proposalExists,
              proposalPassed: law.conditions.quorum == 0n ? true : proposalStatus,
              actionNotCompleted: notCompleted1,
              lawCompleted: law.conditions.needCompleted == 0n ? true : !notCompleted2, 
              lawNotCompleted: law.conditions.needNotCompleted == 0n ? true : notCompleted3 
            } 
            newChecks.allPassed =  
              newChecks.delayPassed && 
              newChecks.throttlePassed && 
              newChecks.authorised && 
              newChecks.proposalExists && 
              newChecks.proposalPassed && 
              newChecks.actionNotCompleted && 
              newChecks.lawCompleted &&
              newChecks.lawNotCompleted 
            
            setChecks(newChecks)
            console.log("fetchChecks triggered, waypoint 2", {newChecks})
            setStatus("success") //NB note: after checking status, sets the status back to idle! 
          }
        }       
  }, [ ])

  return {status, error, checks, fetchChecks, checkProposalExists, checkAccountAuthorised}
}
