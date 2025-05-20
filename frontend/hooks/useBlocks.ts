// ok, what does this need to do? 

import { Status } from "@/context/types"
import { useState } from "react"
import { GetBlockReturnType } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig"
import { getBlock } from "wagmi/actions";

export const useBlocks = (blockNumbers: bigint[]) => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [data, setData] = useState<GetBlockReturnType[]>()
  
   const fetchBlocks = async (blockNumbers: bigint[]) => {
    setStatus("pending")

    let blockNumber: bigint
    let blocks: GetBlockReturnType[] = [] 

    for await (blockNumber of blockNumbers) {
        try {
            // console.log("@useAssets, fetching token: ", token) 
            const block = await getBlock(wagmiConfig, {
                blockNumber: blockNumber
            })
            blocks.push(block as GetBlockReturnType)
        } catch (error) {
            setStatus("error") 
            setError({error})
        }
    } 
    setData(blocks)
    setStatus("success")
  }

  return {status, error, data, fetchBlocks }
}