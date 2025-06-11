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
    let updatedMetaData: Metadata | undefined = powers.metadatas
    let powersUpdated: Powers | undefined = undefined

    if (publicClient && powers && powers.uri && !updatedMetaData) {
      try {
        if (powers.uri) {
          const fetchedMetadata: unknown = await(
            await fetch(powers.uri as string)
            ).json() 
          updatedMetaData = parseMetadata(fetchedMetadata) 
        } 
        if (updatedMetaData) {
          powersUpdated = { ...powers, 
            metadatas: updatedMetaData
          }
          setPowers(powersUpdated)
          powersUpdated && savePowers(powersUpdated)
          return powersUpdated
        }
      } catch (error) {
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

  const checkLaws = async (powers: Powers, lawIds: bigint[]) => {
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
            console.log("@checkLaws, waypoint 3", {fetchedLaws})  
          } catch (error) {
            console.log("@checkLaws, waypoint 3", {error})
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
      const rolesAll = activeLaws.map((law: Law) => law.conditions?.allowedRole)
      return [... new Set(rolesAll)] as bigint[]
    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const updateRoleLabels = async (roles: bigint[], powers: Powers): Promise<RoleLabel[] | undefined> => {
    let role: bigint
    const updatedRoleLabels: RoleLabel[] = []

    if (roles.length > 0) {
    try {
      for (role of roles) {
        const roleLabel = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: powers.contractAddress as `0x${string}`,
          functionName: 'getRoleLabel',
          args: [role]
        })
        updatedRoleLabels.push({roleId: role, label: roleLabel as string})
      }
      return updatedRoleLabels
    } catch (error) {
        setStatus("error")
        setError(error)
      }
    }
  }

  const fetchLawsAndRoles = async (powers: Powers) => {
    let laws: Law[] | undefined = undefined
    let lawsPopulated: Law[] | undefined = undefined
    let roles: bigint[] | undefined = undefined
    let roleLabels: RoleLabel[] | undefined = undefined
    let powersUpdated: Powers | undefined = undefined

    try {
      const lawIds: bigint[] = Array.from({length: Number(powers.lawCount) - 1}, (_, i) => BigInt(i+1))
      laws = await checkLaws(powers, lawIds)
      if (laws) { lawsPopulated = await populateLaws(laws) }
      if (lawsPopulated) { roles = calculateRoles(lawsPopulated) } 
      if (roles) { roleLabels = await updateRoleLabels(roles, powers) }  
    } catch (error) {
      setStatus("error")
      setError(error)
    }
    console.log("@fetchLawsAndRoles, waypoint 0", {laws, roles, roleLabels, error})
    if (laws && roles && roleLabels) {
      console.log("@fetchLawsAndRoles, waypoint 1")
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
    }
    return powers // Return original powers if update failed
  }
  
  const fetchProposals = async (powers: Powers | undefined, maxRuns: bigint, chunkSize: bigint) => {
    let powersUpdated: Powers | undefined;

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

      // Fetch blocks in chunks with pagination
      let chunkFrom: bigint = 0n
      let chunkTo: bigint = 0n
  
      // check if we reached the end of the distance or max runs
      // if so, save here everything to disc.  
      let i = 0
      while (distance > i) {
        // console.log("@fetchProposals, waypoint 1", {chunkTo, i, distance})
      
        // calculate chunk boundaries
        chunkFrom = blockFrom + BigInt(i * Number(chunkSize))
        chunkTo = (chunkFrom + chunkSize) > currentBlock ? currentBlock : (chunkFrom + chunkSize)
        
        try { 
          // Fetch events for the current chunk
          const logs = await publicClient.getContractEvents({ 
            address: powers?.contractAddress as `0x${string}`,
            abi: powersAbi, 
            eventName: 'ProposedActionCreated',
            fromBlock: chunkFrom,
            toBlock: chunkTo
          })
          
          const fetchedLogs = parseEventLogs({
            abi: powersAbi,
            eventName: 'ProposedActionCreated',
            logs
          });

          let newProposals: Action[] = (fetchedLogs as ParseEventLogsReturnType).map(log => log.args as Action);
          // but with typing of nonce and actionId as string
          newProposals = newProposals.map(proposal => { 
            return {
              ...proposal,
              actionId: String(proposal.actionId),
              nonce: String(proposal.nonce)
            }
          })
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
        
        // const sortedProposals = uniqueProposals.sort((a: Action, b: Action) => a.voteStart > b.voteStart ? -1 : 1);
        
          powersUpdated = { ...powers as Powers, 
            proposals: uniqueProposals, // Use deduplicated proposals
            proposalsBlocksFetched: { 
              from: powers?.proposalsBlocksFetched?.from ? 
                powers?.proposalsBlocksFetched.from : // note: from is only saved once, and is never updated.  
                blockFrom, 
              to: chunkTo 
            }
          }
          setPowers(powersUpdated)
          savePowers(powersUpdated)
          return powersUpdated
      }
      return powers
  }
  
  const fetchExecutedActions = async (powers: Powers) => {
    let powersUpdated: Powers | undefined;
    
    let law: Law
    let laws = powers.laws || []
    let executedActions: LawExecutions[] = []

    try {
      for (law of laws) {
        console.log("@fetchExecutedActions, waypoint 0", {law})

        const executedActionsFetched = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.lawAddress as `0x${string}`,
          functionName: 'getExecutions',
          args: [law.powers, law.index]
        })
        console.log("@fetchExecutedActions, waypoint 1", {executedActionsFetched})
        executedActions.push(executedActionsFetched as unknown as LawExecutions)
      }
      console.log("@fetchExecutedActions, waypoint 2", {executedActions, error})
      powersUpdated = { ...powers, executedActions: executedActions }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
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
      let updatedData: Powers | undefined = undefined
      let updatedMetaData: Powers | undefined = undefined
      let updatedLaws: Powers | undefined = undefined
      let updatedProposals: Powers | undefined = undefined
      let updatedExecutedActions: Powers | undefined = undefined
      let localStore = localStorage.getItem("powersProtocols")
      // console.log("@fetchPowers, waypoint 0", {localStore})
      
      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress == address)
      // console.log("@fetchPowers, waypoint 1", {existing})

      if (existing) { 
        powersToBeUpdated = existing 
      } else {
        powersToBeUpdated = { contractAddress: address }
      }
      // console.log("@fetchPowers, waypoint 2", {powersToBeUpdated})
      
      try {
        // Always fetch basic powers data (name, uri, lawCount)
      updatedData = await fetchPowersData(powersToBeUpdated)
      // console.log("@fetchPowers, waypoint 3", {updatedData})
        
        // Only fetch metadata if missing or URI changed
        if (updatedData && (!updatedData.metadatas || updatedData.uri !== powersToBeUpdated?.uri)) { 
        updatedMetaData = await fetchMetaData(updatedData) 
      } else {
        updatedMetaData = updatedData
      }
        console.log("@fetchPowers, waypoint 4", {updatedMetaData, error})
        
        // Only fetch laws if they need updating
        if (updatedMetaData && needsLawsUpdate(updatedMetaData)) { 
          console.log("@fetchPowers: Fetching laws (needed update)")
          updatedLaws = await fetchLawsAndRoles(updatedMetaData) 
        } else {
          console.log("@fetchPowers: Skipping laws (no update needed)")
          updatedLaws = updatedMetaData
        }
        console.log("@fetchPowers, waypoint 5", {updatedLaws, error})
        
        // Only fetch proposals if needed (based on block progress)
        if (updatedLaws && needsProposalsUpdate(updatedLaws)) {
          console.log("@fetchPowers: Fetching proposals (needed update)")
          updatedProposals = await fetchProposals(updatedLaws, 10n, 10000n)
        } else {
          console.log("@fetchPowers: Skipping proposals (no update needed)")
          updatedProposals = updatedLaws
        }
        
        // Only fetch executed actions if laws were updated (executed actions depend on laws)
        if (updatedProposals && (updatedLaws !== updatedMetaData || !updatedProposals.executedActions)) {
          console.log("@fetchPowers: Fetching executed actions")
          updatedExecutedActions = await fetchExecutedActions(updatedProposals)
        } else {
          console.log("@fetchPowers: Skipping executed actions (no update needed)")
          updatedExecutedActions = updatedProposals
        }
        
        console.log("@fetchPowers, waypoint 7", {updatedExecutedActions, error})
        
        // Ensure we have the final updated powers object
        const finalPowers = updatedExecutedActions || updatedProposals || updatedLaws || updatedMetaData
        if (finalPowers) {
          setPowers(finalPowers)
        }
      } catch (error) {
        console.error("@fetchPowers error:", error)
        setStatus("error")
        setError(error)
      } finally {
        setStatus("success")
      }
    }, [status] // Removed currentBlock from dependencies to prevent loop
  )

  // Helper function to check if laws need updating
  const needsLawsUpdate = (powers: Powers): boolean => {
    // Check if we have no laws at all
    if (!powers.laws || powers.laws.length === 0) {
      return true
    }
    
    // Check if lawCount has changed
    if (powers.lawCount && powers.laws.length !== Number(powers.lawCount) - 1) {
      return true
    }
    
    // Check if any laws are missing essential data
    const hasIncompleteData = powers.laws.some(law => 
      !law.conditions || !law.nameDescription || !law.params
    )
    
    return hasIncompleteData
  }

  // Helper function to check if proposals need updating
  const needsProposalsUpdate = (powers: Powers): boolean => {
    // If no block data, needs update
    if (!powers.proposalsBlocksFetched || !currentBlock) {
      return true
    }
    
    // If no proposals at all, needs update
    if (!powers.proposals || powers.proposals.length === 0) {
      return true
    }
    
    // Check if we need to fetch recent blocks (only fetch if there are significant new blocks)
    const blocksSinceLastFetch = Number(currentBlock) - Number(powers.proposalsBlocksFetched.to)
    return blocksSinceLastFetch > 50 // Increased threshold to be more conservative
  }

  return {status, error, powers, fetchPowers, fetchLawsAndRoles, fetchProposals, fetchExecutedActions, checkLaws, checkSingleLaw}  
}