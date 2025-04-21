import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Execution, LogExtended } from "../context/types"
import { getBlock, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useChainId, useWaitForTransactionReceipt } from "wagmi";
import { useLawStore, useOrgStore } from "@/context/store";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { GetBlockReturnType, keccak256, Log, parseEventLogs, ParseEventLogsReturnType, toHex } from "viem";
import { supportedChains } from "@/context/chains";
import { sepolia } from "@wagmi/core/chains";

export const useLaw = () => {
  const organisation = useOrgStore()
  const law = useLawStore()
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
 
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>()
  const [executions, setExecutions ] = useState<Execution[]>()
 
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
 
  const fetchExecutions = async () => {
    let log: Log
    let blocksData: GetBlockReturnType[] = []
    let executions2: Execution[] = []

    if (publicClient) {
      try {
          if (organisation?.contractAddress) {
            
            // fetching executions
            const logs = await publicClient.getContractEvents({ 
              address: organisation.contractAddress as `0x${string}`,
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

  const fetchSimulation = useCallback( 
    async (caller: `0x${string}`, lawCalldata: `0x${string}`, nonce: bigint) => {
      setError(null)
      setStatus("pending")
      try {
        const result = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.lawAddress,
          functionName: 'handleRequest', 
          args: [caller, law.index, lawCalldata, nonce]
        })
          setSimulation(result as LawSimulation)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          setError(error)
          console.log(error)
        }
        setStatus("idle") // immediately reset status
  }, [ ])

  const execute = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      description: string
    ) => {
        setError(null)
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: powersAbi,
            address: organisation.contractAddress,
            functionName: 'request', 
            args: [targetLaw, lawCalldata, keccak256(toHex((description))), description]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
          console.log(error)
      }
  }, [ ])

  return {status, error, executions, simulation, resetStatus, fetchSimulation, fetchExecutions, execute}
}

