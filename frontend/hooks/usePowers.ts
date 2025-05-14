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

  console.log("@usePowers, MAIN", {chainId, error, powers, publicClient})

  useEffect(() => {
    let localStore = localStorage.getItem("powersProtocols")
    console.log("@usePowers, waypoint 0", {localStore})
    if (localStore && localStore == undefined) {
      const saved: Powers[] = JSON.parse(localStore)
      setPowers(saved.find(item => item.contractAddress == address))
    }
  }, [, address])

  // should combine these three functions... 
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

      const dataFetched: PowersData = {
        name: nameContract as string,
        uri: uriContract as string,
        lawCount: lawCountContract as bigint
      }

      powersPopulated.lawCount = dataFetched.lawCount as bigint
      powersPopulated.name = dataFetched.name as string
      powersPopulated.uri = dataFetched.uri as string
      return powersPopulated

    } catch (error) {
      setStatus("error") 
      setError(error)
    }
  }

  const fetchMetaData = async (powers: Powers): Promise<Metadata | undefined> => {
    let updatedMetaData: Metadata | undefined = undefined
    if (publicClient && powers && powers.uri && !powers.metadatas) {
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

  const checkLaws = async (address: `0x${string}`, lawCount: bigint) => {
    let law: bigint
    let laws: Law[] = []
    const lawIds: bigint[] = Array.from({length: Number(lawCount)}, (_, i) => BigInt(i+1))

    if (publicClient && lawIds.length > 0) {
      try {
        // fetching all laws ever initiated by the org
        for (law of lawIds) {
          if (address) {
            console.log("@checkLaws, waypoint 1", {address, lawCount, law})
            const lawFetched = await readContract(wagmiConfig, { 
              abi: powersAbi, 
              address: address as `0x${string}`,
              functionName: 'getActiveLaw',
              args: [law]
            })
            const lawFetchedTyped = lawFetched as [`0x${string}`, `0x${string}`, boolean]

            if (lawFetchedTyped) {
              laws.push({
                powers: address,
                lawAddress: lawFetchedTyped[0] as unknown as `0x${string}`,
                lawHash: lawFetchedTyped[1] as unknown as `0x${string}`,
                index: law,
                nameDescription: undefined, 
                active: lawFetchedTyped[2] as unknown as boolean
              })
            }
          }
        }
        return laws
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const populateLaws = async (laws: Law[]) => {
    let law: Law
    const populatedLaws: Law[] = []

    console.log("@populateLaws, waypoint 0", {laws})

    try {
      for (law of laws) {
        if (!law.conditions && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawConditions = await readContract(wagmiConfig, {
            abi: lawAbi, 
            address: law.lawAddress,
            functionName: 'getConditions',
            args: [law.powers, law.index]
          })
          law.conditions = lawConditions as Conditions
        }

        if (!law.inputParams && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const lawInputParams = await readContract(wagmiConfig, {
            abi: lawAbi, 
            address: law.lawAddress,
            functionName: 'getInputParams',
            args: [law.powers, law.index]
          })
          law.inputParams = lawInputParams as `0x${string}`
        }

        if (!law.nameDescription && law.lawAddress != `0x0000000000000000000000000000000000000000`) {
          const nameDescription = await readContract(wagmiConfig, {
            abi: lawAbi, 
            address: law.lawAddress,
            functionName: 'getNameDescription',
            args: [law.powers, law.index]
          })
          law.nameDescription = nameDescription as string
        }
        populatedLaws.push(law)
        console.log("@populateLaws, waypoint 1", {law})
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
      laws = await checkLaws(address, powers.lawCount ? powers.lawCount : BigInt(0))
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
      localStorage.setItem("powersProtocols", JSON.stringify(powersUpdated, (key, value) =>
        typeof value === "bigint" ? value.toString() : value,
      ));
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
            localStorage.setItem("powersProtocols", JSON.stringify(powersUpdated, (key, value) =>
              typeof value === "bigint" ? value.toString() : value,
            ));
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

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      let powers: Powers | undefined = undefined
      let powersToBeUpdated: Powers | undefined = undefined
      let powersUpdated: Powers | undefined = undefined
      let powersUpdatedData: Powers | undefined = undefined
      let updatedMetaData: Metadata | undefined = undefined
      let powersUpdatedLaws: Law[] | undefined = undefined
      let updatedLaws: Law[] | undefined = undefined
      let updatedRoles: bigint[] | undefined = undefined 
      let updatedRoleLabels: RoleLabel[] | undefined = undefined
      console.log("@usePowers, waypoint 1", {address})

      setStatus("pending")
      if (powers) { powersToBeUpdated = powers } else {
        powersToBeUpdated = { contractAddress: address }
      }

      powersUpdatedData = await fetchPowersData(powersToBeUpdated)
      if (powersUpdatedData) {
        powersUpdatedLaws = await checkLaws(address, powersUpdatedData.lawCount ? powersUpdatedData.lawCount : BigInt(0))
        console.log("@usePowers, waypoint 2", {powersUpdatedLaws})
      }
      if (powersUpdatedLaws) { 
        updatedLaws = await populateLaws(powersUpdatedLaws) 
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
      if (updatedRoleLabels) {
        console.log("@usePowers, waypoint 6", {updatedRoleLabels})
        powersUpdated = { ...powersToBeUpdated, 
          metadatas: updatedMetaData, 
          laws: updatedLaws, 
          roles: updatedRoles, 
          roleLabels: updatedRoleLabels
        }
        console.log("@usePowers, waypoint 7", {powersUpdated})
      }
      setPowers(powersUpdated)
      localStorage.setItem("powersProtocols", JSON.stringify(powersUpdated, (key, value) =>
        typeof value === "bigint" ? value.toString() : value,
      ));
      console.log("@fetchPowers, waypoint 8")
      setStatus("success")
    }, []
  )

  return {status, error, powers, fetchPowers, fetchLawsAndRoles, fetchProposals}  
}