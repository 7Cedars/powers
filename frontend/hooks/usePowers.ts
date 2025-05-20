import { Status, Proposal, Powers, Law, Metadata, RoleLabel, Conditions, LawExecutions, BlockRange, Role } from "../context/types"
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
  console.log("@usePowers, MAIN", {chainId, error, powers, publicClient, status})

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

  const checkLaws = async (powers: Powers, lawIds: bigint[]) => {
    console.log("@checkLaws, waypoint 0", {lawIds})
    let lawId: bigint
    let fetchedLaws: Law[] = []
    let laws: Law[] = powers.laws || []

    setStatus("pending")

    if (publicClient && lawIds.length > 0 && address) {
        // fetching all laws ever initiated by the org
        for (lawId of lawIds) {
          console.log("@checkLaws, waypoint 1", {lawId})
          try { 
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
            console.log("@checkLaws, waypoint 3", {fetchedLaws})
          } catch (error) {
            console.log("@checkLaws, waypoint 3", {error})
          }
        }
        console.log("@checkLaws, waypoint 4", {fetchedLaws})
        laws = laws.map((law: Law) => {
          let lawTemp: Law | undefined = fetchedLaws.find((l: Law) => l.index == law.index)
          
          if (lawTemp) {
            console.log("@checkLaws, waypoint 5", {lawTemp})
            return {
              ...law,
              lawAddress: lawTemp.lawAddress,
              lawHash: lawTemp.lawHash,
              index: lawTemp.index,
              active: lawTemp.active
            }
          } else {
            console.log("@checkLaws, waypoint 6", {law})
            return law
          }
        })
        console.log("@checkLaws, waypoint 7", {laws})
        const powersUpdated = { ...powers, 
          laws: laws,
          activeLaws: laws.filter((law: Law) => law.active)
        }
        setPowers(powersUpdated)
        powersUpdated && savePowers(powersUpdated)
        setStatus("success")
        return laws
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

    if (laws && roles && roleLabels) {
      powersUpdated = { ...powers, 
        laws: laws, 
        activeLaws: laws.filter((law: Law) => law.active),
        roles: roles, 
        roleLabels: roleLabels
      }
      setPowers(powersUpdated)
      powersUpdated && savePowers(powersUpdated)
      setStatus("success")
    }
  }
  
  const fetchProposals = async (powers: Powers, maxRuns: bigint, chunkSize: bigint) => {
    let powersUpdated: Powers | undefined;
    setStatus("pending")

    if (!publicClient || !currentBlock) {
      setStatus("error")
      setError("No public client or current block")
    } else {
      // Initialize arrays to collect results
      let proposalsFetched: Proposal[] = powers.proposals || [];
     
      let distance = powers.proposalsBlocksFetched ? BigInt(Number(currentBlock) - Number(powers.proposalsBlocksFetched?.to)) : BigInt(Number(chunkSize) * Number(maxRuns))
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
        console.log("@fetchProposals, waypoint 1", {chunkTo, i, distance})
      
        // calculate chunk boundaries
        chunkFrom = blockFrom + BigInt(i * Number(chunkSize))
        chunkTo = (chunkFrom + chunkSize) > currentBlock ? currentBlock : (chunkFrom + chunkSize)
        
        try { 
          // Fetch events for the current chunk
          const logs = await publicClient.getContractEvents({ 
            address: powers.contractAddress as `0x${string}`,
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

          let newProposals: Proposal[] = (fetchedLogs as ParseEventLogsReturnType).map(log => log.args as Proposal);
          // but with typing of nonce and actionId as string
          newProposals = newProposals.map(proposal => { 
            return {
              ...proposal,
              actionId: String(proposal.actionId),
              nonce: String(proposal.nonce)
            }
          })
          // add fetched proposals to the array
          proposalsFetched = [...proposalsFetched, ...newProposals]
          } catch (error) {
            setStatus("error")
            setError(error)
          }
          i = i + Number(chunkSize)
        }
        
        const sortedProposals = proposalsFetched.sort((a: Proposal, b: Proposal) => a.voteStart > b.voteStart ? -1 : 1);
        console.log("@fetchProposals, waypoint 2", {sortedProposals})
        
          powersUpdated = { ...powers, 
            proposals: sortedProposals, 
            proposalsBlocksFetched: { 
              from: powers.proposalsBlocksFetched?.from ? 
                powers.proposalsBlocksFetched.from : // note: from is only saved once, and is never updated.  
                blockFrom, 
              to: chunkTo 
            }
          }
          setPowers(powersUpdated)
          savePowers(powersUpdated)
          setStatus("success")
      }
  }

  // const allProposals = [...(powers.proposals || []), ...fetchedProposals];

  // setStatus("success")


  // Need fetchRoleHolders function here. Same logic as fetchProposals.
  
  const fetchRoleHolders = async (powers: Powers, maxRuns: bigint, chunkSize: bigint) => {
    // let powersUpdated: Powers | undefined = powers
    // setStatus("pending")

    // if (!publicClient || !currentBlock) {
    //   setStatus("error")
    //   setError("No public client or current block")
    // } else {
    //   // Initialize arrays to collect results
    //   const roleHoldersFetched: Role[] = [];
    //   const blocksFetched: BlockRange[] = [];
      
    //   // Get previously fetched blocks from powers
    //   const fetched: BlockRange[] = [...(powers.roleHoldersBlocksFetched || [])];

    //   // Add current block to make sure we have a complete range
    //   if (fetched.length === 0 || fetched[fetched.length - 1].to < currentBlock) {
    //     fetched.push({ from: currentBlock, to: currentBlock });
    //   }

    //   // Sort fetched blocks by 'to' in descending order for proper gap analysis
    //   fetched.sort((a, b) => Number(b.to) - Number(a.to));

    //   // Find gaps in fetched blocks
    //   const gaps: BlockRange[] = [];
    //   console.log("@fetchRoleHolders, waypoint 0.5", {gaps})

    //   if (fetched.length > 1) {
    //     for (let i = 0; i < fetched.length - 1; i++) {
    //       if (Number(fetched[i].from) - Number(fetched[i+1].to) > 1) {
    //         gaps.push({ from: BigInt(fetched[i+1].to) + 1n, to: BigInt(fetched[i].from) - 1n });
    //         console.log("@fetchRoleHolders, waypoint 0.6", {gaps})
    //       }
    //     }
    //   } else {
    //     // If we only have the current block, fetch a range of past blocks
    //     gaps.push({ from: currentBlock > Number(chunkSize) ? currentBlock - chunkSize : 0n, to: currentBlock });
    //     console.log("@fetchRoleHolders, waypoint 0.7", {gaps})
    //   }
      
    //   // Fetch blocks in chunks with pagination
    //   let runs = 0;
      
    //   for (const gap of gaps) {
    //     console.log("@fetchRoleHolders, waypoint 0.8", {gap})
    //     // Split large gaps into smaller chunks of max 500 blocks
    //     const blockRange = Number(gap.to) - Number(gap.from) + 1;
    //     const requiredChunks = Math.ceil(blockRange / Number(chunkSize));
    //     console.log("@fetchRoleHolders, waypoint 0.9", {blockRange, requiredChunks})
        
    //     for (let i = 0; i < requiredChunks; i++) {
    //       console.log("@fetchRoleHolders, waypoint 0.10", {i})
    //       // Check if we've reached the maximum number of runs
    //       if (runs >= maxRuns) {
    //         powersUpdated = { ...powers, 
    //           roleHolders: roleHoldersFetched, 
    //           roleHoldersBlocksFetched: blocksFetched
    //         }
    //         setPowers(powersUpdated)
    //         powersUpdated && savePowers(powersUpdated)
    //         setStatus("success")
    //         console.log("@fetchRoleHolders, waypoint 0.11", { roleHolders: roleHoldersFetched, blocks: blocksFetched })
    //         return { roleHolders: roleHoldersFetched, blocks: blocksFetched }
    //       }
          
    //       // Calculate chunk boundaries
    //       const chunkFrom = gap.from + BigInt(i * Number(chunkSize));
    //       const chunkTo = i === requiredChunks - 1 
    //         ? gap.to 
    //         : gap.from + BigInt((i + 1) * Number(chunkSize) - 1); 
    //       console.log("@fetchRoleHolders, waypoint 0.12", {chunkFrom, chunkTo})

    //       try {
    //         console.log("@fetchRoleHolders, waypoint 0.13", {chunkFrom, chunkTo})
    //         // Fetch events for the current chunk
    //         const logs = await publicClient.getContractEvents({ 
    //           address: powers.contractAddress as `0x${string}`,
    //           abi: powersAbi, 
    //           eventName: 'RoleSet',
    //           fromBlock: chunkFrom,
    //           toBlock: chunkTo
    //         });
            
    //         // Record fetched block range
    //         blocksFetched.push({ from: chunkFrom, to: chunkTo });
    //         console.log("@fetchRoleHolders, waypoint 0.14", {blocksFetched})
            
    //         // Parse logs and extract role holders
    //         const fetchedLogs = parseEventLogs({
    //           abi: powersAbi,
    //           eventName: 'RoleSet',
    //           logs
    //         });
    //         console.log("@fetchRoleHolders, waypoint 0.15", {fetchedLogs})
            
    //         const fetchedRoleHolders: Role[] = (fetchedLogs as ParseEventLogsReturnType)
    //           .map(log => log.args as Role);
    //         console.log("@fetchRoleHolders, waypoint 0.16", {fetchedRoleHolders})

    //         // Sort role holders and add to our result array
    //         fetchedRoleHolders.sort((a: Role, b: Role) => a.roleId > b.roleId ? -1 : 1);
    //         console.log("@fetchRoleHolders, waypoint 0.17", {fetchedRoleHolders})
    //         roleHoldersFetched.push(...fetchedRoleHolders);
    //         console.log("@fetchRoleHolders, waypoint 0.18", {roleHoldersFetched})
            
    //         runs++;
    //         console.log("@fetchRoleHolders, waypoint 0.19", {runs})
    //       } catch (error) {
    //         console.error("Error fetching role holders in block range", { chunkFrom, chunkTo, error });
    //         // Continue to next chunk despite error
    //       }
    //     }
    //   }
    //   setStatus("success")
    // }
  };

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      if (status == "pending") {
        return
      }
      setStatus("pending")

      let powersToBeUpdated: Powers | undefined = undefined
      let updatedData: Powers | undefined = undefined
      let updatedMetaData: Powers | undefined = undefined
      let localStore = localStorage.getItem("powersProtocols")
      
      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress == address)
    
      if (existing) { 
        powersToBeUpdated = existing 
      } else {
        powersToBeUpdated = { contractAddress: address }
      }
      updatedData = await fetchPowersData(powersToBeUpdated)
      if ( updatedData && (updatedData?.metadatas == undefined || updatedData?.metadatas != powersToBeUpdated?.metadatas) ) { 
        updatedMetaData = await fetchMetaData(updatedData) 
      } else {
        updatedMetaData = updatedData
      }
      if (updatedMetaData && (updatedMetaData?.laws == undefined || updatedMetaData?.laws != powersToBeUpdated?.laws) ) { 
        fetchLawsAndRoles(updatedMetaData) 
      }
      setPowers(updatedMetaData)
      setStatus("success")
    }, []
  )

  return {status, error, powers, fetchPowers, fetchLawsAndRoles, fetchProposals, checkLaws, fetchRoleHolders}  
}