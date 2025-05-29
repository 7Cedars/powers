// ok, what does this need to do? 

import { Status } from "@/context/types"
import { useEffect, useState } from "react"
import { GetBlockReturnType } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig"
import { getBlock } from "wagmi/actions";
import { parseChainId } from "@/utils/parsers";

export const useBlocks = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [data, setData] = useState<GetBlockReturnType[]>()

  console.log("@useBlocks, data: ", data)

  const fetchBlocks = async (blockNumbers: bigint[], chainId: string) => {
    setStatus("pending")
    // console.log("@useBlocks, fetching blocks: ", blockNumbers, chainId)

    let blockNumber: bigint
    let blocks: GetBlockReturnType[] = [] 

    for await (blockNumber of blockNumbers) {
        try {
            // console.log("@useBlocks, fetching block: ", blockNumber, chainId) 
            const block = await getBlock(wagmiConfig, {
                blockNumber: BigInt(blockNumber),
                chainId: parseChainId(chainId)
            })
            // console.log("@useBlocks, fetched block: ", block)
            blocks.push(block as GetBlockReturnType)
        } catch (error) {
            // console.log("@useBlocks, error: ", error)
            setStatus("error") 
            setError({error})
        } 
    } 
    setData(blocks)
    setStatus("success")
  }

  return { status, error, data, fetchBlocks }
}