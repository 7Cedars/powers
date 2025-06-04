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

export const useChecks = (powers: Powers) => {
  const { chainId } = useParams<{ chainId: string }>()
  const supportedChains = useChains()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))
  const constants = getConstants(parseChainId(chainId) as number)
  const { data: blockNumber } = useBlockNumber({
    chainId: parseChainId(chainId)
  })
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()
  const [chainChecks, setChainChecks] = useState<Map<string, Checks>>()

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


  const checkDelayedExecution = (nonce: bigint, calldata: `0x${string}`, law: Law, powers: Powers) => {
    // console.log("CheckDelayedExecution triggered")
    const actionId = hashAction(law.index, calldata, nonce)
    const selectedProposal = powers.proposals?.find(proposal => BigInt(proposal.actionId) == actionId)

    // console.log("waypoint 1, CheckDelayedExecution: ", {selectedProposal, blockNumber})
    const result = Number(selectedProposal?.voteEnd) + Number(law.conditions?.delayExecution) < Number(blockNumber)
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

    // console.log("checkThrottledExecution, waypoint 1", {fetchedExecutions, law})

    if (fetchedExecutions && fetchedExecutions.executions?.length > 0) {
      const result = Number(fetchedExecutions?.executions[0]) + Number(law.conditions?.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      // console.log("fetchChecks triggered, waypoint 0", {law, callData, nonce, wallets, powers})
        setError(null)
        setStatus("pending")

        if (wallets[0] && powers?.contractAddress && law.conditions) {
          
          const throttled = await checkThrottledExecution(law)
          const authorised = await checkAccountAuthorised(law, powers, wallets)
          const proposalStatus = await checkActionStatus(law, law.index, callData, nonce, [3, 4, 5])
          const proposalExists = await checkActionStatus(law, law.index, callData, nonce, [6])
          const delayed = checkDelayedExecution(nonce, callData, law, powers)

          const notCompleted1 = await checkActionStatus(law, law.index, callData, nonce, [5])
          const notCompleted2 = await checkActionStatus(law, law.conditions.needCompleted, callData, nonce, [5])
          const notCompleted3 = await checkActionStatus(law, law.conditions.needNotCompleted, callData, nonce, [5])

          // console.log({notCompleted1: !notCompleted1})
          
          // console.log("fetchChecks triggered, waypoint 1", {delayed, throttled, authorised, proposalStatus, proposalExists, notCompleted1, notCompleted2, notCompleted3})

            let newChecks: Checks =  {
              delayPassed: law.conditions.delayExecution == 0n ? true : delayed,
              throttlePassed: law.conditions.throttleExecution == 0n ? true : throttled,
              authorised: authorised,
              proposalExists: law.conditions.quorum == 0n ? true : proposalExists == false,
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
            
            setChecks(newChecks)
            // console.log("fetchChecks triggered, waypoint 2", {newChecks})
            setStatus("success") //NB note: after checking status, sets the status back to idle! 
            return newChecks
        }       
  }, [ ])

  const fetchChainChecks = useCallback(
    async (originLaw: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => {
      const chainLaws = powers.laws?.filter(law => 
        law.conditions?.needCompleted == originLaw.index || 
        law.conditions?.needNotCompleted == originLaw.index || 
        law.conditions?.readStateFrom == originLaw.index 
      )

      const checksMap = new Map<string, Checks>()
      if (chainLaws) {
        try {
          // For each active law, calculate basic checks
          for (const law of chainLaws) {
            if (!law.conditions) continue
            const checks = await fetchChecks(law, callData, nonce, wallets, powers)
            checksMap.set(String(law.index), checks as Checks)
          }
  
        setChainChecks(checksMap)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch law checks')
      } finally {
        setStatus("success")
      }
    }
  }, [fetchChecks])

  return {status, error, checks, chainChecks, fetchChecks, fetchChainChecks, checkActionStatus, checkAccountAuthorised, hashAction, setChainChecks}
}