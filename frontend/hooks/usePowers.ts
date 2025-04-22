import { Status, Proposal, Powers, Law, Metadata, RoleLabel } from "../context/types"
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients"; 
import { readContract } from "wagmi/actions";
import { supportedChains } from "@/context/chains";
import { useChainId } from 'wagmi'
import { bytesToParams, parseMetadata } from "@/utils/parsers";

export const usePowers = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [powers, setPowers] = useState<Powers | undefined>() 
  const chainId = useChainId()
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const checkLocalStorage = async (address: `0x${string}`) => {
    let localStore = localStorage.getItem("powersProtocols")
    const saved: Powers[] = localStore ? JSON.parse(localStore) : []
    const powersToFetch = saved.find(item => item.contractAddress == address) 

    if (powersToFetch) {
      return powersToFetch
    }
  }

  const fetchName = async (address: `0x${string}`) => {
    if (publicClient) {
      try {
        const name = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: address,
          functionName: 'name'
        })
        return name as string
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

  const fetchMetaData = async (address: `0x${string}`) => {
    if (publicClient) {
      try {
        const uri = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: address,
          functionName: 'uri'
          })

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

    if (publicClient) {
      try {
        // fetching all laws ever initiated by the org
        if (address) {
          const logs = await publicClient.getContractEvents({ 
            abi: lawAbi, 
            eventName: 'Law__Initialized',
            fromBlock: supportedChain?.genesisBlock,
            args: {
              powers: address as `0x${string}`
              }
            })
            const fetchedLogs = parseEventLogs({
              abi: lawAbi,
              eventName: 'Law__Initialized',
              logs
            })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            let fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)
            fetchedLaws = fetchedLogsTyped.map(log => (
              {
                ...log.args as Law, 
                lawAddress: log.address, 
              }))
            fetchedLaws.forEach(law => {
              law.params = bytesToParams(law.inputParams as `0x${string}`)
            })
            fetchedLaws.sort((a: Law, b: Law) => Number(a.index) > Number(b.index) ? 1 : -1)

            // fetching active laws
            let activeLaws: Law[] = []
            if (fetchedLaws) {
              for await (law of fetchedLaws) {
                const activeLaw = await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: address,
                  functionName: 'getActiveLaw', 
                  args: [law.index]
                })
                const active = activeLaw as boolean
                if (active) activeLaws.push(law)
              }
            } 
            // calculating roles
            const rolesAll = activeLaws.map((law: Law) => law.conditions.allowedRole)
            const fetchedRoles = [... new Set(rolesAll)] as bigint[]
          
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

  const fetchProposals = async (address: `0x${string}`) => {
    if (publicClient) {
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
        const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
        fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart  > b.voteStart ? 1 : -1)
        if (fetchedProposals) {
          return fetchedProposals
        }
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchPowers = useCallback(
    async (address: `0x${string}`) => {
      setStatus("pending")
      const powersToFetch = await checkLocalStorage(address)
      if (powersToFetch) {
        setPowers(powersToFetch)
      } else {

        const names = await fetchName(address)
        const metadatas = await fetchMetaData(address)
        const lawsAndRoles = await fetchLawsAndRoles(address)
        const proposalsPerOrg = await fetchProposals(address)
        const roleLabels = await fetchRoleLabels(address)

        // console.log("waypoint 4: data fetched: ", {names, metadatas, lawsAndRoles, proposalsPerOrg, roleLabels})
        if (names && metadatas && lawsAndRoles && proposalsPerOrg && roleLabels) {
            const powersFetched = {
              contractAddress: address,
              name: names, 
              metadatas: metadatas, 
              colourScheme: 0, // TODO: make dynamic. 
              laws: lawsAndRoles.laws, 
              activeLaws: lawsAndRoles.activeLaws, 
              proposals: proposalsPerOrg, 
              roles: lawsAndRoles.roles, 
              roleLabels: roleLabels
            }

            let localStore = localStorage.getItem("powersProtocols")
            const saved: Powers[] = localStore ? JSON.parse(localStore) : []
            const allPowers = [...saved, powersFetched]
            localStorage.setItem("powersProtocols", JSON.stringify(allPowers, (key, value) =>
              typeof value === "bigint" ? Number(value) : value,
            ));
            setPowers(powersFetched)
          }  
      }

      // console.log("waypoint 8")
      setStatus("success")
    }, []
  )
    
  const updatePowers = useCallback(
    // updates laws, roles and proposal info of an existing Powers or fetches a new Powers - and stores it in local storage.  
    async (address: `0x${string}`) => {
      setStatus("pending")
      // console.log("@updateOrg: TRIGGERED")

      let localStore = localStorage.getItem("powersProtocol")
      const saved: Powers[] = localStore ? JSON.parse(localStore) : []
      const powersToUpdate = saved.find(item => item.contractAddress == address) 
      
      if (powersToUpdate) {
        const lawsAndRoles = await fetchLawsAndRoles(address)
        const roleLabels = await fetchRoleLabels(address)
        const proposalsPerOrg = await fetchProposals(address)

        if (lawsAndRoles && proposalsPerOrg && roleLabels) {
          const updatedPowers = 
          { ...powersToUpdate,  
            laws: lawsAndRoles.laws, 
            activeLaws: lawsAndRoles.activeLaws, 
            proposals: proposalsPerOrg, 
            roles: lawsAndRoles.roles, 
            roleLabels: roleLabels
          }
          
          const updatedPowersArray: Powers[] = saved.map(
            powers => powers.contractAddress == updatedPowers.contractAddress ? updatedPowers : powers
          )

          localStorage.setItem("powersProtocol", JSON.stringify(updatedPowersArray, (key, value) =>
            typeof value === "bigint" ? Number(value) : value,
          ));
        }
      } else {
        setStatus("error")
        setError("Powers not found")
      }

      setStatus("success")
      }, []
    )

  return {status, error, powers, fetchPowers, updatePowers}
}