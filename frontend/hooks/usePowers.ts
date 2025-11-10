import { Status, Action, Powers, Law, Metadata, Role, Conditions } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { useParams } from "next/navigation";
import { setPowers, setError, setStatus } from "@/context/store";

export const usePowers = () => {
  const { chainId, powers: address } = useParams<{ chainId: string, powers: `0x${string}` }>()
  // console.log("@usePowers, MAIN", {chainId, error, powers, status})

  // function to save powers to local storage
  const savePowers = (powers: Powers) => {
    // console.log("@savePowers, waypoint 0", {powers})
    const localStore = localStorage.getItem("powersProtocols")
    // console.log("@savePowers, waypoint 1", {localStore})
    const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
    // console.log("@savePowers, waypoint 2", {saved})
    const existing = saved.find(item => item.contractAddress == address)
    if (existing) {
      saved.splice(saved.indexOf(existing), 1)
    }
    saved.push(powers)
    localStorage.setItem("powersProtocols", JSON.stringify(saved, (key, value) =>
      typeof value === "bigint" ? value.toString() : value,
    ));
  }

  // Everytime powers is fetched these functions are called. 
  const fetchPowersData = async(powers: Powers): Promise<Powers | undefined> => {
    const powersPopulated: Powers | undefined = powers
    // console.log("@fetchPowersData, waypoint 0", {powers})
    try { 
      const [ namePowers, uriPowers, lawCountPowers, treasuryPowers] = await readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: [
          {
            address: powers.contractAddress as `0x${string}`,
            abi: powersAbi,
            functionName: 'name',
            chainId: parseChainId(chainId)
          },
          {
            address: powers.contractAddress as `0x${string}`,
            abi: powersAbi,
            functionName: 'uri',
            chainId: parseChainId(chainId)
          },
          {
            address: powers.contractAddress as `0x${string}`,
            abi: powersAbi,
            functionName: 'lawCounter',
            chainId: parseChainId(chainId)
          },
          {
            address: powers.contractAddress as `0x${string}`,
            abi: powersAbi,
            functionName: 'getTreasury',
            chainId: parseChainId(chainId)
          }
        ]
      }) as [string, string, bigint, `0x${string}`]

      // console.log("@fetchPowersData, waypoint 1", {namePowers, uriPowers, lawCountPowers})
      powersPopulated.lawCount = lawCountPowers as bigint
      powersPopulated.name = namePowers as string
      powersPopulated.uri = uriPowers as string
      powersPopulated.treasury = treasuryPowers as `0x${string}`
      // console.log("@fetchPowersData, waypoint 2", {powersPopulated})
      return powersPopulated

    } catch (error) {
      console.log("@fetchPowersData, waypoint 3", {error})
      setStatus({status: "error"}) 
      setError({error: error as Error})
    }
  }

  const fetchMetaData = async (powers: Powers): Promise<Metadata | undefined> => {
    let updatedMetaData: Metadata | undefined

    if (powers && powers.uri) {
      try {
          const fetchedMetadata: unknown = await(
            await fetch(powers.uri as string)
            ).json() 
          updatedMetaData = parseMetadata(fetchedMetadata) 
          return updatedMetaData
      } catch (error) {
        setStatus({status: "error"}) 
        setError({error: error as Error})
      }
    }
    return undefined
  }
  
  const checkLaws = async (lawIds: bigint[]) => {
    const fetchedLaws: Law[] = []

    if (wagmiConfig && lawIds.length > 0 && address) {
        try {
          const contracts = lawIds.map((id) => ({
            abi: powersAbi,
            address: address as `0x${string}`,
            functionName: 'getAdoptedLaw' as const,
            args: [BigInt(id)] as [bigint],
            chainId: parseChainId(chainId)
          }))

          const results = await readContracts(wagmiConfig, {
            allowFailure: false,
            contracts
          }) as Array<[`0x${string}`, `0x${string}`, boolean]>

          results.forEach((lawTuple, idx) => {
            const id = lawIds[idx]
            fetchedLaws.push({
              powers: address,
              lawAddress: lawTuple[0] as unknown as `0x${string}`,
              lawHash: lawTuple[1] as unknown as `0x${string}`,
              index: id,
              active: lawTuple[2] as unknown as boolean
            })
          })
          return fetchedLaws
        } catch (error) {
          setStatus({status: "error"})
          setError({error: error as Error})
        }
    }
  }

  const populateLaws = async (laws: Law[]) => {
    let law: Law
    const populatedLaws: Law[] = []

    try {
      type PendingCall = {
        kind: 'conditions' | 'inputParams' | 'nameDescription'
        lawIdx: number
      }
      const contracts: any[] = []
      const pending: PendingCall[] = []

      laws.forEach((l, idx) => {
        if (l.lawAddress != `0x0000000000000000000000000000000000000000`) {
          if (!l.conditions) {
            contracts.push({
              abi: powersAbi,
              address: l.powers as `0x${string}`,
              functionName: 'getConditions',
              args: [l.index],
              chainId: parseChainId(chainId)!
            })
            pending.push({ kind: 'conditions', lawIdx: idx })
          }
          if (!l.inputParams) {
            contracts.push({
              abi: lawAbi,
              address: l.lawAddress as `0x${string}`,
              functionName: 'getInputParams',
              args: [l.powers, l.index],
              chainId: parseChainId(chainId)!
            })
            pending.push({ kind: 'inputParams', lawIdx: idx })
          }
          if (!l.nameDescription) {
            contracts.push({
              abi: lawAbi,
              address: l.lawAddress as `0x${string}`,
              functionName: 'getNameDescription',
              args: [l.powers, l.index],
              chainId: parseChainId(chainId)!
            })
            pending.push({ kind: 'nameDescription', lawIdx: idx })
          }
        }
      })

      if (contracts.length > 0) {
        const results = await readContracts(wagmiConfig, {
          allowFailure: false,
          contracts
        })

        // Apply results back to the corresponding laws in order
        results.forEach((value, i) => {
          const meta = pending[i]
          const target = laws[meta.lawIdx]
          if (meta.kind === 'conditions') {
            target.conditions = value as Conditions
          } else if (meta.kind === 'inputParams') {
            target.inputParams = value as `0x${string}`
            target.params = bytesToParams(target.inputParams)
          } else if (meta.kind === 'nameDescription') {
            target.nameDescription = value as string
          }
        })
      }

      for (law of laws) {
        populatedLaws.push(law)
      }
      return populatedLaws
    } catch (error) {
      setStatus({status: "error"}) 
      setError({error: error as Error})
    }
  }

  const fetchRoles = async (laws: Law[]): Promise<Role[] | undefined> => {
    const rolesIds = new Set(laws.filter((law) => law.active).flatMap((law) => law.conditions?.allowedRole) || [])
 
    let updatedRoleLabels: Role[] = []

    if (rolesIds.size > 0) {
    try {
      // Build a multicall to fetch labels and holder counts for all roles
      const contracts = Array.from(rolesIds).flatMap((roleId) => ([
        {
          abi: powersAbi,
          address: laws[0].powers as `0x${string}`,
          functionName: 'getRoleLabel' as const,
          args: [roleId] as [bigint],
          chainId: parseChainId(chainId)
        },
        {
          abi: powersAbi,
          address: laws[0].powers as `0x${string}`,
          functionName: 'getAmountRoleHolders' as const,
          args: [roleId] as [bigint],
          chainId: parseChainId(chainId)
        }
      ]))

      const results = await readContracts(wagmiConfig, {
        allowFailure: false,
        contracts
      })
      // console.log("@fetchRoles, waypoint 1", {results})
      
      // results are in pairs [label, holders] per role in same order
      for (let i = 0; i < rolesIds.size; i++) {
        const label = results[i * 2] as string
        const holders = results[i * 2 + 1] as bigint
        updatedRoleLabels.push({ roleId: Array.from(rolesIds)[i] as bigint, label, amountHolders: holders })
      }
      // console.log("@fetchRoles, waypoint 2", {updatedRoleLabels})
      return updatedRoleLabels
    } catch (error) {
        setStatus({status: "error"})
        setError({error: error as Error})
        return []
      }
    }
  }

  const fetchLaws = async (powers: Powers): Promise<Law[] | undefined> => {
    try {
      const lawCount = await readContract(wagmiConfig, {
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
        functionName: 'lawCounter',
        chainId: parseChainId(chainId)
      })
      const lawIds = Array.from({length: Number(lawCount) - 1}, (_, i) => BigInt(i+1))
      const laws = await checkLaws(lawIds)
      if (laws) {
        const lawsPopulated = await populateLaws(laws)
        return lawsPopulated
      } else {
        setStatus({status: "error"})
        setError({error: Error("Failed to fetch laws")})
        return undefined
      }
    } catch (error) {
      setStatus({status: "error"})
      setError({error: error as Error})
      return undefined
    }
  }

  const populateActions = async(actionIds: string[], powersAddress: `0x${string}`): Promise<Action[]> => {
    if (actionIds.length === 0) return []

    const [stateResults, dataResults, calldataResults, uriResults] = await Promise.all([
      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powersAddress as `0x${string}`,
          functionName: 'getActionState' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<number>>,

      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powersAddress as `0x${string}`,
          functionName: 'getActionData' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<[
        number,      // lawId (uint16)
        bigint,      // proposedAt (uint48)
        bigint,      // requestedAt (uint48)
        bigint,      // fulfilledAt (uint48)
        bigint,      // cancelledAt (uint48)
        `0x${string}`, // caller (address)
        bigint       // nonce (uint256)
      ]>>,

      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powersAddress as `0x${string}`,
          functionName: 'getActionCalldata' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<`0x${string}`>>,

      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powersAddress as `0x${string}`,
          functionName: 'getActionUri' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<string>>
    ])

    const actions: Action[] = actionIds.map((actionId, idx) => {
      const data = dataResults[idx]
      
      return {
        actionId: actionId,
        lawId: BigInt(data[0]),
        proposedAt: data[1],
        requestedAt: data[2],
        fulfilledAt: data[3],
        cancelledAt: data[4],
        caller: data[5],
        nonce: String(data[6]),
        callData: calldataResults[idx],
        description: uriResults[idx],
        state: stateResults[idx]
      }
    })

    return actions
  }
  
  // Returns a mapping of non-stale actionIds to their lawId and index
  const fetchActions = async (laws: Law[]): Promise<Law[] | undefined> => {
    const activeLaws = laws.filter((law) => law.active)

    // Step 1: Identify stale actions by law
    const staleActionsByLaw = new Map<string, Set<number>>() // lawId -> Set of stale indices
    
    activeLaws.forEach((law) => {
      const savedActions = law.actions || []
      const staleIndices = new Set<number>()
      
      savedActions.forEach((action, index) => {
        // State 2, 4, or 7 are stale (Defeated, Fulfilled, or NonExistent)
        if (action.state === 2 || action.state === 4 || action.state === 7) {
          staleIndices.add(index)
        }
      })
      
      if (staleIndices.size > 0) {
        staleActionsByLaw.set(law.index.toString(), staleIndices)
      }
    })

    // Step 2: Fetch action quantities for each active law
    const actionQuantities = await readContracts(wagmiConfig, {
      allowFailure: false,
      contracts: activeLaws.map((law) => ({
        abi: powersAbi,
        address: activeLaws[0].powers as `0x${string}`,
        functionName: 'getQuantityLawActions' as const,
        args: [law.index],
        chainId: parseChainId(chainId)
      }))
    }) as Array<bigint>

    // Step 3: Create list of non-stale action indices to fetch per law
    type FetchRequest = {
      lawId: bigint
      actionIndex: number
    }
    
    const fetchRequests: FetchRequest[] = []
    
    actionQuantities.forEach((quantity, lawIndex) => {
      const law = activeLaws[lawIndex]
      const lawId = law.index
      const staleIndices = staleActionsByLaw.get(lawId.toString()) || new Set()
      
      // Create requests for non-stale indices only
      for (let i = 0; i < Number(quantity); i++) {
        if (!staleIndices.has(i)) {
          fetchRequests.push({
            lawId,
            actionIndex: i
          })
        }
      }
    })

    // Early exit if no actions to fetch
    if (fetchRequests.length === 0) {
      return laws
    }

    // Step 4: Fetch actionIds for non-stale actions
    const actionIds = await readContracts(wagmiConfig, {
      allowFailure: false,
      contracts: fetchRequests.map((req) => ({
        abi: powersAbi,
        address: activeLaws[0].powers as `0x${string}`,
        functionName: 'getLawActionAtIndex' as const,
        args: [req.lawId, BigInt(req.actionIndex)],
        chainId: parseChainId(chainId)
      }))
    }) as Array<bigint>

    // Step 5: Create mapping of actionId -> { lawId, index }
    const actionIdMapping = new Map<string, { lawId: bigint, index: number }>()
    
    fetchRequests.forEach((req, idx) => {
      const actionId = actionIds[idx]
      actionIdMapping.set(actionId.toString(), {
        lawId: req.lawId,
        index: req.actionIndex
      })
    })

    // Step 6: Populate actions with full data
    const actionIdsArray = Array.from(actionIdMapping.keys())
    const populatedActions = await populateActions(actionIdsArray, activeLaws[0].powers as `0x${string}`)

    // Step 7: Organize actions by law and index
    const actionsByLaw = new Map<string, Map<number, Action>>() // lawId -> (index -> Action)
    
    populatedActions.forEach((action) => {
      const mapping = actionIdMapping.get(action.actionId)
      if (mapping) {
        const lawKey = mapping.lawId.toString()
        
        if (!actionsByLaw.has(lawKey)) {
          actionsByLaw.set(lawKey, new Map())
        }
        
        actionsByLaw.get(lawKey)!.set(mapping.index, action)
      }
    })

    // Step 8: Update laws with populated actions (including stale actions)
    const updatedLaws = laws.map((law) => {
      const lawKey = law.index.toString()
      const newActionsByIndex = actionsByLaw.get(lawKey)
      
      if (!newActionsByIndex && !law.active) {
        // Inactive law with no new actions - keep as is
        return law
      }
      
      // Get the total quantity for this law
      const lawIndex = activeLaws.findIndex(l => l.index === law.index)
      const quantity = lawIndex >= 0 ? Number(actionQuantities[lawIndex]) : 0
      
      if (quantity === 0) {
        return { ...law, actions: [] }
      }
      
      // Build actions array with correct indices
      const actionsArray: Action[] = new Array(quantity)
      const savedActions = law.actions || []
      const staleIndices = staleActionsByLaw.get(lawKey) || new Set()
      
      // First, place stale actions at their indices
      savedActions.forEach((action, index) => {
        if (staleIndices.has(index)) {
          actionsArray[index] = action
        }
      })
      
      // Then, place newly fetched actions at their indices
      if (newActionsByIndex) {
        newActionsByIndex.forEach((action, index) => {
          actionsArray[index] = action
        })
      }
      
      // Filter out undefined entries
      const finalActions = actionsArray.filter(a => a !== undefined)
      
      return {
        ...law,
        actions: finalActions
      }
    })
    return updatedLaws
  }

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      // console.log("@fetchPowers, waypoint 0", {address}
      setStatus({status: "pending"})
      let metaData: Metadata | undefined
      let laws: Law[] | undefined
      let lawWithActions: Law[] | undefined
      let roles: Role[] | undefined

      const localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress == address)

      const powersToBeUpdated = existing ? existing : {
        contractAddress: address,
        chainId: BigInt(chainId)
      }
      // console.log("@refetchPowers, waypoint 1", {powersToBeUpdated})

      try {
        const data = await fetchPowersData(powersToBeUpdated)
        // console.log("@refetchPowers, waypoint 2", {data})

        if (data) {
          [metaData, laws] = await Promise.all([
            fetchMetaData(data),
            fetchLaws(data)
          ])
        }
        if (laws) {
          lawWithActions = await fetchActions(laws)
          roles = await fetchRoles(laws)
        }

        // console.log("@refetchPowers, waypoint 4", {metaData, laws})

        if (data != undefined && metaData != undefined && laws != undefined) {
          // console.log("@refetchPowers, waypoint 7", {data, metaData, laws, actions})
          const newPowers: Powers = {
            contractAddress: powersToBeUpdated.contractAddress as `0x${string}`,
            chainId: BigInt(chainId),
            name: data.name,
            metadatas: metaData,
            uri: data.uri,
            treasury: data.treasury,
            lawCount: data.lawCount,
            laws: lawWithActions,
            roles: roles,
            layout: powersToBeUpdated.layout
          }
          // console.log("@refetchPowers, waypoint 8", {newPowers})
          setPowers(newPowers)
          savePowers(newPowers)
        }
      } catch (error) {
         console.error("@fetchPowers error:", error)
        setStatus({status: "error"})
        setError({error: error as Error})
      } finally {
        setStatus({status: "success"})
      }
    }, [ ] 
  )

  return {fetchPowers}  
}
