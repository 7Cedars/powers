import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Checks, Status, LawSimulation, Execution, LogExtended, Powers, LawExecutions } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { ConnectedWallet, useWallets, Wallet } from "@privy-io/react-auth";
import { getPublicClient, readContract } from "wagmi/actions";
import { useBlockNumber, useChains } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType, encodeAbiParameters, keccak256, toBytes } from "viem";
import { sepolia } from "@wagmi/core/chains";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";

export const useChecks = (powers: Powers) => {
  const timestamp = Math.floor(Date.now() / 1000)
  const { chainId } = useParams<{ chainId: string }>()
  const supportedChains = useChains()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  // console.log("@fetchChecks useChecks called: ", {checks, status, error, powers})

  /**
   * Hashes an action using the same algorithm as in the Solidity contract
   * Replicates: uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)));
   * Create by AI - let's see if it works.. 
   */
  const hashAction = useCallback((lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint): bigint => {
    // Encode the parameters in the same order as abi.encode in Solidity
    const encoded = encodeAbiParameters(
      [
        { name: 'lawId', type: 'uint16' },
        { name: 'lawCalldata', type: 'bytes' },
        { name: 'nonce', type: 'uint256' }
      ],
      [Number(lawId), lawCalldata, nonce]
    );
    
    // Hash the encoded data
    const hash = keccak256(encoded);
    
    // Convert the hash to a bigint (equivalent to uint256 in Solidity)
    return BigInt(hash);
  }, []);

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
    const result = Number(selectedProposal?.voteEnd) + Number(law.conditions?.delayExecution) < Number(timestamp)
    return result as boolean
  }

  const fetchExecutions = async (law: Law) => {
    // console.log("@fetchExecutions: waypoint 0", {lawId})
    if (publicClient) {
      try {
          const lawExecutions = await readContract(wagmiConfig, {
            abi: lawAbi, 
            address: law.lawAddress,
            functionName: 'getExecutions',
            args: [law.powers, law.index]
          })
          return lawExecutions as unknown as LawExecutions
      } catch (error) {
        // console.log("@fetchExecutions: waypoint 4", {lawId, error})
        setStatus("error") 
        setError(error)
      }
    }
  }

  const checkThrottledExecution = useCallback( async (law: Law) => {
    const fetchedExecutions = await fetchExecutions(law)

    if (fetchedExecutions && fetchedExecutions.executions?.length > 0) {
      const result = Number(fetchedExecutions?.executions[0]) + Number(law.conditions?.throttleExecution) < Number(timestamp)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkNotCompleted = useCallback( 
    async (nonce: bigint, calldata: `0x${string}`, lawId: bigint): Promise<boolean | undefined> => {
      const law: Law = powers?.laws?.find(law => law.index == lawId) as Law

      // Calculate actionId using the same algorithm as in the contract
      const actionId = hashAction(lawId, calldata, nonce);
      
      try {
        // Check if the action has already been completed
        const stateAction = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.lawAddress,
          functionName: 'state',
          args: [actionId]
        });
        
        // If action exists and is completed, return false
        if (Number(stateAction) == 5) {
          return false;
        }
        return true; // Default to true if we couldn't determine otherwise
      } 
      catch (error) {
        setStatus("error");
        setError(error);
        return undefined;
      }
  }, [hashAction, publicClient, supportedChain]);

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      console.log("fetchChecks triggered, waypoint 0", {law, callData, nonce, wallets, powers})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && powers?.proposals && law.conditions) {
          
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
  }, [checkAccountAuthorised, checkNotCompleted, checkProposalStatus, checkThrottledExecution])

  return {status, error, checks, fetchChecks, checkProposalExists, checkAccountAuthorised, hashAction}
}