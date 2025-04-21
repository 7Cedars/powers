import { Status, Proposal, Organisation, Law, Metadata, RoleLabel } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients"; 
import { readContract } from "wagmi/actions";
import { supportedChains } from "@/context/chains";
import { useChainId } from 'wagmi'
import { assignOrg } from "@/context/store";
import { parseMetadata } from "@/utils/parsers";

type LawsAndRoles = { 
    laws: Law[]; 
    activeLaws: Law[];
    roles: bigint[];
  }

export const useOrganisations = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [organisations, setOrganisations] = useState<Organisation[] | undefined>() 
  const chainId = useChainId()
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const fetchNames = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let names: string[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
              const name = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: organisation.contractAddress,
                functionName: 'name'
              })
              names.push(name as string)
            }
          return names
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

  const fetchMetaDatas = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let metadatas: Metadata[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          const uri = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: organisation.contractAddress,
            functionName: 'uri'
          })

          if (uri) {
            const fetchedMetadata: unknown = await(
              await fetch(uri as string)
              ).json()
              metadatas.push(parseMetadata(fetchedMetadata)) 
            } 
          }
          return metadatas
        } 
          catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

  const fetchLawsAndRoles = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let law: Law
    let lawsAndRoles: LawsAndRoles[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          // fetching all laws ever initiated by the org
          if (organisation?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              abi: lawAbi, 
              eventName: 'Law__Initialized',
              fromBlock: supportedChain?.genesisBlock,
              args: {
                powers: organisation.contractAddress as `0x${string}`
              }
            })
            const fetchedLogs = parseEventLogs({
              abi: lawAbi,
              eventName: 'Law__Initialized',
              logs
            })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            let fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)
            fetchedLaws = fetchedLogsTyped.map(log => ({...log.args as Law, lawAddress: log.address}))
            fetchedLaws.sort((a: Law, b: Law) => Number(a.index) > Number(b.index) ? 1 : -1)

            // fetching active laws
            let activeLaws: Law[] = []
            if (fetchedLaws) {
              for await (law of fetchedLaws) {
                const activeLaw = await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress,
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
              lawsAndRoles.push({laws: fetchedLaws, activeLaws: activeLaws, roles: fetchedRoles})
            }
          }
        } 
        return lawsAndRoles
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchRoleLabels = async (organisations: Organisation[]) => {
    // console.log("@fetchRoleLabels, waypoint 1", {organisations})
    let organisation: Organisation

    if (publicClient) {
      try {
        for await (organisation of organisations) {
            // console.log("@fetchRoleLabels, waypoint 2", {organisation})
            const logs = await publicClient.getContractEvents({ 
              abi: powersAbi, 
              address: organisation.contractAddress as `0x${string}`, 
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
          }
          return null 
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

  const fetchProposals = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let proposalsPerOrg: Proposal[][] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          if (organisation?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              address: organisation.contractAddress as `0x${string}`,
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
              proposalsPerOrg.push(fetchedProposals)
            }
          }
        } 
        return proposalsPerOrg
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchOrgs = useCallback(
    async () => {
      setStatus("pending")
      // console.log("waypoint 3: fetchOrgs called")

      const defaultOrganisations = supportedChain?.organisations?.map(org => { return ({
        contractAddress: org
        }) as Organisation }
      )
      // console.log("waypoint 3: data fetched: ", {defaultOrganisations})

      if (defaultOrganisations) {
        const names = await fetchNames(defaultOrganisations)
        const metadatas = await fetchMetaDatas(defaultOrganisations)
        const lawsAndRoles = await fetchLawsAndRoles(defaultOrganisations)
        const proposalsPerOrg = await fetchProposals(defaultOrganisations)
        const roleLabels = await fetchRoleLabels(defaultOrganisations)

        // console.log("waypoint 4: data fetched: ", {names, metadatas, lawsAndRoles, proposalsPerOrg, roleLabels})

        if (names && metadatas && lawsAndRoles && proposalsPerOrg && roleLabels) {
            const organisationsFetched = defaultOrganisations?.map((org, index) => {
              return ( 
                { ...org, 
                  name: names[index], 
                  metadatas: metadatas[index], 
                  colourScheme: index, 
                  laws: lawsAndRoles[index].laws, 
                  activeLaws: lawsAndRoles[index].activeLaws, 
                  proposals: proposalsPerOrg[index], 
                  roles: lawsAndRoles[index].roles, 
                  roleLabels: roleLabels
                }
              )
            })

            // console.log("waypoint 5: ", {organisationsFetched})
            setOrganisations(organisationsFetched)
            localStorage.setItem("powersProtocol_savedOrgs", JSON.stringify(organisationsFetched, (key, value) =>
              typeof value === "bigint" ? Number(value) : value,
            ));
          }  
        }

        // console.log("waypoint 8")
        setStatus("success")
      }, []
    )

  const initialise = () => {
      // checks if orgs are stored in memory. If so, it does not query api and only reads from local storage.  
      // console.log("waypoint 1: initialise called")
      setStatus("pending")
      let localStore = localStorage.getItem("powersProtocol_savedOrgs")
      const saved: Organisation[] = localStore ? JSON.parse(localStore) : []
      // console.log("waypoint 2: local storage queried:", {saved})

      saved.length == 0 ? fetchOrgs() : setOrganisations(saved)
      setStatus("success")  
    } 

    
  const updateOrg = useCallback(
    // updates laws, roles and proposal info of an existing organisation or fetches a new organisation - and stores it in local storage.  
    async (organisation: Organisation) => {
      setStatus("pending")
      // console.log("@updateOrg: TRIGGERED")

      let localStore = localStorage.getItem("powersProtocol_savedOrgs")
      const saved: Organisation[] = localStore ? JSON.parse(localStore) : []
      const orgToUpdate = saved.find(item => item.contractAddress == organisation.contractAddress) 
      
      if (orgToUpdate) {
        const lawsAndRoles = await fetchLawsAndRoles([organisation])
        const roleLabels = await fetchRoleLabels([organisation])
        const proposalsPerOrg = await fetchProposals([organisation])

        if (lawsAndRoles && proposalsPerOrg && roleLabels) {
          const updatedOrg = 
          { ...orgToUpdate,  
            laws: lawsAndRoles[0].laws, 
            activeLaws: lawsAndRoles[0].activeLaws, 
            proposals: proposalsPerOrg[0], 
            roles: lawsAndRoles[0].roles, 
            roleLabels: roleLabels
          }
          
          const updatedOrgs: Organisation[] = saved.map(
            org => org.contractAddress == updatedOrg.contractAddress ? updatedOrg : org
          )

          assignOrg(updatedOrg)
          setOrganisations(updatedOrgs)
          localStorage.setItem("powersProtocol_savedOrgs", JSON.stringify(updatedOrgs, (key, value) =>
            typeof value === "bigint" ? Number(value) : value,
          ));
        }
      } else {
        setStatus("error")
        setError("Organisation not found")
      }

      setStatus("success")
      }, []
    )


  const addOrg = useCallback(
    // updates laws, roles and proposal info of an existing organisation or fetches a new organisation - and stores it in local storage.  
    async (protocol: `0x${string}`) => {
      setStatus("pending")

      let localStore = localStorage.getItem("powersProtocol_savedOrgs")
      const saved: Organisation[] = localStore ? JSON.parse(localStore) : [] 
      const organisationToFetch = {contractAddress: protocol} as Organisation 

      if (organisationToFetch) {
        const names = await fetchNames([organisationToFetch])
        const metadatas = await fetchMetaDatas([organisationToFetch])
        const lawsAndRoles = await fetchLawsAndRoles([organisationToFetch])
        const roleLabels = await fetchRoleLabels([organisationToFetch])
        const proposalsPerOrg = await fetchProposals([organisationToFetch])

        // console.log("@AddOrg, data fetched: ", {names, metadatas, lawsAndRoles, proposalsPerOrg})

        if (names && metadatas && lawsAndRoles && proposalsPerOrg && roleLabels) {
            const organisationFetched = 
                { ...organisationToFetch, 
                  name: names[0], 
                  metadatas: metadatas[0], 
                  colourScheme: saved.length + 1, 
                  laws: lawsAndRoles[0].laws, 
                  activeLaws: lawsAndRoles[0].laws, 
                  proposals: proposalsPerOrg[0], 
                  roles: lawsAndRoles[0].roles, 
                  roleLabels: roleLabels
                }  

            // console.log("@AddOrg", {organisationFetched})
            const allOrgs = [...saved, organisationFetched]
            setOrganisations(allOrgs)
            localStorage.setItem("powersProtocol_savedOrgs", JSON.stringify(allOrgs, (key, value) =>
              typeof value === "bigint" ? Number(value) : value,
            ));
          }  
        }
        setStatus("success")
      }, []
    )


  return {status, error, organisations, initialise, fetchOrgs, addOrg, updateOrg}
}