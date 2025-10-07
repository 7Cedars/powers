import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, Action, Powers, ActionTruncated } from "../context/types"
import { readContract, readContracts } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { parseChainId, parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { useParams } from "next/navigation";

export const useAction = () => {
  const { chainId } = useParams<{ chainId: string }>()
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [action, setAction ] = useState<Action | undefined>()

  const savePowers = (powers: Powers) => {
    const localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
    const existing = saved.find(item => item.contractAddress == powers.contractAddress)
    if (existing) {
      saved.splice(saved.indexOf(existing), 1)
    }
    saved.push(powers)
    localStorage.setItem("powersProtocols", JSON.stringify(saved, (key, value) =>
      typeof value === "bigint" ? value.toString() : value,
    ));
  }

  const fetchVoteData = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ) => {
      setError(null)
      setStatus("pending")
      
      try {
        const [{ result: voteData }, { result: state }] = await readContracts(wagmiConfig, {
          contracts: [
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionVoteData',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            },
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionState',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            }
          ]
        })

        const [voteStart, voteDuration, voteEnd, againstVotes, forVotes, abstainVotes] = voteData as unknown as [
          bigint, bigint, bigint, bigint, bigint, bigint
        ]

        const action: Action = {
          ...actionObject,
          state: state as number,
          voteStart: voteStart as bigint,
          voteDuration: voteDuration as bigint,
          voteEnd: voteEnd as bigint,
          againstVotes: againstVotes as bigint,
          forVotes: forVotes as bigint,
          abstainVotes: abstainVotes as bigint,
        }

        setAction(action)
        setStatus("success")
        return action
      } catch (error) {
        setStatus("error")
        setError(error)
        return undefined
      }
    }, [ ])

  const fetchActionMetadata = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ) => {
      setError(null)
      setStatus("pending")

      try {
        const [{ result: lawCalldata }, { result: actionUri }] = await readContracts(wagmiConfig, {
          contracts: [
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionCalldata',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            },
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionUri',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            }
          ]
        })
        const law = powers.laws?.find(l => l.index == actionObject.lawId)
        const dataTypes = law?.params?.map(param => param.dataType)
        let valuesParsed = undefined
        if (dataTypes != undefined && dataTypes.length > 0) {
          const values = decodeAbiParameters(
            parseAbiParameters(dataTypes.toString()),
            lawCalldata as `0x${string}`
          );
          valuesParsed = parseParamValues(values)
        }

        const merged: Action = {
          ...actionObject,
          dataTypes,
          paramValues: valuesParsed,
          description: actionUri as string,
          callData: lawCalldata as `0x${string}`,
          upToDate: true
        }

        setAction(merged)
        setStatus("success")
        return merged
      } catch (error) {
        setStatus("error")
        setError(error)
        return undefined
      }
    }, [ ])

  const fetchActionData = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ) => {
      setError(null)
      setStatus("pending")

      try {
        const [{ result: actionDataRaw }] = await readContracts(wagmiConfig, {
          contracts: [
            {
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionData',
              args: [BigInt(actionObject.actionId)],
              chainId: parseChainId(chainId)
            }
          ]
        })

        const [lawId, proposedAt, requestedAt, fulfilledAt, cancelledAt, caller, nonce] = actionDataRaw as unknown as [
          bigint, bigint, bigint, bigint, bigint, `0x${string}`, bigint
        ]


        const merged: Action = {
          ...actionObject,
          lawId: lawId,
          caller: caller,
          nonce: String(nonce),
          upToDate: true,
          proposedAt: proposedAt,
          requestedAt: requestedAt,
          cancelledAt: cancelledAt,
          fulfilledAt: fulfilledAt
        }

        setAction(merged)
        setStatus("success")
        return merged
      } catch (error) {
        setStatus("error")
        setError(error)
        return undefined
      }
    }, [ ])

  const fetchAction = useCallback(
    async (
      actionObject: Action,
      powers: Powers
    ) => {
      // if action is cancelled, defeated, or fulfilled, return the action object as it is.
      if (actionObject.state == 2 || actionObject.state == 4 || actionObject.state == 7) return actionObject

      const withVotes = await fetchVoteData(actionObject, powers) // bote data needs to always be fetched as it also returns state of the action.  
      if (!withVotes) return undefined
      const withMetadata = await fetchActionMetadata(withVotes, powers)
      if (!withMetadata) return undefined
      const withData = await fetchActionData(withMetadata, powers)
      if (!withData) return undefined
      setAction(withData)
      return withData
    }, [ fetchVoteData, fetchActionMetadata, fetchActionData ])

  
  const fetchLawActions = useCallback(
    async (powers: Powers, lawId: bigint) => {
      const law = powers.laws?.find(l => l.index === lawId)
      if (!law) return [] as Action[]

      const unique = new Map<string, bigint>()
      law.actions?.forEach(a => {
        if (a.actionId) unique.set(a.actionId, law.index)
      })

      const initial: Action[] = Array.from(unique.entries()).map(([actionId, lId]) => ({
        actionId,
        lawId: lId
      }))

      const results = await Promise.all(initial.map(a => fetchAction(a, powers)))
      const populated = results.filter((a): a is Action => Boolean(a))

      if (powers.laws && populated.length > 0) {
        const updatedLaws = powers.laws.map(l => (
          l.index === lawId ? { ...l, actions: populated } : l
        ))
        const powersUpdated: Powers = { ...powers, laws: updatedLaws }
        try { 
          savePowers(powersUpdated) 
        } catch (error) {
          console.error("Error saving powers", error)
        }
      }

      return populated
    }, [ fetchAction ])


  const fetchAllActions = useCallback(
    async (powers: Powers) => {
      const unique = new Map<string, bigint>()
      powers.laws?.forEach(law => {
        law.actions?.forEach(action => {
          if (action.actionId) {
            unique.set(action.actionId, law.index)
          }
        })
      })

      const initialActions: Action[] = Array.from(unique.entries()).map(([actionId, lawId]) => ({
        actionId,
        lawId
      }))

      const results = await Promise.all(initialActions.map(a => fetchAction(a, powers)))
      const populated = results.filter((a): a is Action => Boolean(a))

      // Map actions back onto their corresponding laws
      if (powers.laws && populated.length > 0) {
        const lawIdToActions = new Map<string, Action[]>()
        populated.forEach(a => {
          const key = String(a.lawId)
          const arr = lawIdToActions.get(key) || []
          arr.push(a)
          lawIdToActions.set(key, arr)
        })

        const updatedLaws = powers.laws.map(l => ({
          ...l,
          actions: lawIdToActions.get(String(l.index)) || l.actions || []
        }))

        const powersUpdated: Powers = { ...powers, laws: updatedLaws }
        try { 
          savePowers(powersUpdated) 
        } catch (error) {
          console.error("Error saving powers", error)
        }
      }

      return populated
    }, [ fetchAction ])

  return {status, error, action, fetchVoteData, fetchActionMetadata, fetchActionData, fetchAction, fetchAllActions, fetchLawActions}
}