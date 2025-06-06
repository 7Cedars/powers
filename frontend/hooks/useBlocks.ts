// ok, what does this need to do? 

import { Status } from "@/context/types"
import { useCallback, useEffect, useState } from "react"
import { GetBlockReturnType } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig"
import { getBlock } from "wagmi/actions";
import { parseChainId } from "@/utils/parsers";
import { toEurTimeFormat } from "@/utils/toDates";
import { toFullDateFormat } from "@/utils/toDates";

type BlockTimestamp = {
  chainId: string
  blockNumber: bigint
  timestamp: bigint
}

// Helper functions for bigint serialization
const bigintReplacer = (key: string, value: any) =>
  typeof value === "bigint" ? value.toString() : value

const bigintReviver = (key: string, value: any) =>
  typeof value === "string" && /^\d+$/.test(value) && (key === "blockNumber" || key === "timestamp")
    ? BigInt(value)
    : value

// Helper function to safely load timestamps from localStorage
const loadTimestampsFromStorage = (): Map<string, BlockTimestamp> => {
  try {
    const localStore = localStorage.getItem("blockTimestamps")
    console.log("@useBlocks, raw localStorage data: ", localStore)
    
    if (!localStore) {
      return new Map()
    }
    
    const parsed = JSON.parse(localStore, bigintReviver)
    console.log("@useBlocks, parsed data: ", parsed)
    
    // Ensure parsed data is an array
    if (!Array.isArray(parsed)) {
      console.warn("@useBlocks, localStorage data is not an array, clearing...")
      localStorage.removeItem("blockTimestamps")
      return new Map()
    }
    
    return new Map(parsed)
  } catch (error) {
    console.error("@useBlocks, error loading from localStorage: ", error)
    localStorage.removeItem("blockTimestamps") // Clear corrupted data
    return new Map()
  }
}

export const useBlocks = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [timestamps, setTimestamps] = useState<Map<string, BlockTimestamp>>(new Map())
  
  const fetchTimestamps = useCallback(
    async (blockNumbers: bigint[], chainId: string) => {
      console.log("@useBlocks, fetching timestamp: ", blockNumbers, chainId)
      setStatus("pending")
      setError(null)

      const saved = loadTimestampsFromStorage()
      console.log("@useBlocks, loaded saved: ", saved)

      for (const blockNumber of blockNumbers) {
        if (saved.size == 0 || saved.get(`${chainId}:${blockNumber}`) == undefined) {
          try {
            const block = await getBlock(wagmiConfig, {
              blockNumber: BigInt(blockNumber),
              chainId: parseChainId(chainId)
            })
            const blockParsed = block as GetBlockReturnType
            saved.set(`${chainId}:${blockNumber}`, {chainId, blockNumber, timestamp: blockParsed.timestamp})
            
            try {
              localStorage.setItem("blockTimestamps", JSON.stringify(Array.from(saved.entries()), bigintReplacer))
            } catch (storageError) {
              console.error("@useBlocks, error saving to localStorage: ", storageError)
            }
          } catch (error) {
            console.error("@useBlocks, error: ", error)
            setStatus("error")
            setError(error)
            return
          }
        }
      }
      setStatus("success")
    }, 
    []
  )

  useEffect(() => {
    if (status == "success") {
      const saved = loadTimestampsFromStorage()
      setTimestamps(saved)
    }
  }, [status])
  
  return { status, error, timestamps, fetchTimestamps }
}