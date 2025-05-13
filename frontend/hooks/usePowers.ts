import { Status, Proposal, Powers, Law, Metadata, RoleLabel } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { GetBlockReturnType, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { getBlock, getPublicClient, readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { sepolia } from "viem/chains";
import { useParams } from "next/navigation";

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

  // console.log("@usePowers, waypoint 0", {chainId, error, powers, publicClient})

  const fetchLocalStorage = async (address: `0x${string}`) => {
    let localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore ? JSON.parse(localStore) : []
    const savedPowers = saved.find(item => item.contractAddress == address) 

    console.log("@fetchLocalStorage: waypoint 0", {savedPowers})

    if (savedPowers) {
      return savedPowers
    } else {
      return undefined
    }
  }

  // should combine these three functions... 
  const fetchPowersData = async(address: `0x${string}`): Promise<PowersData | undefined> => {
      const powersContract = {
        address: address as `0x${string}`,
        abi: powersAbi,
      } as const

      const powersData = await readContracts(wagmiConfig, {
        contracts: [  
          {
            ...powersContract,
            functionName: 'name',
          },
          {
            ...powersContract,
            functionName: 'uri',
          },
          {
            ...powersContract,
            functionName: 'lawCount',
          }
        ]
      })
      
      // set Error if any of the calls fail
      if (powersData.find(item => item.status != "success")) {
        console.log("@fetchPowersData, waypoint 1 ERROR", {powersData})
        setError(powersData.find(item => item.status != "success")?.error)
      } else {
        const dataFetched = {
          name: powersData[0].result as string,
          uri: powersData[1].result as string,
          lawCount: powersData[2].result as bigint
        }
        console.log("@fetchPowersData, waypoint 1", {dataFetched})

        return dataFetched
      }
  }

  const fetchMetaData = async (uri: string): Promise<Metadata | undefined> => {
    if (publicClient) {
    console.log("@fetchMetaData, waypoint 0", {uri})
      try {
        if (uri) {
          const fetchedMetadata: unknown = await(
            await fetch(uri as string)
            ).json()
            return parseMetadata(fetchedMetadata) 
          } 
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchActiveLaws = async (address: `0x${string}`, lawIds: bigint[]) => {
    let law: bigint

    console.log("@fetchActiveLaws, waypoint 3", {address, publicClient, lawIds})

    if (publicClient && lawIds.length > 0) {
      try {
        // fetching all laws ever initiated by the org
        let fetchedLaws: Law[] = []
        for (law of lawIds) {
          if (address) {
            console.log("@fetchActiveLaws, waypoint 1", {address})
            const activeLaw = await readContract(wagmiConfig, { 
              abi: powersAbi, 
              address: address,
              functionName: 'getActiveLaw',
              args: [law]
            })
            console.log("@fetchActiveLaws, waypoint 2", {activeLaw})

            // console.log("@fetchLawsAndRoles, waypoint 3", {fetchedLogs})
            // const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            // let fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)
            // // console.log("@fetchLawsAndRoles: waypoint 0", {fetchedLaws})
            // fetchedLaws = fetchedLogsTyped.map(log => (
            //   {
            //     ...log.args as Law, 
            //     lawAddress: log.address, 
            //   }))
            // console.log("@fetchLawsAndRoles, waypoint 4", {fetchedLaws})
            // fetchedLaws.forEach(law => {
            //   law.params = bytesToParams(law.inputParams as `0x${string}`)
            // })
            // console.log("@fetchLawsAndRoles, waypoint 5", {fetchedLaws})
            // fetchedLaws.sort((a: Law, b: Law) => Number(a.index) > Number(b.index) ? 1 : -1)
            // console.log("@fetchLawsAndRoles, waypoint 6", {fetchedLaws})

            

            // // fetching active laws
            // let activeLaws: Law[] = []
            // if (fetchedLaws) {
            //   for await (law of fetchedLaws) {
            //     console.log("@fetchLawsAndRoles, activeLaw waypoint 1", {fetchedLaws, powersAbi, address, indexLaw: law.index})
            //     const activeLaw = await publicClient.readContract({
            //       abi: powersAbi,
            //       address: address,
            //       functionName: 'isActiveLaw', 
            //       args: [law.index]
            //     })
            //     const active = activeLaw as boolean
            //     console.log("@fetchLawsAndRoles, activeLaw waypoint 2", {activeLaw, active})
            //     if (active) activeLaws.push(law)
            //   }
            // } 
            // // calculating roles
            // const rolesAll = activeLaws.map((law: Law) => law.conditions.allowedRole)
            // const fetchedRoles = [... new Set(rolesAll)] as bigint[]
            
            // console.log("@fetchLawsAndRoles: waypoint 2", {fetchedLaws, activeLaws, fetchedRoles})
          
            // if (fetchedLaws && fetchedRoles) {
            //   return {laws: fetchedLaws, activeLaws: activeLaws, roles: fetchedRoles}
            }
        }
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  // const fetchRoleLabels = async (address: `0x${string}`) => {
  //   // console.log("@fetchRoleLabels, waypoint 1", {organisations})
  //   if (publicClient) {
  //     try {
  //       const logs = await publicClient.getContractEvents({ 
  //         abi: powersAbi, 
  //         address: address as `0x${string}`, 
  //         eventName: 'RoleLabel',
  //         fromBlock: supportedChain?.genesisBlock
  //           })
  //           // console.log("@fetchRoleLabels, waypoint 3", {logs})
  //           const fetchedLogs = parseEventLogs({
  //             abi: powersAbi,
  //             eventName: 'RoleLabel',
  //             logs
  //           })
  //           // console.log("@fetchRoleLabels, waypoint 4", {fetchedLogs})
  //           const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
  //           // console.log("@fetchRoleLabels, waypoint 5", {fetchedLogsTyped})
  //           const fetchedRoleLabels: RoleLabel[] = fetchedLogsTyped.map(log => log.args as RoleLabel)
  //           // console.log("@fetchRoleLabels, waypoint 6", {fetchedRoleLabels})
  //           return fetchedRoleLabels
  //       } catch (error) {
  //         setStatus("error") 
  //         setError(error)
  //       }
  //     }
  // }

  // const getProposals = async (address: `0x${string}`) => {
  //   if (publicClient) {
  //     console.log("@getProposals, waypoint 1", {publicClient})
  //     try {
  //       const logs = await publicClient.getContractEvents({ 
  //         address: address as `0x${string}`,
  //         abi: powersAbi, 
  //         eventName: 'ProposedActionCreated',
  //         fromBlock: supportedChain?.genesisBlock
  //       })
  //       const fetchedLogs = parseEventLogs({
  //         abi: powersAbi,
  //         eventName: 'ProposedActionCreated',
  //         logs
  //       })
  //       const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
  //       // console.log("@getProposals: waypoint 1", {fetchedLogsTyped})
  //       const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
  //       fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart  > b.voteStart ? -1 : 1)
  //       // console.log("@getProposals: waypoint 2", {fetchedProposals})
  //       if (fetchedProposals) {
  //         return fetchedProposals
  //       }
  //     } catch (error) {
  //       setStatus("error") 
  //       setError(error)
  //     }
  //   }
  // }

  const getProposalsState = async (proposals: Proposal[], address: `0x${string}`) => {
    let proposal: Proposal
    let state: number[] = []

    // console.log("@getProposalsState, waypoint 0", {proposals, address})

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.actionId) {
              const fetchedState = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: address,
                functionName: 'state', 
                args: [proposal.actionId]
              })
              state.push(Number(fetchedState)) // = 5 is a non-existent state
            }
        } 
        // console.log("@getProposalsState: waypoint 1", {state})
        return state
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  // const fetchProposals = useCallback(
  //   async (address: `0x${string}`) => {
  //     // console.log("fetchProposals called, waypoint 1: ", {organisation})

  //     let proposals: Proposal[] | undefined = [];
  //     let states: number[] | undefined = []; 
  //     let blocks: GetBlockReturnType[] | undefined = [];
  //     let proposalsFull: Proposal[] | undefined = [];

  //     // proposals = await getProposals(address)
  //     // console.log("fetchProposals called, waypoint 2: ", {proposals})
  //     if (proposals && proposals.length > 0) {
  //       states = await getProposalsState(proposals, address)
  //       blocks = await getBlockData(proposals, address)
  //     } 
  //     // console.log("@fetchProposals: waypoint 2", {states, blocks})
  //     if (states && blocks) { // + votes later.. 
  //       proposalsFull = proposals?.map((proposal, index) => {
  //         return ( 
  //           {...proposal, state: states[index], voteStartBlockData: {...blocks[index], chainId: sepolia.id}}
  //         )
  //       })
  //     }  
  //     // console.log("@fetchProposals: waypoint 3", {proposalsFull})
  //     // console.log("fetchProposals called, waypoint 4: ", {proposalsFull})
  //     // return data - to be saved in local storage. 
  //     return proposalsFull
  // }, [ ]) 


  const fetchPowers = useCallback(
    async () => {
      console.log("@usePowers, waypoint 1", {address})
      setStatus("pending")
      const savedPowers = await fetchLocalStorage(address)
      console.log("@usePowers, waypoint 2", {savedPowers})

      const powersData = await fetchPowersData(address)
      if (savedPowers?.laws && powersData && powersData?.lawCount > savedPowers.laws.length) {
        // fetch laws for the new laws. 
        const lawIds = await fetchLawIds(address, powersData.lawCount)
        console.log("@usePowers, waypoint 3", {lawIds})
      }



    
        console.log("@usePowers, waypoint 3", {address})
        
        console.log("@usePowers, waypoint 4: ", {powersData})
        // const names = powersData[0]
        // console.log("@fetchPowers, waypoint 4: ", {names})
        // const metadatas = powersData[1]
        // console.log("@fetchPowers, waypoint 5: ", {metadatas})
        if (powersData && powersData.lawCount > 0) {
          const activeLaws = await fetchActiveLaws(address, powersData.lawCount)
          console.log("@usePowers, waypoint 6: ", {activeLaws})
        }
        // const proposals = await fetchProposals(address)
        // console.log("@fetchPowers, waypoint 7: ", {proposals})
        // const roleLabels = await fetchRoleLabels(address)
        // console.log("@fetchPowers, waypoint 8: ", {roleLabels})

        // // console.log("waypoint 4: data fetched: ", {names, metadatas, lawsAndRoles, proposalsPerOrg, roleLabels})
        // if (names && metadatas && lawsAndRoles && roleLabels && proposals) { 
        //     const powersFetched = {
        //       contractAddress: address,
        //       name: names, 
        //       metadatas: metadatas, 
        //       colourScheme: 0, // TODO: make dynamic. 
        //       laws: lawsAndRoles.laws, 
        //       activeLaws: lawsAndRoles.activeLaws, 
        //       proposals: proposals, 
        //       roles: lawsAndRoles.roles, 
        //       roleLabels: roleLabels
        //     }
        //     console.log("@fetchPowers, waypoint 9: ", {powersFetched})
        //     // when multiple components are calling this function at the same time, we need to make sure they do not create separate instances of the same Powers. 
        //     let localStore = localStorage.getItem("powersProtocols")
        //     const saved: Powers[] = localStore ? JSON.parse(localStore) : []
        //     const powersToUpdate = saved.find(item => item.contractAddress == address)
        //     console.log("@fetchPowers, waypoint 10: ", {powersToUpdate})
        //     if (powersToUpdate) {
        //       const allPowers = saved.map(powers => powers.contractAddress == address ? powersFetched : powers)
        //       localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
        //         typeof value === "bigint" ? value.toString() : value,
        //       ));
        //       console.log("@fetchPowers, waypoint 11: ", {allPowers})
        //     } else {
        //       const allPowers = [...saved, powersFetched]
        //       localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
        //         typeof value === "bigint" ? value.toString() : value,
        //       ));
        //       console.log("@fetchPowers, waypoint 12: ", {powersFetched})
        //     }
        //     setPowers(powersFetched)
        //     console.log("@fetchPowers, waypoint 13: ", {powersFetched})
        //   }     
      }

      console.log("@fetchPowers, waypoint 14")
      setStatus("success")
    }, []
  )
    
  // const updatePowers = useCallback(
  //   // updates laws, roles and proposal info of an existing Powers or fetches a new Powers - and stores it in local storage.  
  //   async (address: `0x${string}`) => {
  //     setStatus("pending")
  //     console.log("@updatePowers: TRIGGERED")

  //     let localStore = localStorage.getItem("powersProtocols")
  //     const saved: Powers[] = localStore ? JSON.parse(localStore) : []
  //     const powersToUpdate = saved.find(item => item.contractAddress == address)

  //     console.log("@updatePowers: waypoint 1", {powersToUpdate})
      
  //     if (powersToUpdate) {
  //       const lawsAndRoles = await fetchLawsAndRoles(address)
  //       console.log("@updatePowers: waypoint 1.1", {lawsAndRoles})
  //       const roleLabels = await fetchRoleLabels(address)
  //       console.log("@updatePowers: waypoint 1.2", {roleLabels})
  //       const proposals = await fetchProposals(address)
  //       console.log("@updatePowers: waypoint 1.3", {proposals})

  //       console.log("@updatePowers: waypoint 2", {lawsAndRoles, roleLabels, proposals})

  //       if (lawsAndRoles && proposals && roleLabels) {
  //         const updatedPowers = 
  //         { ...powersToUpdate,  
  //           laws: lawsAndRoles.laws, 
  //           activeLaws: lawsAndRoles.activeLaws, 
  //           proposals: proposals, 
  //           roles: lawsAndRoles.roles, 
  //           roleLabels: roleLabels
  //         }

  //         console.log("@updatePowers: waypoint 3", {updatedPowers})

  //         const updatedPowersArray: Powers[] = saved.map(
  //           powers => powers.contractAddress == updatedPowers.contractAddress ? updatedPowers : powers
  //         )

  //         console.log("@updatePowers: waypoint 4", {updatedPowersArray})
        
  //         localStorage.setItem("powersProtocols", JSON.stringify(updatedPowersArray, (key, value) =>
  //           typeof value === "bigint" ? value.toString() : value,
  //         ));

  //         setPowers(updatedPowers)

  //         console.log("@updatePowers: waypoint 5")
  //       }
  //     } else {
  //       setStatus("error")
  //       setError("Powers not found")
  //     }

  //     setStatus("success")
  //     }, []
  //   )

    // const updateProposals = useCallback(
    //   async (address: `0x${string}`) => {
    //     setStatus("pending")
    //     // console.log("@updateOrg: TRIGGERED")
  
    //     let localStore = localStorage.getItem("powersProtocols")
    //     const saved: Powers[] = localStore ? JSON.parse(localStore) : []
    //     const powersToUpdate = saved.find(item => item.contractAddress == address)

    //     if (powersToUpdate) {
    //       // const proposals = await fetchProposals(address)
    //       // const updatedPowers = 
    //       // { ...powersToUpdate,  
    //       //   proposals: proposals
    //       // }

    //       const updatedPowersArray: Powers[] = saved.map(
    //         powers => powers.contractAddress == updatedPowers.contractAddress ? updatedPowers : powers
    //       )
    //       localStorage.setItem("powersProtocols", JSON.stringify(updatedPowersArray, (key, value) =>
    //         typeof value === "bigint" ? value.toString() : value,
    //       ));

    //       setPowers(updatedPowers)

    //       setStatus("success")
    //     } else {
    //       setStatus("error")
    //       setError("Powers not found")
    //     }
    //   }, []
    // )

  return {status, error, powers, fetchPowers} // updateProposals
}