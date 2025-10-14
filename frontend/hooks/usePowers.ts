import { Status, Action, Powers, Law, Metadata, RoleLabel, Conditions } from "../context/types"
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

    console.log("@fetchMetaData, waypoint 0", {powers})

    if (powers && powers.uri) {
      console.log("@fetchMetaData, waypoint 1")
      try {
        if (powers.uri) {
          const fetchedMetadata: unknown = await(
            await fetch(powers.uri as string)
            ).json() 
          updatedMetaData = parseMetadata(fetchedMetadata) 
        } 
        console.log("@fetchMetaData, waypoint 2", {updatedMetaData})
        if (updatedMetaData) {
          powersUpdated = { ...powers, 
            metadatas: updatedMetaData
          }
          console.log("@fetchMetaData, waypoint 3", {powersUpdated})
          setPowers(powersUpdated)
          powersUpdated && savePowers(powersUpdated)
          return powersUpdated
        }
      } catch (error) {
        console.log("@fetchMetaData, waypoint 4", {error})
        setStatus("error") 
        setError(error as Error)
      }
    }
  }

  const checkLaws = async (lawIds: bigint[]) => {
    console.log("@checkLaws, waypoint 0", {lawIds})
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

  const calculateRoles = (laws: Law[]): bigint[] | undefined => {
    try {
      const ActiveLaws = laws.filter((law: Law) => law.active)
      // console.log("@calculateRoles, waypoint 0", {ActiveLaws})
      const rolesAll = ActiveLaws.map((law: Law) => law.conditions?.allowedRole)
      // console.log("@calculateRoles, waypoint 1", {rolesAll})
      const roles = [... new Set(rolesAll)] as bigint[]
      // console.log("@calculateRoles, waypoint 2", {roles})
      return roles
    } catch (error) {
      setStatus("error") 
      setError(error as Error)
    }
  }

  const updateRoleLabels = async (roles: bigint[], powers: Powers): Promise<RoleLabel[] | undefined> => {
    let role: bigint
    let updatedRoleLabels: RoleLabel[] = []

    if (roles.length > 0) {
    try {
      // Build a multicall to fetch labels and holder counts for all roles
      const contracts = roles.flatMap((r) => ([
        {
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getRoleLabel' as const,
          args: [r] as [bigint],
          chainId: parseChainId(chainId)
        },
        {
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getAmountRoleHolders' as const,
          args: [r] as [bigint],
          chainId: parseChainId(chainId)
        }
      ]))

      const results = await readContracts(wagmiConfig, {
        allowFailure: false,
        contracts
      })

      // results are in pairs [label, holders] per role in same order
      for (let i = 0; i < roles.length; i++) {
        const label = results[i * 2] as string
        const holders = results[i * 2 + 1] as bigint
        updatedRoleLabels.push({ roleId: roles[i], label, holders })
      }
      return updatedRoleLabels
    } catch (error) {
        setStatus("error")
        setError(error as Error)
      }
    }
  }

  const fetchLawsAndRoles = async (powers: Powers) => {
    console.log("@fetchLawsAndRoles, waypoint 0", {powers})

    setStatus("pending")
    let laws: Law[] | undefined = undefined
    let lawsPopulated: Law[] | undefined = undefined
    let roles: bigint[] | undefined = undefined
    let roleLabels: RoleLabel[] | undefined = undefined
    let powersUpdated: Powers | undefined = undefined
    let lawIds: bigint[] | undefined = undefined

    try {
      const lawCount = await readContract(wagmiConfig, {
        abi: powersAbi,
        address: powers.contractAddress as `0x${string}`,
        functionName: 'lawCounter',
        chainId: parseChainId(chainId)
      })
      // console.log("@fetchLawsAndRoles, waypoint 0", {lawCount})
      if (lawCount) {
        lawIds = Array.from({length: Number(lawCount) - 1}, (_, i) => BigInt(i+1))
      } else {
        setStatus("error")
        setError("Failed to fetch law count")
        return powers
      }
      // console.log("@fetchLawsAndRoles, waypoint 1", {lawIds})
      laws = await checkLaws(lawIds)
      // console.log("@fetchLawsAndRoles, waypoint 2", {laws})
      if (laws) { lawsPopulated = await populateLaws(laws) }
      // console.log("@fetchLawsAndRoles, waypoint 3", {lawsPopulated})
      if (lawsPopulated) { roles = calculateRoles(lawsPopulated) } 
      // console.log("@fetchLawsAndRoles, waypoint 4", {roles})
      if (roles) { roleLabels = await updateRoleLabels(roles, powers) }  
      // console.log("@fetchLawsAndRoles, waypoint 5", {roleLabels})
    } catch (error) {
      // console.log("@fetchLawsAndRoles, waypoint 6", {error})
      setStatus("error")
      setError(error as Error)
    }
    // console.log("@fetchLawsAndRoles, waypoint 7", {laws, roles, roleLabels, error})
    if (laws && roles && roleLabels) {
      // console.log("@fetchLawsAndRoles, waypoint 8")
      powersUpdated = { ...powers, 
        laws, 
        roles, 
        roleLabels
      }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      return powersUpdated
    } else {
      setStatus("error")
      setError("Failed to fetch laws and roles")
      return powers
    }
  }
  
  // Note: it ONLY fetch the action data on status of the action. Calldata, vote data is not fetched.
  const fetchActions = async (powers: Powers) => {
    setStatus("pending")
    let powersUpdated: Powers | undefined;
    const laws = powers.laws || []
    const activeLaws = laws.filter((law) => law.active)

    console.log("@fetchActions, waypoint 0", { totalLaws: laws.length, activeLaws: activeLaws.length })

    try {
      // Step 1 & 2: Per law, fetch saved actions and identify stale actions with their indices
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
          console.log(`@fetchActions, law ${law.index}: ${staleIndices.size} stale actions at indices:`, Array.from(staleIndices))
        }
      })

      // Step 3: Fetch getQuantityLawActions for each active law
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

      console.log("@fetchActions, waypoint 1", { actionQuantities })

      // Step 4: Create list of indices to fetch per law (excluding stale actions)
      type FetchRequest = {
        lawId: bigint
        lawIndex: number
        actionIndex: number
      }
      
      const fetchRequests: FetchRequest[] = []
      
      actionQuantities.forEach((quantity, lawIndex) => {
        const law = activeLaws[lawIndex]
        const lawId = law.index
        const staleIndices = staleActionsByLaw.get(lawId.toString()) || new Set()
        
        // Create array from 0 to quantity - 1, excluding stale indices
        for (let i = 0; i < Number(quantity); i++) {
          if (!staleIndices.has(i)) {
            fetchRequests.push({
              lawId,
              lawIndex,
              actionIndex: i
            })
          }
        }
      })

      console.log("@fetchActions, waypoint 2", { totalFetchRequests: fetchRequests.length })

      // Early exit if no actions to fetch
      if (fetchRequests.length === 0) {
        setStatus("success")
        return powers
      }

      // Step 5: Combine into one large array for readContracts
      // Note that this code is super inefficient. - AI created. TODO: Optimize.
      const [actionIdResults, actionDataResults, actionStateResults] = await Promise.all([
        // Fetch actionIds
        readContracts(wagmiConfig, {
          allowFailure: false,
          contracts: fetchRequests.map((req) => ({
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getLawActionAtIndex' as const,
            args: [req.lawId, BigInt(req.actionIndex)],
            chainId: parseChainId(chainId)
          }))
        }) as Promise<Array<bigint>>,
        
        // Fetch actionData (will use actionIds from first call)
        readContracts(wagmiConfig, {
          allowFailure: false,
          contracts: fetchRequests.map((req) => ({
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getLawActionAtIndex' as const,
            args: [req.lawId, BigInt(req.actionIndex)],
            chainId: parseChainId(chainId)
          }))
        }).then(async (actionIds) => {
          return readContracts(wagmiConfig, {
            allowFailure: false,
            contracts: (actionIds as Array<bigint>).map((aid) => ({
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionData' as const,
              args: [aid],
              chainId: parseChainId(chainId)
            }))
          }) as Promise<Array<[
            number,
            bigint,
            bigint,
            bigint,
            bigint,
            `0x${string}`,
            bigint
          ]>>
        }),
        
        // Fetch actionState
        readContracts(wagmiConfig, {
          allowFailure: false,
          contracts: fetchRequests.map((req) => ({
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getLawActionAtIndex' as const,
            args: [req.lawId, BigInt(req.actionIndex)],
            chainId: parseChainId(chainId)
          }))
        }).then(async (actionIds) => {
          return readContracts(wagmiConfig, {
            allowFailure: false,
            contracts: (actionIds as Array<bigint>).map((aid) => ({
              abi: powersAbi,
              address: powers.contractAddress as `0x${string}`,
              functionName: 'getActionState' as const,
              args: [aid],
              chainId: parseChainId(chainId)
            }))
          }) as Promise<Array<number>>
        })
      ])

      console.log("@fetchActions, waypoint 3", { actionIdResults, actionDataResults, actionStateResults })

      // Step 6: Recreate proper action objects
      const fetchedActionsByLaw = new Map<string, Action[]>()
      
      fetchRequests.forEach((req, idx) => {
        const actionId = actionIdResults[idx]
        const tuple = actionDataResults[idx]
        const state = actionStateResults[idx]
        
        const action: Action = {
          actionId: String(actionId),
          lawId: req.lawId,
          caller: tuple[5],
          nonce: String(tuple[6]),
          proposedAt: tuple[1],
          requestedAt: tuple[2],
          fulfilledAt: tuple[3],
          cancelledAt: tuple[4],
          state: state
        }
        
        const lawKey = req.lawId.toString()
        if (!fetchedActionsByLaw.has(lawKey)) {
          fetchedActionsByLaw.set(lawKey, [])
        }
        fetchedActionsByLaw.get(lawKey)!.push({ ...action, index: req.actionIndex } as any)
      })

      console.log("@fetchActions, waypoint 4", { fetchedActionsByLaw })

      // Step 7: Merge arrays of actions per law, correctly along their indices
      const updatedLaws = activeLaws.map((law, lawIndex) => {
        const quantity = Number(actionQuantities[lawIndex])
        const savedActions = law.actions || []
        const fetchedActions = fetchedActionsByLaw.get(law.index.toString()) || []
        
        // Create array with correct length, filling in stale and fetched actions by index
        const mergedActions: Action[] = new Array(quantity)
        
        // First, place stale actions at their indices
        savedActions.forEach((action, index) => {
          if (action.state === 2 || action.state === 4 || action.state === 7) {
            mergedActions[index] = action
          }
        })
        
        // Then, place fetched actions at their indices
        fetchedActions.forEach((actionWithIndex: any) => {
          const { index, ...action } = actionWithIndex
          mergedActions[index] = action
        })
        
        // Filter out any undefined entries (shouldn't happen, but just in case)
        const finalActions = mergedActions.filter(a => a !== undefined)
        
        console.log(`@fetchActions, law ${law.index}: merged ${finalActions.length} actions`)
        
        return {
          ...law,
          actions: finalActions
        }
      })

      // Also include inactive laws unchanged
      const inactiveLaws = laws.filter((law) => !law.active)
      const allUpdatedLaws = [...updatedLaws, ...inactiveLaws]

      console.log("@fetchActions, waypoint 5", { updatedLaws: allUpdatedLaws.length })

      // Step 8: Update and save powers
      powersUpdated = { ...powers, laws: allUpdatedLaws }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      return powersUpdated
    } catch (error) {
      console.log("@fetchActions, error", error)
      setStatus("error")
      setError(error as Error)
      return powers
    }
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
      let actions: Powers | undefined

      powersToBeUpdated = { contractAddress: address, chainId: BigInt(chainId) }
      // console.log("@refetchPowers, waypoint 1", {powersToBeUpdated})

      try {
        data = await fetchPowersData(powersToBeUpdated)
        // console.log("@refetchPowers, waypoint 2", {data})

        if (data) {
          [metaData, laws] = await Promise.all([
            fetchMetaData(data),
            fetchLawsAndRoles(data)
          ])
          // console.log("@refetchPowers, waypoint 3", {metaData, laws})
        }
        // console.log("@refetchPowers, waypoint 4", {metaData, laws})
        if (laws) { actions = await fetchActions(laws) }
          // console.log("@refetchPowers, waypoint 5", {actions})
         

        if (data != undefined && metaData != undefined && laws != undefined && actions != undefined) {
          // console.log("@refetchPowers, waypoint 7", {data, metaData, laws, actions})
          const newPowers: Powers = {
            contractAddress: powersToBeUpdated.contractAddress as `0x${string}`,
            chainId: BigInt(chainId),
            name: data.name,
            metadatas: metaData.metadatas,
            uri: data.uri,
            lawCount: data.lawCount,
            laws: laws.laws,
            roles: laws.roles,
            roleLabels: laws.roleLabels,
            deselectedRoles: laws.deselectedRoles,
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

  return {status, error, powers, fetchPowers, refetchPowers, fetchLawsAndRoles, fetchActions, checkLaws}  
}
