import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Law, Checks, Status, LawExecutions, Powers } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { ConnectedWallet } from "@privy-io/react-auth";
import { getPublicClient, readContract } from "wagmi/actions";
import { useChains, useBlockNumber, useAccount } from 'wagmi'
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";
import { hashAction } from "@/utils/hashAction";
import { getConstants } from "@/context/constants";
import { setChainChecks, setChecksStatus } from "@/context/store";

export const useChecks = () => {
  const { chainId } = useParams<{ chainId: string }>()
  const { data: blockNumber } = useBlockNumber({
    chainId: parseChainId(chainId)
  })
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  // note: the state of checks is not stored here, it is stored in the Zustand store

  console.log("useChecks: waypoint 0", {error, status})

  const checkAccountAuthorised = useCallback(
    async (law: Law, powers: Powers, wallets: ConnectedWallet[]) => {
        try {
          console.log("@checkAccountAuthorised: waypoint 0", {law, powers, wallets})
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

  const checkActionStatus = useCallback(
    async (law: Law, lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint, stateToCheck: number[]): Promise<boolean | undefined> => {
      const actionId = hashAction(lawId, lawCalldata, nonce)
      console.log("@checkActionStatus: waypoint 0", {lawId, lawCalldata, nonce, stateToCheck, actionId})

      try {
        const state =  await readContract(wagmiConfig, {
                abi: powersAbi,
                address: law.powers as `0x${string}`,
                functionName: 'state', 
                args: [actionId],
              })
        const result = stateToCheck.includes(Number(state)) 
        return result 
      } catch (error) {
        setStatus("error")
        setError(error)
      }
  }, []) 
  
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

    // console.log("checkThrottledExecution, waypoint 1", {fetchedExecutions, law})

    if (fetchedExecutions && fetchedExecutions.executions?.length > 0) {
      const result = Number(fetchedExecutions?.executions[0]) + Number(law.conditions?.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkDelayedExecution = (lawId: bigint, nonce: bigint, calldata: `0x${string}`, powers: Powers) => {
    // NB! CONTINUE HERE! The proposal box should NOT depend on data saved at powers.proposals. Too few of the proposals are saved.
    // instead should fetch data straigh from contract: use the getProposedActionDeadline function. 
    console.log("CheckDelayedExecution triggered:", {lawId, nonce, calldata, powers})
    const actionId = hashAction(lawId, calldata, nonce)
    const law = powers.activeLaws?.find(law => law.index === lawId)
    console.log("waypoint 0, CheckDelayedExecution: ", {actionId})
    const selectedProposal = powers.proposals?.find(proposal => BigInt(proposal.actionId) == actionId)

    console.log("waypoint 1, CheckDelayedExecution: ", {selectedProposal, blockNumber})
    const result = Number(selectedProposal?.voteEnd) + Number(law?.conditions?.delayExecution) < Number(blockNumber)
    return result as boolean
  }


  const calculateDependencies = (lawId: bigint, powers: Powers) => {
    const selectedLawId = String(lawId)
    let connectedNodes: Set<string> = new Set()
    
    if (powers.activeLaws) {
      // Build dependency maps
      const dependencies = new Map<string, Set<string>>()
      const dependents = new Map<string, Set<string>>()
      
      powers.activeLaws.forEach(law => {
        const lawId = String(law.index)
        dependencies.set(lawId, new Set())
        dependents.set(lawId, new Set())
      })
      
      // Populate dependency relationships
      powers.activeLaws.forEach(law => {
        const lawId = String(law.index)
        if (law.conditions) {
          if (law.conditions.needCompleted !== 0n) {
            const targetId = String(law.conditions.needCompleted)
            if (dependencies.has(targetId)) {
              dependencies.get(lawId)?.add(targetId)
              dependents.get(targetId)?.add(lawId)
            }
          }
          if (law.conditions.needNotCompleted !== 0n) {
            const targetId = String(law.conditions.needNotCompleted)
            if (dependencies.has(targetId)) {
              dependencies.get(lawId)?.add(targetId)
              dependents.get(targetId)?.add(lawId)
            }
          }
          if (law.conditions.readStateFrom !== 0n) {
            const targetId = String(law.conditions.readStateFrom)
            if (dependencies.has(targetId)) {
              dependencies.get(lawId)?.add(targetId)
              dependents.get(targetId)?.add(lawId)
            }
          }
        }
      })
      
      // Find all connected nodes using traversal
      const visited = new Set<string>()
      const traverse = (nodeId: string) => {
        if (visited.has(nodeId)) return
        visited.add(nodeId)
        connectedNodes.add(nodeId)
        
        // Add all dependencies
        const deps = dependencies.get(nodeId) || new Set()
        deps.forEach(depId => traverse(depId))
        
        // Add all dependents  
        const dependentNodes = dependents.get(nodeId) || new Set()
        dependentNodes.forEach(depId => traverse(depId))
      }
      
      traverse(selectedLawId)
    }
    return connectedNodes
  }

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      // console.log("fetchChecks triggered, waypoint 0", {law, callData, nonce, wallets, powers, actionLawId, caller})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && law.conditions) {
          // console.log("fetchChecks triggered, waypoint 1", {law, callData, nonce, wallets, powers, actionLawId, caller})
          const throttled = await checkThrottledExecution(law)
          const authorised = await checkAccountAuthorised(law, powers, wallets)
          const proposalStatus = await checkActionStatus(law, law.index, callData, nonce, [3, 4, 5])
          const voteActive = await checkActionStatus(law, law.index, callData, nonce, [0])
          const proposalExists = await checkActionStatus(law, law.index, callData, nonce, [6])
          const delayed = checkDelayedExecution(law.index, nonce, callData, powers)

          const notCompleted1 = await checkActionStatus(law, law.index, callData, nonce, [5])
          const notCompleted2 = await checkActionStatus(law, law.conditions.needCompleted, callData, nonce, [5])
          const notCompleted3 = await checkActionStatus(law, law.conditions.needNotCompleted, callData, nonce, [5])

            let newChecks: Checks =  {
              delayPassed: law.conditions.delayExecution == 0n ? true : delayed,
              throttlePassed: law.conditions.throttleExecution == 0n ? true : throttled,
              authorised: authorised,
              proposalExists: law.conditions.quorum == 0n ? true : proposalExists == false,
              voteActive: law.conditions.quorum == 0n ? true : voteActive,
              proposalPassed: law.conditions.quorum == 0n ? true : proposalStatus,
              actionNotCompleted: !notCompleted1,
              lawCompleted: law.conditions.needCompleted == 0n ? true : notCompleted2, 
              lawNotCompleted: law.conditions.needNotCompleted == 0n ? true : !notCompleted3 
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
          
            // console.log("fetchChecks triggered, waypoint 2", {newChecks})
            setStatus("success") //NB note: after checking status, sets the status back to idle! 
            return newChecks
        }       
  }, [ ])

  const fetchChainChecks = useCallback(
    async (lawId: bigint, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      
      const chainLaws = calculateDependencies(lawId, powers)
      setChecksStatus({status: "pending", chains: Array.from(chainLaws)})
      const law: Law | undefined = powers.activeLaws?.find(law => law.index === lawId)

      const checksMap = new Map<string, Checks>()
      if (chainLaws && law) {
        try {
          // For each active law, calculate basic checks
          for (const lawStrId of chainLaws) {
            const targetLaw = powers.activeLaws?.find(law => String(law.index) === lawStrId)
            if (!targetLaw?.conditions) continue
            const singleChecks = await fetchChecks(targetLaw, callData, nonce, wallets, powers)
            checksMap.set(lawStrId, singleChecks as Checks)
          }
  
        setChainChecks(checksMap)
        setChecksStatus({status: "success", chains: Array.from(chainLaws)})

      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch law checks')
      } finally {
        setChecksStatus({status: "success", chains: Array.from(chainLaws)})
        setStatus("success")
      }
    }
  }, [fetchChecks])

  return {status, error, fetchChecks, fetchChainChecks, checkActionStatus, checkAccountAuthorised, hashAction}
}