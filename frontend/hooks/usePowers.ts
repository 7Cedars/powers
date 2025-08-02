import { Status, Action, Powers, Law, Metadata, RoleLabel, Conditions, LawExecutions, BlockRange, Role, PowersExecutions } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { GetBlockReturnType, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { getBlock, getPublicClient, readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { useParams } from "next/navigation";
import { useBlockNumber } from "wagmi";

export const usePowers = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [powers, setPowers] = useState<Powers | undefined>() 
  const { chainId, powers: address } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId), 
  })
  const {data: currentBlock} = useBlockNumber({
    chainId: parseChainId(chainId), 
  })
  // console.log("@usePowers, MAIN", {chainId, error, powers, publicClient, status})

  // function to save powers to local storage
  const savePowers = (powers: Powers) => {
    let localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
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
    let powersPopulated: Powers | undefined = powers
    try {
      const namePowers = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'name'
      })  

      const uriPowers = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'uri',
      })

      const lawCountPowers = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'lawCount',
      })

      if (namePowers && uriPowers && lawCountPowers) {
        powersPopulated.lawCount = lawCountPowers as bigint
        powersPopulated.name = namePowers as string
        powersPopulated.uri = uriPowers as string
      }
      return powersPopulated

    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const fetchMetaData = async (powers: Powers): Promise<Powers | undefined> => {
    let updatedMetaData: Metadata | undefined
    let powersUpdated: Powers | undefined

    // console.log("@fetchMetaData, waypoint 0", {powers})

    if (publicClient && powers && powers.uri) {
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
        setError(error)
      }
    }
  }

  const checkSingleLaw = async (powers: Powers, lawId: bigint) => {
    // console.log("@checkSingleLaw, waypoint 0", {lawId})
    let fetchedLaw: Law | undefined = undefined
    let laws: Law[] = powers.laws || []
    setStatus("pending")

    if (publicClient && lawId && address) {
      try {
        const lawFetched = await publicClient.readContract({ 
          abi: powersAbi,
          address: address as `0x${string}`,
          functionName: 'getActiveLaw',
          args: [BigInt(lawId)]
        })
        // console.log("@checkSingleLaw, waypoint 1", {lawFetched})
        const lawFetchedTyped = lawFetched as [`0x${string}`, `0x${string}`, boolean]

        fetchedLaw = {
          powers: address,
          lawAddress: lawFetchedTyped[0] as unknown as `0x${string}`,
          lawHash: lawFetchedTyped[1] as unknown as `0x${string}`,
          index: lawId,
          active: lawFetchedTyped[2] as unknown as boolean
        }
        // console.log("@checkSingleLaw, waypoint 2", {fetchedLaw})
      } catch (error) {
        setStatus("error")
        setError(error)
      }
      laws = laws.map((law: Law) => {        
        if (fetchedLaw?.index == law.index) {
          return {
            ...law,
            lawAddress: fetchedLaw.lawAddress,
            lawHash: fetchedLaw.lawHash,
            index: fetchedLaw.index,
            active: fetchedLaw.active
          }
        } else {
          return law
        }
      })
      // console.log("@checkSingleLaw, waypoint 3", {laws})
      const powersUpdated = { ...powers, 
        laws: laws,
        activeLaws: laws.filter((law: Law) => law.active)
      }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      }
  }

  const checkLaws = async (lawIds: bigint[]) => {
    // console.log("@checkLaws, waypoint 0", {lawIds})
    let lawId: bigint
    let fetchedLaws: Law[] = []

    setStatus("pending")

    if (publicClient && lawIds.length > 0 && address) {
        // fetching all laws ever initiated by the org
        for (lawId of lawIds) {
          // console.log("@checkLaws, waypoint 1", {lawId})
          try { 
            const lawFetched = await publicClient.readContract({ 
              abi: powersAbi,
              address: address as `0x${string}`,
              functionName: 'getActiveLaw',
              args: [BigInt(lawId)]
            })
                // console.log("@checkLaws, waypoint 2", {lawFetched})
            const lawFetchedTyped = lawFetched as [`0x${string}`, `0x${string}`, boolean]
            fetchedLaws.push({
              powers: address,
              lawAddress: lawFetchedTyped[0] as unknown as `0x${string}`,
              lawHash: lawFetchedTyped[1] as unknown as `0x${string}`,
              index: lawId,
              active: lawFetchedTyped[2] as unknown as boolean
            })
            // console.log("@checkLaws, waypoint 3", {error})
          } catch (error) {
            // console.log("@checkLaws, waypoint 3", {error})
            setStatus("error")
            setError(error)
          }
        }
        return fetchedLaws
    }
  }

  const populateLaws = async (laws: Law[]) => {
    let law: Law
    const populatedLaws: Law[] = []

    try {
      for (law of laws) {
        if (!law.conditions && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawConditions = await publicClient.readContract({
            abi: lawAbi, 
            address: law.lawAddress as `0x${string}`,
            functionName: 'getConditions',
            args: [law.powers, law.index]
          })
          law.conditions = lawConditions as Conditions
        }

        if (!law.inputParams && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawInputParams = await publicClient.readContract({
            abi: lawAbi, 
            address: law.lawAddress as `0x${string}`,
            functionName: 'getInputParams',
            args: [law.powers, law.index]
          })
          law.inputParams = lawInputParams as `0x${string}`
          law.params = bytesToParams(law.inputParams)
        }

        if (!law.nameDescription && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const nameDescription = await publicClient.readContract({
            abi: lawAbi, 
            address: law.lawAddress as `0x${string}`,
            functionName: 'getNameDescription',
            args: [law.powers, law.index]
          })
          law.nameDescription = nameDescription as string
        }
        populatedLaws.push(law)
      }
      return populatedLaws
    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const calculateRoles = (laws: Law[]): bigint[] | undefined => {
    try {
      const activeLaws = laws.filter((law: Law) => law.active)
      // console.log("@calculateRoles, waypoint 0", {activeLaws})
      const rolesAll = activeLaws.map((law: Law) => law.conditions?.allowedRole)
      // console.log("@calculateRoles, waypoint 1", {rolesAll})
      const roles = [... new Set(rolesAll)] as bigint[]
      // console.log("@calculateRoles, waypoint 2", {roles})
      return roles
    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const updateRoleLabels = async (roles: bigint[], powers: Powers): Promise<RoleLabel[] | undefined> => {
    let role: bigint
    let updatedRoleLabels: RoleLabel[] = []

    if (roles.length > 0) {
    try {
      for (role of roles) {
        const [roleLabel, roleHolders] = await Promise.all([
          readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getRoleLabel',
            args: [role]
          }),
          readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getAmountRoleHolders',
            args: [role]
          })
        ])
        updatedRoleLabels = [...updatedRoleLabels, {roleId: role, label: roleLabel as string, holders: roleHolders as bigint }]
      }
      return updatedRoleLabels
    } catch (error) {
        setStatus("error")
        setError(error)
      }
    }
  }

  const fetchLawsAndRoles = async (powers: Powers) => {
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
        functionName: 'lawCount'
      })
      // console.log("@fetchLawsAndRoles, waypoint 0", {lawCount})
      if (lawCount) {
        lawIds = Array.from({length: Number(lawCount) - 1}, (_, i) => BigInt(i+1))
      } else {
        setStatus("error")
        setError("Failed to fetch law count")
        return powers
      }
      laws = await checkLaws(lawIds)
      if (laws) { lawsPopulated = await populateLaws(laws) }
      if (lawsPopulated) { roles = calculateRoles(lawsPopulated) } 
      if (roles) { roleLabels = await updateRoleLabels(roles, powers) }  
    } catch (error) {
      setStatus("error")
      setError(error)
    }
    // console.log("@fetchLawsAndRoles, waypoint 0", {laws, roles, roleLabels, error})
    if (laws && roles && roleLabels) {
      // console.log("@fetchLawsAndRoles, waypoint 1")
      powersUpdated = { ...powers, 
        laws: laws, 
        activeLaws: laws.filter((law: Law) => law.active),
        roles: roles, 
        roleLabels: roleLabels
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
  
  const fetchProposals = async (powers: Powers | undefined, maxRuns: bigint, chunkSize: bigint) => {
    let powersUpdated: Powers | undefined;
    // console.log("@fetchProposals, waypoint 0", {powers, currentBlock, maxRuns, chunkSize})

    if (!publicClient || !currentBlock || !powers) {
      setStatus("error")
      setError("No public client, current block, or powers data")
      return powers
    } else {
      // Initialize arrays to collect results
      let proposalsFetched: Action[] = powers?.proposals || []; // Start with existing proposals
     
      let distance = powers?.proposalsBlocksFetched ? BigInt(Number(currentBlock) - Number(powers?.proposalsBlocksFetched?.to)) : BigInt(Number(chunkSize) * Number(maxRuns))
      if (distance > BigInt(Number(chunkSize) * Number(maxRuns)) ) {
        distance = BigInt(Number(chunkSize) * Number(maxRuns))
      }
      const blockFrom = currentBlock - distance
      // console.log("@fetchProposals, waypoint 1", {blockFrom, distance, currentBlock})

      // Fetch blocks in chunks with pagination
      let chunkFrom: bigint = 0n
      let chunkTo: bigint = 0n
      // console.log("@fetchProposals, waypoint 2", {chunkFrom, chunkTo})
  
      // check if we reached the end of the distance or max runs
      // if so, save here everything to disc.  
      let i = 0
      while (i < Number(distance)) {
        // console.log("@fetchProposals, waypoint 3", {chunkTo, i, distance})
      
        // calculate chunk boundaries
        chunkFrom = BigInt(Number(blockFrom) + i)
        chunkTo = (Number(chunkFrom) + Number(chunkSize)) > Number(currentBlock) ? currentBlock : BigInt(Number(chunkFrom) + Number(chunkSize))
        // console.log("@fetchProposals, waypoint 3.1", {chunkFrom, chunkTo, currentBlock})
        
        try { 
          // Fetch events for the current chunk
          const logs = await publicClient.getContractEvents({ 
            address: powers?.contractAddress as `0x${string}`,
            abi: powersAbi, 
            eventName: 'ProposedActionCreated',
            fromBlock: chunkFrom,
            toBlock: chunkTo
          })
          // console.log("@fetchProposals, waypoint 4", {logs, publicClient})          
          const fetchedLogs = parseEventLogs({
            abi: powersAbi,
            eventName: 'ProposedActionCreated',
            logs
          });
          // console.log("@fetchProposals, waypoint 5", {fetchedLogs})
          let newProposals: Action[] = (fetchedLogs as ParseEventLogsReturnType).map(log => log.args as Action);
          // but with typing of nonce and actionId as string
          newProposals = newProposals.map(proposal => { 
            return {
              ...proposal,
              actionId: String(proposal.actionId),
              nonce: String(proposal.nonce)
            }
          })
          // console.log("@fetchProposals, waypoint 6", {newProposals})
          // Append new proposals to the accumulated array
          proposalsFetched = [...proposalsFetched, ...newProposals]
          } catch (error) {
            setStatus("error")
            setError(error)
            return powers
          }
          i = i + Number(chunkSize)
        }
        
        // Remove duplicates based on actionId and nonce
        const uniqueProposals = proposalsFetched.filter((proposal, index, self) => 
          index === self.findIndex(p => p.actionId === proposal.actionId && p.nonce === proposal.nonce)
        )
        // console.log("@fetchProposals, waypoint 7", {uniqueProposals})
        // const sortedProposals = uniqueProposals.sort((a: Action, b: Action) => a.voteStart && b.voteStart ? a.voteStart > b.voteStart ? -1 : 1 : 0);
        // console.log("@fetchProposals, waypoint 8", {sortedProposals})
        
          powersUpdated = { ...powers as Powers, 
            proposals: uniqueProposals, // Use deduplicated proposals
            proposalsBlocksFetched: { 
              from: powers?.proposalsBlocksFetched?.from ? 
                powers?.proposalsBlocksFetched.from : // note: from is only saved once, and is never updated.  
                blockFrom, 
              to: chunkTo 
            }
          }
          // console.log("@fetchProposals, waypoint 9", {powersUpdated})
          setPowers(powersUpdated)
          savePowers(powersUpdated)
          return powersUpdated
      }
      // return powers
  }
  
  const fetchExecutedActions = async (powers: Powers) => {
    setStatus("pending")
    let powersUpdated: Powers | undefined;
    let law: Law
    let laws = powers.laws || []
    let executedActions: LawExecutions[] = []

    try {
      for (law of laws) {
        // console.log("@fetchExecutedActions, waypoint 0", {law})

        const executedActionsFetched = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.lawAddress as `0x${string}`,
          functionName: 'getExecutions',
          args: [law.powers, law.index]
        })
        // console.log("@fetchExecutedActions, waypoint 1", {executedActionsFetched})
        executedActions.push(executedActionsFetched as unknown as LawExecutions)
      }
      // console.log("@fetchExecutedActions, waypoint 2", {executedActions, error})
      powersUpdated = { ...powers, executedActions: executedActions }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
      return powersUpdated
      } catch (error) {
        setStatus("error")
        setError(error)
        return powers
      }
  }

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      setStatus("pending")
      let powersToBeUpdated: Powers | undefined = undefined
      let localStore = localStorage.getItem("powersProtocols")

      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress == address)

      if (existing) { 
        // Load cached data first
        powersToBeUpdated = existing
        setPowers(powersToBeUpdated)
        
        // Then fetch metadata to ensure it's up to date
        if (powersToBeUpdated.uri) {
          try {
            const updatedMetadata = await fetchMetaData(powersToBeUpdated)
            if (updatedMetadata) {
              powersToBeUpdated = updatedMetadata
              setPowers(powersToBeUpdated)
            }
          } catch (error) {
            console.error("Error fetching metadata for cached protocol:", error)
          }
        }
        setStatus("success")
      } else {
        refetchPowers(address)
        setStatus("success")
      }      
    }, [powers?.contractAddress]
  )
  
  const refetchPowers = useCallback(
    async (address: `0x${string}`) => {
      setStatus("pending")

      let powersToBeUpdated: Powers | undefined
      let data: Powers | undefined
      let metaData: Powers | undefined
      let laws: Powers | undefined
      let executedActions: Powers | undefined
      let proposals: Powers | undefined

      powersToBeUpdated = { contractAddress: address }

      try {
        [data, proposals] = await Promise.all([
          fetchPowersData(powersToBeUpdated),
          fetchProposals(powersToBeUpdated, 10n, 10000n),
        ])

        // console.log("@refetchPowers, waypoint 0.1", {data, proposals})

        if (data) {
          [metaData, laws] = await Promise.all([
            fetchMetaData(data),
            fetchLawsAndRoles(data)
          ])
        }
        // console.log("@refetchPowers, waypoint 0.2", {metaData, laws})
        if (laws) {
          executedActions = await fetchExecutedActions(laws)
        }

        if (data != undefined && metaData != undefined && laws != undefined && executedActions != undefined && proposals != undefined) {
          // console.log("@fetchPowers, waypoint 0", {data, metaData, laws, executedActions, proposals})
          const newPowers: Powers = {
            contractAddress: powersToBeUpdated.contractAddress as `0x${string}`,
            name: data.name,
            metadatas: metaData.metadatas,
            uri: data.uri,
            lawCount: data.lawCount,
            laws: laws.laws,
            activeLaws: laws.activeLaws,
            proposals: proposals.proposals,
            executedActions: executedActions.executedActions,
            roles: laws.roles,
            roleLabels: laws.roleLabels,
            deselectedRoles: laws.deselectedRoles,
            layout: powersToBeUpdated.layout
          }
          setPowers(newPowers)
          savePowers(newPowers)
        }
      } catch (error) {
        //  console.error("@fetchPowers error:", error)
        setStatus("error")
        setError(error)
      } finally {
        setStatus("success")
      }
    }, [ ] 
  )

  return {status, error, powers, fetchPowers, refetchPowers, fetchLawsAndRoles, fetchProposals, fetchExecutedActions, checkLaws, checkSingleLaw}  
}
