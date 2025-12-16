import { useCallback, useState } from "react";
import { powersAbi } from "../context/abi";
import { Mandate, Checks, Status, Powers } from "../context/types"
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
    async (mandate: Mandate, powers: Powers, wallets: ConnectedWallet[]) => {
        try {
          // console.log("@checkAccountAuthorised: waypoint 0", {mandate, powers, wallets})
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: powers.contractAddress as `0x${string}`,
                  functionName: 'canCallMandate', 
                  args: [wallets[0].address, mandate.index],
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
    async (mandate: Mandate, mandateId: bigint, mandateCalldata: `0x${string}`, nonce: bigint): Promise<bigint | undefined> => {
      const actionId = hashAction(mandateId, mandateCalldata, nonce)
      // console.log("@getActionState: waypoint 0", {mandateId, mandateCalldata, nonce, actionId})

      try {
        const state =  await readContract(wagmiConfig, {
                abi: powersAbi,
                address: mandate.powers as `0x${string}`,
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

  const fetchLatestFulfillment = useCallback(async (mandate: Mandate) => {
    const latestFulfillment = await readContract(wagmiConfig, {
      abi: powersAbi,
      address: mandate.powers as `0x${string}`,
      functionName: 'getLatestFulfillment',
      args: [mandate.index],
      chainId: parseChainId(chainId)
    })
    return latestFulfillment as bigint
  }, [])

  const checkThrottledExecution = useCallback( async (mandate: Mandate) => {
    const latestFulfillment = await fetchLatestFulfillment(mandate)
    
    const blockNumber = await getBlockNumber(wagmiConfig, {
      chainId: parseChainId(chainId),
    })
    // console.log("checkThrottledExecution, waypoint 1", {latestFulfillment, mandate, blockNumber})

    if (latestFulfillment && blockNumber) {
      const result = Number(latestFulfillment) + Number(mandate.conditions?.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkDelayedExecution = async (mandateId: bigint, nonce: bigint, calldata: `0x${string}`, powers: Powers) => {
    // console.log("CheckDelayedExecution triggered:", {mandateId, nonce, calldata, powers})
    const actionId = hashAction(mandateId, calldata, nonce)
    // console.log("Deadline ActionId:", actionId)
    const mandate = powers.mandates?.find(mandate => mandate.index === mandateId)
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
      // console.log("Deadline + Delay:", Number(voteEnd) + Number(mandate?.conditions?.timelock), "BlockNumber:", blockNumber)
      if (voteEnd && blockNumber) {
        const result = Number(voteEnd) > 0 ? Number(voteEnd) + Number(mandate?.conditions?.timelock) < Number(blockNumber) : false  
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
    async (mandateId: bigint, nonce: bigint, calldata: `0x${string}`, powers: Powers, account: `0x${string}`): Promise<boolean> => {
      const actionId = hashAction(mandateId, calldata, nonce)
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
    async (mandate: Mandate, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      // console.log("fetchChecks triggered, waypoint 0", {mandate, callData, nonce, wallets, powers, actionMandateId, caller})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && mandate.conditions) { 
          // console.log("fetchChecks triggered, waypoint 1", {mandate, callData, nonce, wallets, powers, actionMandateId, caller})
          const checksData = await Promise.all([
            checkThrottledExecution(mandate),
            checkAccountAuthorised(mandate, powers, wallets),
            getActionState(mandate, mandate.index, callData, nonce),
            getActionState(mandate, mandate.conditions.needFulfilled, callData, nonce),
            getActionState(mandate, mandate.conditions.needNotFulfilled, callData, nonce),
            checkDelayedExecution(mandate.index, nonce, callData, powers), 
            checkHasVoted(mandate.index, nonce, callData, powers, wallets[0].address as `0x${string}`)
          ])
          const [throttled, authorised, actionState, actionStateNeedFulfilled, actionStateNeedNotFulfilled, delayed, hasVoted] = checksData

          const newChecks: Checks =  {
            delayPassed: mandate.conditions.timelock == 0n ? true : delayed,
            throttlePassed: mandate.conditions.throttleExecution == 0n ? true : throttled,
            authorised,
            actionExists: mandate.conditions.quorum == 0n ? true : actionState != 0n,
            proposalPassed: mandate.conditions.quorum == 0n ? true : actionState == 5n || actionState == 6n || actionState == 7n,
            actionNotFulfilled: actionState != 7n,
            mandateFulfilled: mandate.conditions.needFulfilled == 0n ? true : actionStateNeedFulfilled == 7n, 
            mandateNotFulfilled: mandate.conditions.needNotFulfilled == 0n ? true : actionStateNeedNotFulfilled != 7n
          } 
          newChecks.allPassed = Object.values(newChecks).filter(item => item !== undefined).every(item => item === true)
          newChecks.voteActive = mandate.conditions.quorum == 0n ? true : actionState == 1n
          newChecks.hasVoted = hasVoted

          // console.log("fetchChecks triggered, waypoint 2", {newChecks})
          setChecks(newChecks)
          setStatus("success") //NB note: after checking status, sets the status back to idle! 
          return newChecks
        }       
  }, [ ])

  return {status, error, checks, fetchChecks, getActionState, checkAccountAuthorised, hashAction}
}