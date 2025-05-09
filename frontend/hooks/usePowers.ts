import { Status, Proposal, Powers, Law, Metadata, RoleLabel } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { GetBlockReturnType, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { getBlock, getPublicClient, readContract } from "wagmi/actions";
import { supportedChains } from "@/context/chains";
import { bytesToParams, parseChainId, parseMetadata } from "@/utils/parsers";
import { sepolia } from "viem/chains";
import { useParams } from "next/navigation";

export const usePowers = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [powers, setPowers] = useState<Powers | undefined>() 
  const { chainId, powers: address } = useParams<{ chainId: string, powers: `0x${string}` }>()
  console.log("@usePowers, waypoint 0", {chainId, address})
  const supportedChain = supportedChains.find(chain => chain.id == Number(chainId))
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId), 
  })

  console.log("@usePowers, waypoint 0", {chainId, error, powers, publicClient})

  const checkLocalStorage = async (address: `0x${string}`) => {
    let localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore ? JSON.parse(localStore) : []
    const powersExists = saved.find(item => item.contractAddress == address) 

    console.log("@checkLocalStorage: waypoint 1", {powersExists})

    if (powersExists) {
      return powersExists
    } else {
      return undefined
    }
  }

  const fetchName = async (address: `0x${string}`) => {
    if (publicClient) {
    console.log("@fetchName, waypoint 0", {address})
      try {
        const name = await publicClient.readContract({
          abi: powersAbi,
          address: address,
          functionName: 'name'
        })
        console.log("@fetchName, waypoint 1", {name})
        return name as string
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
    }
  }

  const fetchMetaData = async (address: `0x${string}`) => {
    if (publicClient) {
    console.log("@fetchMetaData, waypoint 0", {address})
      try {
        const uri = await publicClient.readContract({
          abi: powersAbi,
          address: address,
          functionName: 'uri'
          })
        console.log("@fetchMetaData, waypoint 1", {uri})
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

  const fetchLawsAndRoles = async (address: `0x${string}`) => {
    let law: Law

    console.log("@fetchLawsAndRoles, waypoint 0", {address, publicClient})

    if (publicClient) {
      try {
        // fetching all laws ever initiated by the org
        if (address) {
          console.log("@fetchLawsAndRoles, waypoint 1", {address})
          const logs = await publicClient.getContractEvents({ 
            abi: lawAbi, 
            eventName: 'Law__Initialized',
            fromBlock: supportedChain?.genesisBlock,
            args: {
              powers: address
              }
            })
            console.log("@fetchLawsAndRoles, waypoint 2", {logs})
            const fetchedLogs = parseEventLogs({
              abi: lawAbi,
              eventName: 'Law__Initialized',
              logs
            })
            console.log("@fetchLawsAndRoles, waypoint 3", {fetchedLogs})
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            let fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)
            // console.log("@fetchLawsAndRoles: waypoint 0", {fetchedLaws})
            fetchedLaws = fetchedLogsTyped.map(log => (
              {
                ...log.args as Law, 
                lawAddress: log.address, 
              }))
            console.log("@fetchLawsAndRoles, waypoint 4", {fetchedLaws})
            fetchedLaws.forEach(law => {
              law.params = bytesToParams(law.inputParams as `0x${string}`)
            })
            console.log("@fetchLawsAndRoles, waypoint 5", {fetchedLaws})
            fetchedLaws.sort((a: Law, b: Law) => Number(a.index) > Number(b.index) ? 1 : -1)
            console.log("@fetchLawsAndRoles, waypoint 6", {fetchedLaws})

            

            // fetching active laws
            let activeLaws: Law[] = []
            if (fetchedLaws) {
              for await (law of fetchedLaws) {
                console.log("@fetchLawsAndRoles, waypoint 1", {fetchedLaws, powersAbi, address, indexLaw: law.index})
                const activeLaw = await publicClient.readContract({
                  abi: powersAbi,
                  address: address,
                  functionName: 'isActiveLaw', 
                  args: [law.index]
                })
                const active = activeLaw as boolean
                // console.log("@fetchLawsAndRoles: waypoint 1", {active})
                if (active) activeLaws.push(law)
              }
            } 
            // calculating roles
            const rolesAll = activeLaws.map((law: Law) => law.conditions.allowedRole)
            const fetchedRoles = [... new Set(rolesAll)] as bigint[]

            // console.log("@fetchLawsAndRoles: waypoint 2", {fetchedLaws, activeLaws, fetchedRoles})
          
            if (fetchedLaws && fetchedRoles) {
              return {laws: fetchedLaws, activeLaws: activeLaws, roles: fetchedRoles}
            }
        }
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchRoleLabels = async (address: `0x${string}`) => {
    // console.log("@fetchRoleLabels, waypoint 1", {organisations})
    if (publicClient) {
      try {
        const logs = await publicClient.getContractEvents({ 
          abi: powersAbi, 
          address: address as `0x${string}`, 
          eventName: 'RoleLabel',
          fromBlock: supportedChain?.genesisBlock
            })
            // console.log("@fetchRoleLabels, waypoint 3", {logs})
            const fetchedLogs = parseEventLogs({
              abi: powersAbi,
              eventName: 'RoleLabel',
              logs
            })
            // console.log("@fetchRoleLabels, waypoint 4", {fetchedLogs})
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            // console.log("@fetchRoleLabels, waypoint 5", {fetchedLogsTyped})
            const fetchedRoleLabels: RoleLabel[] = fetchedLogsTyped.map(log => log.args as RoleLabel)
            // console.log("@fetchRoleLabels, waypoint 6", {fetchedRoleLabels})
            return fetchedRoleLabels
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

  const getProposals = async (address: `0x${string}`) => {
    if (publicClient) {
      console.log("@getProposals, waypoint 1", {publicClient})
      try {
        const logs = await publicClient.getContractEvents({ 
          address: address as `0x${string}`,
          abi: powersAbi, 
          eventName: 'ProposedActionCreated',
          fromBlock: supportedChain?.genesisBlock
        })
        const fetchedLogs = parseEventLogs({
          abi: powersAbi,
          eventName: 'ProposedActionCreated',
          logs
        })
        const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
        // console.log("@getProposals: waypoint 1", {fetchedLogsTyped})
        const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
        fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart  > b.voteStart ? -1 : 1)
        // console.log("@getProposals: waypoint 2", {fetchedProposals})
        if (fetchedProposals) {
          return fetchedProposals
        }
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const getBlockData = async (proposals: Proposal[], address: `0x${string}`) => {
    let proposal: Proposal
    let blocksData: GetBlockReturnType[] = []

    const powers = await checkLocalStorage(address)

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          const existingProposal = powers?.proposals?.find(p => p.actionId == proposal.actionId)
          if (!existingProposal || !existingProposal.voteStartBlockData?.chainId) {
            // console.log("@getBlockData, waypoint 1: ", {proposal})
            const fetchedBlockData = await getBlock(wagmiConfig, {
              blockNumber: proposal.voteStart,
              chainId: sepolia.id, // NB This needs to be made dynamic. In this case need to read of sepolia because arbitrum uses mainnet block numbers.  
            })
            const blockDataParsed = fetchedBlockData as GetBlockReturnType
            // console.log("@getBlockData, waypoint 2: ", {blockDataParsed})
            blocksData.push(blockDataParsed)
          } else {
            blocksData.push(existingProposal.voteStartBlockData ? existingProposal.voteStartBlockData : {} as GetBlockReturnType)
          }
        } 
        // console.log("@getBlockData, waypoint 3: ", {blocksData})
        return blocksData
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const getProposalsState = async (proposals: Proposal[], address: `0x${string}`) => {
    let proposal: Proposal
    let state: number[] = []

    console.log("@getProposalsState, waypoint 0", {proposals, address})

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

  const fetchProposals = useCallback(
    async (address: `0x${string}`) => {
      // console.log("fetchProposals called, waypoint 1: ", {organisation})

      let proposals: Proposal[] | undefined = [];
      let states: number[] | undefined = []; 
      let blocks: GetBlockReturnType[] | undefined = [];
      let proposalsFull: Proposal[] | undefined = [];

      proposals = await getProposals(address)
      // console.log("fetchProposals called, waypoint 2: ", {proposals})
      if (proposals && proposals.length > 0) {
        states = await getProposalsState(proposals, address)
        blocks = await getBlockData(proposals, address)
      } 
      // console.log("@fetchProposals: waypoint 2", {states, blocks})
      if (states && blocks) { // + votes later.. 
        proposalsFull = proposals?.map((proposal, index) => {
          return ( 
            {...proposal, state: states[index], voteStartBlockData: {...blocks[index], chainId: sepolia.id}}
          )
        })
      }  
      // console.log("@fetchProposals: waypoint 3", {proposalsFull})
      // console.log("fetchProposals called, waypoint 4: ", {proposalsFull})
      // return data - to be saved in local storage. 
      return proposalsFull
  }, [ ]) 


  const fetchPowers = useCallback(
    async () => {
      console.log("@fetchPowers, waypoint 1", {address})
      setStatus("pending")
      const powersToFetch = await checkLocalStorage(address)
      console.log("@fetchPowers, waypoint 2", {powersToFetch})
      if (powersToFetch != undefined) {
        setPowers(powersToFetch)
      } else {
        console.log("@fetchPowers, waypoint 3", {address})
        const names = await fetchName(address)
        console.log("@fetchPowers, waypoint 4: ", {names})
        const metadatas = await fetchMetaData(address)
        console.log("@fetchPowers, waypoint 5: ", {metadatas})
        const lawsAndRoles = await fetchLawsAndRoles(address)
        console.log("@fetchPowers, waypoint 6: ", {lawsAndRoles})
        // const proposals = await fetchProposals(address)
        // console.log("@fetchPowers, waypoint 7: ", {proposals})
        const roleLabels = await fetchRoleLabels(address)
        console.log("@fetchPowers, waypoint 8: ", {roleLabels})

        // console.log("waypoint 4: data fetched: ", {names, metadatas, lawsAndRoles, proposalsPerOrg, roleLabels})
        if (names && metadatas && lawsAndRoles && roleLabels) { //  proposals &&
            const powersFetched = {
              contractAddress: address,
              name: names, 
              metadatas: metadatas, 
              colourScheme: 0, // TODO: make dynamic. 
              laws: lawsAndRoles.laws, 
              activeLaws: lawsAndRoles.activeLaws, 
              proposals: [], // proposals, 
              roles: lawsAndRoles.roles, 
              roleLabels: roleLabels
            }
            console.log("@fetchPowers, waypoint 9: ", {powersFetched})
            // when multiple components are calling this function at the same time, we need to make sure they do not create separate instances of the same Powers. 
            let localStore = localStorage.getItem("powersProtocols")
            const saved: Powers[] = localStore ? JSON.parse(localStore) : []
            const powersToUpdate = saved.find(item => item.contractAddress == address)
            console.log("@fetchPowers, waypoint 10: ", {powersToUpdate})
            if (powersToUpdate) {
              const allPowers = saved.map(powers => powers.contractAddress == address ? powersFetched : powers)
              localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
                typeof value === "bigint" ? value.toString() : value,
              ));
              console.log("@fetchPowers, waypoint 11: ", {allPowers})
            } else {
              const allPowers = [...saved, powersFetched]
              localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
                typeof value === "bigint" ? value.toString() : value,
              ));
              console.log("@fetchPowers, waypoint 12: ", {powersFetched})
            }
            setPowers(powersFetched)
            console.log("@fetchPowers, waypoint 13: ", {powersFetched})
          }     
      }

      console.log("@fetchPowers, waypoint 14")
      setStatus("success")
    }, []
  )
    
  const updatePowers = useCallback(
    // updates laws, roles and proposal info of an existing Powers or fetches a new Powers - and stores it in local storage.  
    async (address: `0x${string}`) => {
      setStatus("pending")
      // console.log("@updateOrg: TRIGGERED")

      let localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore ? JSON.parse(localStore) : []
      const powersToUpdate = saved.find(item => item.contractAddress == address)

      // console.log("@updatePowers: waypoint 1", {powersToUpdate})
      
      if (powersToUpdate) {
        const lawsAndRoles = await fetchLawsAndRoles(address)
        const roleLabels = await fetchRoleLabels(address)
        const proposals = await fetchProposals(address)

        // console.log("@updatePowers: waypoint 2", {lawsAndRoles, roleLabels, proposals})

        if (lawsAndRoles && proposals && roleLabels) {
          const updatedPowers = 
          { ...powersToUpdate,  
            laws: lawsAndRoles.laws, 
            activeLaws: lawsAndRoles.activeLaws, 
            proposals: proposals, 
            roles: lawsAndRoles.roles, 
            roleLabels: roleLabels
          }

          // console.log("@updatePowers: waypoint 3", {updatedPowers})

          const updatedPowersArray: Powers[] = saved.map(
            powers => powers.contractAddress == updatedPowers.contractAddress ? updatedPowers : powers
          )

          // console.log("@updatePowers: waypoint 4", {updatedPowersArray})
        
          localStorage.setItem("powersProtocols", JSON.stringify(updatedPowersArray, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ));

          setPowers(updatedPowers)

          // console.log("@updatePowers: waypoint 5")
        }
      } else {
        setStatus("error")
        setError("Powers not found")
      }

      setStatus("success")
      }, []
    )

    const updateProposals = useCallback(
      async (address: `0x${string}`) => {
        setStatus("pending")
        // console.log("@updateOrg: TRIGGERED")
  
        let localStore = localStorage.getItem("powersProtocols")
        const saved: Powers[] = localStore ? JSON.parse(localStore) : []
        const powersToUpdate = saved.find(item => item.contractAddress == address)

        if (powersToUpdate) {
          const proposals = await fetchProposals(address)
          const updatedPowers = 
          { ...powersToUpdate,  
            proposals: proposals
          }

          const updatedPowersArray: Powers[] = saved.map(
            powers => powers.contractAddress == updatedPowers.contractAddress ? updatedPowers : powers
          )
          localStorage.setItem("powersProtocols", JSON.stringify(updatedPowersArray, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ));

          setPowers(updatedPowers)

          setStatus("success")
        } else {
          setStatus("error")
          setError("Powers not found")
        }
      }, []
    )

  return {status, error, powers, fetchPowers, updatePowers, updateProposals}
}