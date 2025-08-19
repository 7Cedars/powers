import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Law, LawExecutions } from "../context/types"
import { getConnectorClient, readContract, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { usePrivy } from "@privy-io/react-auth";
import { setError } from "../context/store";

export const useLaw = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>()
  const [executions, setExecutions ] = useState<LawExecutions>()
 
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

  const fetchExecutions = useCallback( 
    async (law: Law) => {
      // console.log("@simulate: waypoint 1", {caller, lawCalldata, nonce, law})
      setError(null)
      setStatus("pending")
      try {
          const result = await readContract(wagmiConfig, {
            abi: lawAbi,
            address: law.lawAddress as `0x${string}`,
            functionName: 'getExecutions', 
            args: [law.powers, law.index]
            })
          // console.log("@fetchExecutions: waypoint 2a", {result})
          setExecutions(result as unknown as LawExecutions)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          setError(error)
          setError(error)
          // console.log(error)
        }
        setStatus("idle")
  }, [ ])
  

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
          setError(error)
          // console.log(error)
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
        // console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError(null)
        setStatus("pending")
        try {
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: law.powers as `0x${string}`,
            functionName: 'request',
            args: [law.index, lawCalldata, nonce, description]
          })

          // console.log("@execute: waypoint 1", {request})
          const client = await getConnectorClient(wagmiConfig)
          // console.log("@execute: waypoint 2", {client})
          
          if (request) {
            // console.log("@execute: waypoint 3", {request})
            const result = await writeContract(wagmiConfig, request)
            setTransactionHash(result)
            // console.log("@execute: waypoint 4", {result})
          }
        } catch (error) {
          setStatus("error") 
          setError(error)
          setError(error)
          // console.log("@execute: waypoint 5", {error}) 
      }
  }, [ ])

  return {status, error, executions, simulation, resetStatus, simulate, execute, fetchExecutions}
}