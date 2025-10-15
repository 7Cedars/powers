import { Status, Action, Powers, Law, Metadata, Role, Conditions } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { useParams } from "next/navigation";

export const usePowers = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [powers, setPowers] = useState<Powers | undefined>() 
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
    console.log("@fetchPowersData, waypoint 0", {powers})
    try { 
      const [ namePowers, uriPowers, lawCountPowers] = await readContracts(wagmiConfig, {
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
          }
        ]
      }) as [string, string, bigint]

      console.log("@fetchPowersData, waypoint 1", {namePowers})
      powersPopulated.lawCount = lawCountPowers as bigint
      powersPopulated.name = namePowers as string
      powersPopulated.uri = uriPowers as string
      console.log("@fetchPowersData, waypoint 2", {powersPopulated})
      return powersPopulated

    } catch (error) {
      console.log("@fetchPowersData, waypoint 3", {error})
      setStatus("error") 
      setError(error as Error)
    }
  }

  const fetchMetaData = async (powers: Powers): Promise<Powers | undefined> => {
    let updatedMetaData: Metadata | undefined
    let powersUpdated: Powers | undefined

    // console.log("@fetchMetaData, waypoint 0", {powers})

    if (powers && powers.uri) {
      // console.log("@fetchMetaData, waypoint 1")
      try {
        if (powers.uri) {
          const fetchedMetadata: unknown = await(
            await fetch(powers.uri as string)
            ).json() 
          updatedMetaData = parseMetadata(fetchedMetadata) 
        } 
        // console.log("@fetchMetaData, waypoint 2", {updatedMetaData})
        if (updatedMetaData) {
          powersUpdated = { ...powers, 
            metadatas: updatedMetaData
          }
          // console.log("@fetchMetaData, waypoint 3", {powersUpdated})
          setPowers(powersUpdated)
          powersUpdated && savePowers(powersUpdated)
          return powersUpdated
        }
      } catch (error) {
        // console.log("@fetchMetaData, waypoint 4", {error})
        setStatus("error") 
        setError(error as Error)
      }
    }
  }

  const checkLaws = async (lawIds: bigint[]) => {
    // console.log("@checkLaws, waypoint 0", {lawIds})
    const fetchedLaws: Law[] = []

    setStatus("pending")

    if (wagmiConfig && lawIds.length > 0 && address) {
        try {
          // Batch fetch all laws via multicall
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
          setStatus("error")
          setError(error as Error)
        }
    }
  }

  const populateLaws = async (laws: Law[]) => {
    let law: Law
    const populatedLaws: Law[] = []

    try {
      // Build a single multicall for all missing fields across all laws
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
      setStatus("error") 
      setError(error as Error)
    }
  }

  const calculateRoles = (laws: Law[]): Role[] | undefined => {
    try {
      const ActiveLaws = laws.filter((law: Law) => law.active)
      // console.log("@calculateRoles, waypoint 0", {ActiveLaws})
      const rolesAll = ActiveLaws
        .map((law: Law) => law.conditions?.allowedRole)
        .filter((roleId): roleId is bigint => typeof roleId === "bigint");
      // console.log("@calculateRoles, waypoint 1", {rolesAll})
      const roles: Role[] = [...new Set(rolesAll)].map((roleId) => ({ roleId, label: "" }));
      // console.log("@calculateRoles, waypoint 2", {roles})
      return roles;
    } catch (error) {
      setStatus("error") 
      setError(error as Error)
    }
  }

  const fetchRoles = async (powers: Powers): Promise<Role[] | undefined> => {
    const rolesIds = new Set(powers.laws?.filter((law) => law.active).flatMap((law) => law.conditions?.allowedRole) || [])
    // console.log("@fetchRoles, waypoint 0", {rolesIds})
    let updatedRoleLabels: Role[] = []

    if (rolesIds.size > 0) {
    try {
      // Build a multicall to fetch labels and holder counts for all roles
      const contracts = Array.from(rolesIds).flatMap((roleId) => ([
        {
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getRoleLabel' as const,
          args: [roleId] as [bigint],
          chainId: parseChainId(chainId)
        },
        {
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
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
      const powersUpdated: Powers = { ...powers, 
        roles: updatedRoleLabels
      }
      // console.log("@fetchRoles, waypoint 3", {powersUpdated})
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      return updatedRoleLabels
    } catch (error) {
        setStatus("error")
        setError(error as Error)
      }
    }
  }

  const fetchLaws = async (powers: Powers) => {
    // console.log("@fetchLawsAndRoles, waypoint 0", {powers})

    setStatus("pending")
    let laws: Law[] | undefined = undefined
    let lawsPopulated: Law[] | undefined = undefined
    let powersUpdated: Powers | undefined = undefined
    let lawIds: bigint[] | undefined = undefined

    try {
      const lawCount = await readContract(wagmiConfig, {
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
        functionName: 'lawCounter',
        chainId: parseChainId(chainId)
      })
      // console.log("@fetchLaws, waypoint 0", {lawCount})
      if (lawCount) {
        lawIds = Array.from({length: Number(lawCount) - 1}, (_, i) => BigInt(i+1))
      } else {
        setStatus("error")
        setError("Failed to fetch law count")
        return powers
      }
      console.log("@fetchLaws, waypoint 1", {lawIds})
      laws = await checkLaws(lawIds)
      console.log("@fetchLaws, waypoint 2", {laws})
      if (laws) { lawsPopulated = await populateLaws(laws) }
      console.log("@fetchLaws, waypoint 3", {lawsPopulated})

    } catch (error) {
      console.log("@fetchLaws, waypoint 6", {error})
      setStatus("error")
      setError(error as Error)
    }
    console.log("@fetchLaws, waypoint 7", {laws, error})
    if (laws) {
      // console.log("@fetchLaws, waypoint 8")
      powersUpdated = { ...powers, 
        laws: lawsPopulated, 
      }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      return powersUpdated
    } else {
      setStatus("error")
      setError("Failed to fetch laws")
      return powers
    }
  }

  const populateActions = async(actionIds: string[], powers: Powers): Promise<Action[]> => {
    if (actionIds.length === 0) {
      return []
    }

    // Fetch all data in parallel using readContracts
    const [stateResults, dataResults, calldataResults, uriResults] = await Promise.all([
      // Fetch getActionState
      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getActionState' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<number>>,

      // Fetch getActionData
      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
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

      // Fetch getActionCalldata
      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getActionCalldata' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<`0x${string}`>>,

      // Fetch getActionUri
      readContracts(wagmiConfig, {
        allowFailure: false,
        contracts: actionIds.map((actionId) => ({
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getActionUri' as const,
          args: [BigInt(actionId)],
          chainId: parseChainId(chainId)
        }))
      }) as Promise<Array<string>>
    ])

    // Construct Action objects
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
  const fetchActions = async (powers: Powers): Promise<Map<string, { lawId: bigint, index: number }>> => {
    const laws = powers.laws || []
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
        address: powers.contractAddress as `0x${string}`,
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
      return new Map()
    }

    // Step 4: Fetch actionIds for non-stale actions
    const actionIds = await readContracts(wagmiConfig, {
      allowFailure: false,
      contracts: fetchRequests.map((req) => ({
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
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
    const populatedActions = await populateActions(actionIdsArray, powers)

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

    // Step 9: Update and save powers
    const updatedPowers = { ...powers, laws: updatedLaws }
    setPowers(updatedPowers)
    savePowers(updatedPowers)

    return actionIdMapping
  }

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      // console.log("@fetchPowers, waypoint 0", {address})
      setStatus("pending")
      let powersToBeUpdated: Powers | undefined = undefined
      const localStore = localStorage.getItem("powersProtocols")
      // console.log("@fetchPowers, waypoint 1", {localStore})

      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress == address)
      // console.log("@fetchPowers, waypoint 2", {existing})

      if (existing) { 
        // Load cached data first
        powersToBeUpdated = existing
        setPowers(powersToBeUpdated)
        // console.log("@fetchPowers, waypoint 3", {powersToBeUpdated})

        // Then fetch metadata to ensure it's up to date
        if (powersToBeUpdated.uri) {
          try {
            const updatedMetadata = await fetchMetaData(powersToBeUpdated)
            if (updatedMetadata) {
              // console.log("@fetchPowers, waypoint 4", {updatedMetadata})
              powersToBeUpdated = updatedMetadata
              setPowers(powersToBeUpdated)
              // console.log("@fetchPowers, waypoint 5", {powersToBeUpdated})
            }
          } catch (error) {
            console.error("Error fetching metadata for cached protocol:", error)
          }
        }
        setStatus("success")
        // console.log("@fetchPowers, waypoint 6", {powersToBeUpdated})  
      } else {
        // console.log("@fetchPowers, waypoint 7", {address})
        refetchPowers(address)
        setStatus("success")
      }      
    }, [powers?.contractAddress]
  )
  
  const refetchPowers = useCallback(
    async (address: `0x${string}`) => {
      // console.log("@refetchPowers, waypoint 0", {address})
      setStatus("pending")

      let powersToBeUpdated: Powers | undefined
      let data: Powers | undefined
      let metaData: Powers | undefined
      let laws: Powers | undefined
      let roles: Role[] | undefined

      powersToBeUpdated = { contractAddress: address, chainId: BigInt(chainId) }
      // console.log("@refetchPowers, waypoint 1", {powersToBeUpdated})

      try {
        data = await fetchPowersData(powersToBeUpdated)
        // console.log("@refetchPowers, waypoint 2", {data})

        if (data) {
          [metaData, laws, roles] = await Promise.all([
            fetchMetaData(data),
            fetchLaws(data), 
            fetchRoles(data)
          ])
          // console.log("@refetchPowers, waypoint 3", {metaData, laws})
        }
        // console.log("@refetchPowers, waypoint 4", {metaData, laws})

        if (data != undefined && metaData != undefined && laws != undefined) {
          // console.log("@refetchPowers, waypoint 7", {data, metaData, laws, actions})
          const newPowers: Powers = {
            contractAddress: powersToBeUpdated.contractAddress as `0x${string}`,
            chainId: BigInt(chainId),
            name: data.name,
            metadatas: metaData.metadatas,
            uri: data.uri,
            lawCount: data.lawCount,
            laws: laws.laws,
            roles: roles,
            layout: powersToBeUpdated.layout
          }
          // console.log("@refetchPowers, waypoint 8", {newPowers})
          setPowers(newPowers)
          savePowers(newPowers)
        }
      } catch (error) {
         console.error("@fetchPowers error:", error)
        setStatus("error")
        setError(error as Error)
      } finally {
        setStatus("success")
      }
    }, [ ] 
  )

  return {status, error, powers, fetchPowers, refetchPowers, fetchLaws, fetchRoles, fetchActions, checkLaws}  
}
