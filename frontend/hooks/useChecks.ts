import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Law, Checks, Status, Powers, Action } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { ConnectedWallet } from "@privy-io/react-auth";
import { getPublicClient, readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";
import { hashAction } from "@/utils/hashAction";
import { setActionData, setChainChecks, setChecksStatus } from "@/context/store";
import { useAction } from "./useAction";
import { getBlockNumber } from '@wagmi/core'

export const useChecks = () => {
  const { chainId } = useParams<{ chainId: string }>()
  // const { data: blockNumber, refetch } = useBlockNumber({
  //   chainId: parseChainId(chainId),
  //   cacheTime: 2_000
  // })
  // console.log("blockNumber", {blockNumber, chainId})

  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId),
  })
  const { fetchActionData, fetchVoteData } = useAction()
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  // note: the state of checks is not stored here, it is stored in the Zustand store

  // console.log("useChecks: waypoint 0", {error, status})

  const checkAccountAuthorised = useCallback(
    async (law: Law, powers: Powers, wallets: ConnectedWallet[]) => {
        try {
          // console.log("@checkAccountAuthorised: waypoint 0", {law, powers, wallets})
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'canCallLaw', 
                  args: [wallets[0].address, law.index],
                })
          // console.log("@checkAccountAuthorised: waypoint 1", {result})
          return result as boolean 
        } catch (error) {
            setStatus("error") 
            setError(error)
            // console.log("@checkAccountAuthorised: waypoint 2", {error})
        }
  }, [])

  const checkActionStatus = useCallback(
    async (law: Law, lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint, stateToCheck: number[]): Promise<boolean | undefined> => {
      const actionId = hashAction(lawId, lawCalldata, nonce)
      // console.log("@checkActionStatus: waypoint 0", {lawId, lawCalldata, nonce, stateToCheck, actionId})

      try {
        const state =  await readContract(wagmiConfig, {
                abi: powersAbi,
                address: law.powers as `0x${string}`,
                functionName: 'getActionState', 
                args: [actionId],
              })
        // console.log("@checkActionStatus: waypoint 1", {state})
        const result = stateToCheck.includes(Number(state)) 
        return result 
      } catch (error) {
        setStatus("error")
        setError(error)
      }
  }, [])

  const fetchLatestFulfillment = useCallback(async (law: Law) => {
    const latestFulfillment = await readContract(wagmiConfig, {
      abi: powersAbi,
      address: law.powers as `0x${string}`,
      functionName: 'getLatestFulfillment',
      args: [law.index],
    })
    return latestFulfillment as bigint
  }, [])

  const checkThrottledExecution = useCallback( async (law: Law) => {
    const latestFulfillment = await fetchLatestFulfillment(law)
    
    const blockNumber = await getBlockNumber(wagmiConfig, {
      chainId: parseChainId(chainId),
    })
    // console.log("checkThrottledExecution, waypoint 1", {latestFulfillment, law, blockNumber})

    if (latestFulfillment && blockNumber) {
      const result = Number(latestFulfillment) + Number(law.conditions?.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkDelayedExecution = async (lawId: bigint, nonce: bigint, calldata: `0x${string}`, powers: Powers) => {
    // console.log("CheckDelayedExecution triggered:", {lawId, nonce, calldata, powers})
    const actionId = hashAction(lawId, calldata, nonce)
    // console.log("Deadline ActionId:", actionId)
    const law = powers.ActiveLaws?.find(law => law.index === lawId)
    try {
      const blockNumber = await getBlockNumber(wagmiConfig, {
        chainId: parseChainId(chainId),
      })
      // console.log("BlockNumber:", blockNumber)

      const voteData = await readContract(wagmiConfig, {
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
        functionName: 'getActionVoteData',
        args: [actionId]
      })

      const [voteStart, voteDuration, voteEnd, againstVotes, forVotes, abstainVotes] = voteData as unknown as [
        bigint, bigint, bigint, bigint, bigint, bigint
      ]

      // console.log("Deadline:", voteEnd, "BlockNumber:", blockNumber)
      // console.log("Deadline + Delay:", Number(voteEnd) + Number(law?.conditions?.delayExecution), "BlockNumber:", blockNumber)
      if (voteEnd && blockNumber) {
        const result = Number(voteEnd) > 0 ? Number(voteEnd) + Number(law?.conditions?.delayExecution) < Number(blockNumber) : false  
        // console.log("Deadline Result:", result) 
        return result as boolean
      } else {
        return false
      }
    } catch (error) {
      console.log("Error fetching deadline:", error)
      return false
    }
  }

  const calculateDependencies = (lawId: bigint, powers: Powers) => {
    const selectedLawId = String(lawId)
    const connectedNodes: Set<string> = new Set()
    
    if (powers.ActiveLaws) {
      // Build dependency maps
      const dependencies = new Map<string, Set<string>>()
      const dependents = new Map<string, Set<string>>()
      
      powers.ActiveLaws.forEach(law => {
        const lawId = String(law.index)
        dependencies.set(lawId, new Set())
        dependents.set(lawId, new Set())
      })
      
      // Populate dependency relationships
      powers.ActiveLaws.forEach(law => {
        const lawId = String(law.index)
        if (law.conditions) {
          if (law.conditions.needFulfilled !== 0n) {
            const targetId = String(law.conditions.needFulfilled)
            if (dependencies.has(targetId)) {
              dependencies.get(lawId)?.add(targetId)
              dependents.get(targetId)?.add(lawId)
            }
          }
          if (law.conditions.needNotFulfilled !== 0n) {
            const targetId = String(law.conditions.needNotFulfilled)
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
          const proposalStatus = await checkActionStatus(law, law.index, callData, nonce, [5, 6, 7])
          const voteActive = await checkActionStatus(law, law.index, callData, nonce, [1])
          const proposalExists = await checkActionStatus(law, law.index, callData, nonce, [0])
          const delayed = await checkDelayedExecution(law.index, nonce, callData, powers)
          // console.log("delay passed at law", law.index, {delayed})

          const notFulfilled1 = await checkActionStatus(law, law.index, callData, nonce, [5])
          const notFulfilled2 = await checkActionStatus(law, law.conditions.needFulfilled, callData, nonce, [5])
          const notFulfilled3 = await checkActionStatus(law, law.conditions.needNotFulfilled, callData, nonce, [5])

          // console.log("notFulfilled1", {notFulfilled1})

            const newChecks: Checks =  {
              delayPassed: law.conditions.delayExecution == 0n ? true : delayed,
              throttlePassed: law.conditions.throttleExecution == 0n ? true : throttled,
              authorised,
              proposalExists: law.conditions.quorum == 0n ? true : proposalExists == false,
              voteActive: law.conditions.quorum == 0n ? true : voteActive,
              proposalPassed: law.conditions.quorum == 0n ? true : proposalStatus,
              actionNotFulfilled: !notFulfilled1,
              lawFulfilled: law.conditions.needFulfilled == 0n ? true : notFulfilled2, 
              lawNotFulfilled: law.conditions.needNotFulfilled == 0n ? true : !notFulfilled3 
            } 
            newChecks.allPassed =  
              newChecks.delayPassed && 
              newChecks.throttlePassed && 
              newChecks.authorised && 
              newChecks.proposalExists && 
              newChecks.proposalPassed && 
              newChecks.actionNotFulfilled && 
              newChecks.lawFulfilled &&
              newChecks.lawNotFulfilled 
          
            // console.log("fetchChecks triggered, waypoint 2", {newChecks})
            setStatus("success") //NB note: after checking status, sets the status back to idle! 
            return newChecks
        }       
  }, [ ])

  
  // Only fetch action and vote data for dependent laws; do not re-run checks.
  const fetchChainStatus = useCallback(
    async (lawId: bigint, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      const chainLaws = calculateDependencies(lawId, powers)
      setChecksStatus({status: "pending", chains: Array.from(chainLaws)})
      const currentLaw: Law | undefined = powers.ActiveLaws?.find(law => law.index === lawId)

      const emptyChecksMap = new Map<string, Checks>()
      const actionDataMap = new Map<string, Action>()
      if (chainLaws && currentLaw) {
        try {
          for (const lawStrId of chainLaws) {
            // Skip the current law; only fetch status for other connected laws
            if (String(lawId) === lawStrId) continue

            const targetLaw = powers.ActiveLaws?.find(l => String(l.index) === lawStrId)
            if (!targetLaw) continue

            const computedActionId = hashAction(BigInt(lawStrId), callData, nonce)

            // Build a minimal action object for downstream hooks
            const baseAction: Action = {
              actionId: computedActionId.toString(),
              lawId: BigInt(lawStrId)
            }

            // Always fetch core action data
            const withActionData = await fetchActionData(baseAction, powers)
            if (!withActionData) continue

            // Optionally fetch vote data if the target law uses voting
            let finalAction: Action = withActionData
            if (targetLaw.conditions && targetLaw.conditions.quorum != 0n) {
              const withVotes = await fetchVoteData(withActionData, powers)
              if (withVotes) {
                finalAction = withVotes
              }
            }

            actionDataMap.set(lawStrId, finalAction)
          }

          setChainChecks(emptyChecksMap)
          setActionData(actionDataMap)

        } catch (err) {
          setError(err instanceof Error ? err.message : 'Failed to fetch chain status')
        } finally {
          setChecksStatus({status: "success", chains: Array.from(chainLaws)})
          setStatus("success")
        }
      }
    }
  , [fetchActionData, fetchVoteData])

  return {status, error, fetchChecks, fetchChainStatus, checkActionStatus, checkAccountAuthorised, hashAction}
}