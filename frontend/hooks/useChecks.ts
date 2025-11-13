import { useCallback, useState } from "react";
import { powersAbi } from "../context/abi";
import { Law, Checks, Status, Powers } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { ConnectedWallet } from "@privy-io/react-auth";
import { readContract } from "wagmi/actions";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";
import { hashAction } from "@/utils/hashAction";
import { getBlockNumber } from '@wagmi/core'

export const useChecks = () => {
  const { chainId } = useParams<{ chainId: string }>() 
  const [checks, setChecks] = useState<Checks | undefined>()
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
                  chainId: parseChainId(chainId)
                })
          // console.log("@checkAccountAuthorised: waypoint 1", {result})
          return result as boolean 
        } catch (error) {
            setStatus("error") 
            setError(error as Error)
            // console.log("@checkAccountAuthorised: waypoint 2", {error})
        }
  }, [])

  const getActionState = useCallback(
    async (law: Law, lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint): Promise<bigint | undefined> => {
      const actionId = hashAction(lawId, lawCalldata, nonce)
      // console.log("@getActionState: waypoint 0", {lawId, lawCalldata, nonce, actionId})

      try {
        const state =  await readContract(wagmiConfig, {
                abi: powersAbi,
                address: law.powers as `0x${string}`,
                functionName: 'getActionState', 
                args: [actionId],
                chainId: parseChainId(chainId)
              })
        return state as bigint

      } catch (error) {
        setStatus("error")
        setError(error as Error)
      }
  }, [])

  const fetchLatestFulfillment = useCallback(async (law: Law) => {
    const latestFulfillment = await readContract(wagmiConfig, {
      abi: powersAbi,
      address: law.powers as `0x${string}`,
      functionName: 'getLatestFulfillment',
      args: [law.index],
      chainId: parseChainId(chainId)
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
    const law = powers.laws?.find(law => law.index === lawId)
    try {
      const blockNumber = await getBlockNumber(wagmiConfig, {
        chainId: parseChainId(chainId),
      })
      // console.log("BlockNumber:", blockNumber)

      const voteData = await readContract(wagmiConfig, {
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
        functionName: 'getActionVoteData',
        args: [actionId],
        chainId: parseChainId(chainId)
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


  // note: I did not implement castVoteWithReason -- to much work for now. 
  const checkHasVoted = useCallback( 
    async (lawId: bigint, nonce: bigint, calldata: `0x${string}`, powers: Powers, account: `0x${string}`): Promise<boolean> => {
      const actionId = hashAction(lawId, calldata, nonce)
      // console.log("checkHasVoted triggered")
        // setStatus({status: "pending"})
        try {
          const result = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'hasVoted', 
            args: [actionId, account],
            chainId: parseChainId(chainId)
          })
          return result as boolean
      } catch (error) {
          setStatus("error") 
          setError({error: error as Error})
          return false
      }
  }, [chainId])

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      // console.log("fetchChecks triggered, waypoint 0", {law, callData, nonce, wallets, powers, actionLawId, caller})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && law.conditions) { 
          // console.log("fetchChecks triggered, waypoint 1", {law, callData, nonce, wallets, powers, actionLawId, caller})
          const checksData = await Promise.all([
            checkThrottledExecution(law),
            checkAccountAuthorised(law, powers, wallets),
            getActionState(law, law.index, callData, nonce),
            getActionState(law, law.conditions.needFulfilled, callData, nonce),
            getActionState(law, law.conditions.needNotFulfilled, callData, nonce),
            checkDelayedExecution(law.index, nonce, callData, powers), 
            checkHasVoted(law.index, nonce, callData, powers, wallets[0].address as `0x${string}`)
          ])
          const [throttled, authorised, actionState, actionStateNeedFulfilled, actionStateNeedNotFulfilled, delayed, hasVoted] = checksData

          const newChecks: Checks =  {
            delayPassed: law.conditions.delayExecution == 0n ? true : delayed,
            throttlePassed: law.conditions.throttleExecution == 0n ? true : throttled,
            authorised,
            actionExists: law.conditions.quorum == 0n ? true : actionState != 0n,
            proposalPassed: law.conditions.quorum == 0n ? true : actionState == 5n || actionState == 6n || actionState == 7n,
            actionNotFulfilled: actionState != 7n,
            lawFulfilled: law.conditions.needFulfilled == 0n ? true : actionStateNeedFulfilled == 7n, 
            lawNotFulfilled: law.conditions.needNotFulfilled == 0n ? true : actionStateNeedNotFulfilled != 7n
          } 
          newChecks.allPassed = Object.values(newChecks).filter(item => item !== undefined).every(item => item === true)
          newChecks.voteActive = law.conditions.quorum == 0n ? true : actionState == 1n
          newChecks.hasVoted = hasVoted

          // console.log("fetchChecks triggered, waypoint 2", {newChecks})
          setChecks(newChecks)
          setStatus("success") //NB note: after checking status, sets the status back to idle! 
          return newChecks
        }       
  }, [ ])

  return {status, error, checks, fetchChecks, getActionState, checkAccountAuthorised, hashAction}
}