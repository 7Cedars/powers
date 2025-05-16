import { Status, Proposal, Powers, Law, Metadata, RoleLabel, Conditions, LawExecutions, BlockRange } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { GetBlockReturnType, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { getBlock, getPublicClient, readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { sepolia } from "viem/chains";
import { useParams } from "next/navigation";
import { useBlockNumber } from "wagmi";

type PowersData = {
  name: string
  uri: string
  lawCount: bigint
}

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

  // console.log("@usePowers, MAIN", {chainId, error, powers, publicClient})

  // loading powers from local storage
  useEffect(() => {
    console.log("@usePowers, check local store TRIGGERED")
    let localStore = localStorage.getItem("powersProtocols")
    console.log("@usePowers, waypoint 0", {localStore})
    const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
    if (saved.length > 0) {
      setPowers(saved.find(item => item.contractAddress == address))
    }
  }, [, address])

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
      const nameContract = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'name'
      })  

      const uriContract = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'uri',
      })

      const lawCountContract = await publicClient.readContract({
        address: powers.contractAddress as `0x${string}`,
        abi: powersAbi,
        functionName: 'lawCount',
      })

      if (nameContract && uriContract && lawCountContract) {
        powersPopulated.lawCount = lawCountContract as bigint
        powersPopulated.name = nameContract as string
        powersPopulated.uri = uriContract as string
      }
      return powersPopulated

    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const fetchMetaData = async (powers: Powers): Promise<Metadata | undefined> => {
    let updatedMetaData: Metadata | undefined = powers.metadatas
    if (publicClient && powers && powers.uri && !updatedMetaData) {
      try {
        if (powers.uri) {
          const fetchedMetadata: unknown = await(
            await fetch(powers.uri as string)
            ).json()
          updatedMetaData = parseMetadata(fetchedMetadata) 
        } 
        return updatedMetaData
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const checkLaws = async (powers: Powers) => {
    let lawId: bigint
    let fetchedLaws: Law[] = []
    let laws: Law[] = powers.laws || []
    console.log("@checkLaws, waypoint 0", {laws})
    const lawIds: bigint[] = Array.from({length: Number(powers.lawCount) - 1}, (_, i) => BigInt(i+1))
    console.log("@checkLaws, waypoint 0.1", {lawIds})

    if (publicClient && lawIds.length > 0 && address) {
        // fetching all laws ever initiated by the org
        for (lawId of lawIds) {
          try { 
            console.log("@checkLaws, waypoint 1", {address, lawcount: powers.lawCount, lawId})
            const lawFetched = await publicClient.readContract({ 
              abi: powersAbi,
              address: address as `0x${string}`,
              functionName: 'getActiveLaw',
              args: [BigInt(lawId)]
            })
            console.log("@checkLaws, waypoint 2", {lawFetched})
            const lawFetchedTyped = lawFetched as [`0x${string}`, `0x${string}`, boolean]
            fetchedLaws.push({
              powers: address,
              lawAddress: lawFetchedTyped[0] as unknown as `0x${string}`,
              lawHash: lawFetchedTyped[1] as unknown as `0x${string}`,
              index: lawId,
              active: lawFetchedTyped[2] as unknown as boolean
            })
          } catch (error) {
            console.log("@checkLaws, waypoint 3", {error})
          }
        }

        laws = fetchedLaws.map((law: Law) => {
          let lawTemp: Law | undefined = laws.find((l: Law) => l.index == law.index)
          console.log("@checkLaws, waypoint 2.1", {lawTemp})
          if (lawTemp) {
            console.log("@checkLaws, waypoint 2.2 (law exists)", {lawTemp})
            return {
              ...lawTemp,
              powers: address,
              lawAddress: law.lawAddress,
              lawHash: law.lawHash,
              index: law.index,
              active: law.active
            }
          } else {
            console.log("@checkLaws, waypoint 2.3 (law does not exist)", {lawId})
            return {
              powers: address,
              lawAddress: law.lawAddress,
              lawHash: law.lawHash,
              index: law.index,
              active: law.active
            }
          }
        })
    }
    console.log("@checkLaws, waypoint 4", {laws})
    return laws
  }

  const populateLaws = async (laws: Law[]) => {
    let law: Law
    const populatedLaws: Law[] = []

    console.log("@populateLaws, waypoint 0", {laws})

    try {
      for (law of laws) {
        console.log("@populateLaws, waypoint 0.0", {law})
        if (!law.conditions && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawConditions = await publicClient.readContract({
            abi: lawAbi, 
            address: law.lawAddress as `0x${string}`,
            functionName: 'getConditions',
            args: [law.powers, law.index]
          })
          console.log("@populateLaws, waypoint 0.1", {lawConditions, law})
          law.conditions = lawConditions as Conditions
        }

        if (!law.inputParams && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawInputParams = await publicClient.readContract({
            abi: lawAbi, 
            address: law.lawAddress as `0x${string}`,
            functionName: 'getInputParams',
            args: [law.powers, law.index]
          })
          console.log("@populateLaws, waypoint 0.2", {lawInputParams, law})
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
          console.log("@populateLaws, waypoint 0.3", {nameDescription, law})
          law.nameDescription = nameDescription as string
        }
        populatedLaws.push(law)
        console.log("@populateLaws, waypoint 1", {populatedLaws})
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

    console.log("@updateRoleLabels, waypoint 0", {roles, powers})

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
    let roles: bigint[] | undefined = undefined
    let roleLabels: RoleLabel[] | undefined = undefined
    let powersUpdated: Powers | undefined = undefined

    try {
      laws = await checkLaws(powers)
      if (laws) { roles = calculateRoles(laws) } 
      if (roles) { roleLabels = await updateRoleLabels(roles, powers) }  
    } catch (error) {
      setStatus("error")
      setError(error)
    }

    if (laws && roles && roleLabels) {
      powersUpdated = { ...powers, 
        laws: laws, 
        roles: roles, 
        roleLabels: roleLabels
      }
      console.log("@usePowers, waypoint 7", {powersUpdated})
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      console.log("@fetchPowers, waypoint 8")
      setStatus("success")
    }
  }
  
  const fetchProposals = async (powers: Powers, maxRuns: number) => {
    let powersUpdated: Powers | undefined = powers
    setStatus("pending")

    if (!publicClient || !currentBlock) {
      setStatus("error")
      setError("No public client or current block")
    } else {
      // Initialize arrays to collect results
      const proposalsFetched: Proposal[] = [];
      const blocksFetched: BlockRange[] = [];
      
      // Get previously fetched blocks from powers
      const fetched: BlockRange[] = [...(powers.proposalsFetched || [])];
      
      // Add current block to make sure we have a complete range
      if (fetched.length === 0 || fetched[fetched.length - 1].to < currentBlock) {
        fetched.push({ from: currentBlock, to: currentBlock });
      }
      
      // Sort fetched blocks by 'to' in descending order for proper gap analysis
      fetched.sort((a, b) => Number(b.to - a.to));
      
      // Find gaps in fetched blocks
      const gaps: BlockRange[] = [];
      
      if (fetched.length > 1) {
        for (let i = 0; i < fetched.length - 1; i++) {
          if (fetched[i].from - fetched[i+1].to > 1n) {
            gaps.push({ from: fetched[i+1].to + 1n, to: fetched[i].from - 1n });
          }
        }
      } else {
        // If we only have the current block, fetch a range of past blocks
        gaps.push({ from: currentBlock > 10000n ? currentBlock - 10000n : 0n, to: currentBlock });
      }
      
      // Fetch blocks in chunks with pagination
      let runs = 0;
      
      for (const gap of gaps) {
        // Split large gaps into smaller chunks of max 500 blocks
        const blockRange = gap.to - gap.from + 1n;
        const requiredChunks = Math.ceil(Number(blockRange) / 500);
        
        for (let i = 0; i < requiredChunks; i++) {
          // Check if we've reached the maximum number of runs
          if (runs >= maxRuns) {
            powersUpdated = { ...powers, 
              proposals: proposalsFetched, 
              proposalsFetched: blocksFetched
            }
            setPowers(powersUpdated)
            powersUpdated && savePowers(powersUpdated)
            setStatus("success")
            return { proposals: proposalsFetched, blocks: blocksFetched }
          }
          
          // Calculate chunk boundaries
          const chunkFrom = gap.from + BigInt(i * 500);
          const chunkTo = i === requiredChunks - 1 
            ? gap.to 
            : gap.from + BigInt((i + 1) * 500 - 1);
          
          try {
            // Fetch events for the current chunk
            const logs = await publicClient.getContractEvents({ 
              address: powers.contractAddress as `0x${string}`,
              abi: powersAbi, 
              eventName: 'ProposedActionCreated',
              fromBlock: chunkFrom,
              toBlock: chunkTo
            });
            
            // Record fetched block range
            blocksFetched.push({ from: chunkFrom, to: chunkTo });
            console.log("@fetchProposals, waypoint 1", {blocksFetched})
            
            // Parse logs and extract proposals
            const fetchedLogs = parseEventLogs({
              abi: powersAbi,
              eventName: 'ProposedActionCreated',
              logs
            });
            
            const fetchedProposals: Proposal[] = (fetchedLogs as ParseEventLogsReturnType)
              .map(log => log.args as Proposal);
            
            // Sort proposals and add to our result array
            fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart > b.voteStart ? -1 : 1);
            proposalsFetched.push(...fetchedProposals);
            
            runs++;
          } catch (error) {
            console.error("Error fetching proposals in block range", { chunkFrom, chunkTo, error });
            // Continue to next chunk despite error
          }
        }
      }
    }
  };

  // Need fetchRoleHolders function here. Same logic as fetchProposals.
  // TODO 

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      let powersToBeUpdated: Powers | undefined = undefined
      let powersUpdated: Powers | undefined = undefined
      let updatedData: Powers | undefined = undefined
      let checkedLaws: Law[] | undefined = undefined
      let updatedMetaData: Metadata | undefined = undefined
      let updatedLaws: Law[] | undefined = undefined
      let updatedRoles: bigint[] | undefined = undefined 
      let updatedRoleLabels: RoleLabel[] | undefined = undefined
      console.log("@usePowers, waypoint 1", {address})

      setStatus("pending")
      if (powers) { 
        powersToBeUpdated = powers 
      } else {
        powersToBeUpdated = { contractAddress: address }
      }

      updatedData = await fetchPowersData(powersToBeUpdated)
      console.log("@usePowers, waypoint 1.1", {updatedData})
      if (updatedData) {
        checkedLaws = await checkLaws(updatedData)
        console.log("@usePowers, waypoint 2", {checkedLaws})
      }
      if (checkedLaws) { 
        updatedLaws = await populateLaws(checkedLaws) 
        updatedMetaData = await fetchMetaData(powersToBeUpdated)
        console.log("@usePowers, waypoint 3", {updatedLaws, updatedMetaData})
      }
      if (updatedLaws) {
        updatedRoles = calculateRoles(updatedLaws) 
        console.log("@usePowers, waypoint 4", {updatedRoles})
      }
      if (updatedRoles) {
        updatedRoleLabels = await updateRoleLabels(updatedRoles, powersToBeUpdated)
        console.log("@usePowers, waypoint 5", {updatedRoleLabels})
      }
      if (updatedRoleLabels && updatedLaws && updatedLaws.length == Number(powersToBeUpdated.lawCount) - 1) {
        console.log("@usePowers, waypoint 6", {updatedRoleLabels})
        powersUpdated = { ...powersToBeUpdated, 
          metadatas: updatedMetaData, 
          laws: updatedLaws, 
          roles: updatedRoles, 
          roleLabels: updatedRoleLabels,
          activeLaws: updatedLaws?.filter((law: Law) => law.active)
        }
        console.log("@usePowers, waypoint 7", {powersUpdated})
      }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
    }, []
  )

  return {status, error, powers, fetchPowers, fetchLawsAndRoles, fetchProposals}  
}