import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Execution, LogExtended, Law } from "../context/types"
import { getBlock, readContract, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { getPublicClient } from "wagmi/actions";
// import { readContract } from "";
import { GetBlockReturnType, keccak256, Log, parseEventLogs, ParseEventLogsReturnType, toHex } from "viem";
import { supportedChains } from "@/context/chains";
import { sepolia } from "@wagmi/core/chains";
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";

export const useLaw = () => {
  const { chainId } = useParams<{ chainId: string }>()
  const supportedChain = supportedChains.find(chain => chain.id == parseChainId(chainId))
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId)
  })
 
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>()
  const [executions, setExecutions ] = useState<Execution[]>()

  // console.log("@useLaw: waypoint 1", {status, error, simulation, executions})
 
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })
 
  useEffect(() => {
    if (statusReceipt === "success") setStatus("success")
    if (statusReceipt === "error") setStatus("error")
  }, [statusReceipt])

  // reset // 
  const resetStatus = () => {
    setStatus("idle")
    setError(null)
    setTransactionHash(undefined)
  }
 
  const fetchExecutions = async (law: Law) => {
    let log: Log
    let executions2: Execution[] = []

    if (publicClient) {
      try {
          if (law?.lawAddress) {
            
            // fetching executions
            const logs = await publicClient.getContractEvents({ 
              address: law.powers as `0x${string}`,
              abi: powersAbi, 
              eventName: 'ActionRequested',
              fromBlock: supportedChain?.genesisBlock,
              args: {lawId: law.index}
            })
            const fetchedLogs = parseEventLogs({
                        abi: powersAbi,
                        eventName: 'ActionRequested',
                        logs
                      })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType  
            fetchedLogsTyped.sort((a: Log, b: Log) => (
              a.blockNumber ? Number(a.blockNumber) : 0
            ) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)
            
            // fetching blockdata
            if (fetchedLogsTyped.length > 0) {
              for await (log of fetchedLogsTyped) {
                if (log.blockNumber) {
                  const fetchedBlockData = await getBlock(wagmiConfig, {
                    blockNumber: log.blockNumber
                  })
                  if (fetchedBlockData) {
                    executions2.push({
                      log: log as LogExtended, 
                      blocksData: {...fetchedBlockData, chainId: sepolia.id} 
                    })
                  }
                } 
              } 
            }
            setExecutions(executions2)
          } 
      } catch (error) {
        setStatus("error") 
        setError(error)
        console.log(error)
      }
    }
  }

  const simulate = useCallback( 
    async (caller: `0x${string}`, lawCalldata: `0x${string}`, nonce: bigint, law: Law) => {
      // console.log("@simulate: waypoint 1", {caller, lawCalldata, nonce, law})
      setError(null)
      setStatus("pending")
      try {
          const result = await readContract(wagmiConfig, {
            abi: lawAbi,
            address: law.lawAddress as `0x${string}`,
            functionName: 'handleRequest', 
            args: [caller, law.powers, law.index, lawCalldata, nonce]
            })
          // console.log("@simulate: waypoint 2a", {result})
          // console.log("@simulate: waypoint 2b", {result: result as LawSimulation})
          setSimulation(result as LawSimulation)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          setError(error)
          console.log(error)
        }
        setStatus("idle")
  }, [ ])

  const execute = useCallback( 
    async (
      law: Law,
      lawCalldata: `0x${string}`,
      nonce: bigint,
      description: string
    ) => {
        console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError(null)
        setStatus("pending")
        try {
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: law.powers as `0x${string}`,
            functionName: 'request',
            args: [law.index, lawCalldata, nonce, "simulation"]
          })

          console.log("@execute: waypoint 1", {request})
          
          if (request) {
            const result = await writeContract(wagmiConfig, {
              abi: powersAbi,
              address: law.powers as `0x${string}`,
              functionName: 'request', 
              args: [law.index, lawCalldata, nonce, description]
            })
            setTransactionHash(result)
            console.log("@execute: waypoint 3", {result})
          }
        } catch (error) {
          setStatus("error") 
          setError(error)
          console.log("@execute: waypoint 4", {error}) 
      }
  }, [ ])

  return {status, error, executions, simulation, resetStatus, simulate, fetchExecutions, execute}
}

