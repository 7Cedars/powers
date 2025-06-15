// ok, what does this need to do? 

import { erc1155Abi, erc20Abi, erc721Abi, ownableAbi } from "@/context/abi"
// import { publicClient } from "@/context/clients"
import { Powers, Status, Token } from "@/context/types"
import { useCallback, useState } from "react"
import { useBalance, useChains } from "wagmi"
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig"
import { parse1155Metadata } from "@/utils/parsers"
import { useParams } from "next/navigation";
import { parseChainId } from "@/utils/parsers";

export const useAssets = (powers: Powers | undefined) => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [tokens, setTokens] = useState<Token[]>()
  const { chainId } = useParams<{ chainId: string }>()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const {data: native, status: statusBalance}  = useBalance({
    address: powers?.contractAddress
  }) 
  // console.log("@useAssets, supportedChain:", {supportedChain, tokens, status, error})

   const fetchErc20Or721 = async (tokenAddresses: `0x${string}`[], type: "erc20" | "erc721", powers: Powers) => {
     let token: `0x${string}`
     let tokens: Token[] = [] 
 
    //  if (publicClient) {
         for await (token of tokenAddresses) {
          try {
            // console.log("@useAssets, fetching token: ", token) 
            const name = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'name' 
            })
            const nameParsed = name as string
            // console.log("@useAssets, nameParsed:", {nameParsed})

            const symbol = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'symbol' 
            })
            const symbolParsed = symbol as string
            // console.log("@useAssets, symbolParsed:", {symbolParsed})

            const balance = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'balanceOf', 
              args: [powers.contractAddress] 
            })
            const balanceParsed = balance as bigint
            // console.log("@useAssets, balanceParsed:", {balanceParsed})

            let decimalParsed: bigint = 8n
            if ( type == "erc20") {
              const decimal = await readContract(wagmiConfig, {
                abi: erc20Abi,
                address: token,
                functionName: 'decimals'
              })
              decimalParsed = decimal as bigint
            }
          

            // console.log("@useAssets, decimalParsed:", {decimalParsed})

            // NB! still need to include a conditional decimal check for ERC20s. 

            if (nameParsed && symbolParsed && balanceParsed != undefined && type == "erc721") {
              tokens.push({
                name: nameParsed,
                symbol: symbolParsed, 
                balance: balanceParsed,
                address: token,
                type: type
              })
            }

            if (nameParsed && symbolParsed && balanceParsed != undefined && decimalParsed && type == "erc20") {
              tokens.push({
                name: nameParsed,
                symbol: symbolParsed, 
                balance: balanceParsed,
                decimals: decimalParsed, 
                address: token,
                type: type
              })
            }

            // console.log("@useAssets, end of fetchErc20Or721:", {tokens, nameParsed, symbolParsed, balanceParsed, decimalParsed, type})
         } catch (error) {
          setStatus("error") 
          setError({error, token})
          // console.log("@useAssets, error:", {error, token})
         }
       } 
    // } 
    return tokens
  }


  const fetch1155s = async (erc1155Addresses: `0x${string}`[]) => {
    let token: `0x${string}`
    let erc1155s: Array<Token> = []
    const Ids = 10 // this hook checks the first 50 tokens Ids for a balance. 
    const IdsToCheck: bigint[] = new Array(Ids).fill(null).map((_, i) => BigInt(i + 1));
    

    // if (publicClient) {
        for await (token of erc1155Addresses) {
          try {
           const AccountsToCheck: `0x${string}`[] = new Array(Ids).fill(token);
           // console.log({AccountsToCheck})
           const balancesRaw = await readContract(wagmiConfig, {
             abi: erc1155Abi,
             address: token,
             functionName: 'balanceOfBatch', 
             args: [AccountsToCheck, IdsToCheck] 
           })
           const balancesParsed: bigint[] = balancesRaw as bigint[]
           
           // console.log({balancesRaw, balancesParsed})

           let erc1155 = balancesParsed.map((balance, index) => {
            if (Number(balance) > 0) return ({
              tokenId: index, 
              balance: balance,
              address: token
            })
           })
           const result: Token[] = erc1155.filter(token => token != undefined)
           erc1155s = result ? [...erc1155s, ...result] : erc1155s
           // console.log({erc1155s})     
        } catch (error) {
          setStatus("error") 
          setError({token, error})
        }
        return erc1155s
      // } 
    }
  }

  const fetch1155Metadata = async (erc1155s: Token[]) => {
    let token: Token
    let erc1155sMetadata: Token[] = []

    // if (publicClient) {
      try {
        for await (token of erc1155s) {
          if (powers?.contractAddress && token.address) {
           const uriRaw = await readContract(wagmiConfig, {
             abi: erc1155Abi,
             address: token.address as `0x${string}`,
             functionName: 'uri', 
             args: [token.tokenId] 
            })
           
             if (uriRaw) {
                const fetchedMetadata: unknown = await(
                  await fetch(uriRaw as string)
                  ).json()
                  const metadata = parse1155Metadata(fetchedMetadata)
                  erc1155sMetadata.push({
                    ...token, 
                    name: metadata.name,
                    symbol: metadata.symbol
                  })
                }
              }
            } return erc1155sMetadata
          } catch (error) {
          setStatus("error") 
          setError(error)
        // }
      }
  }

  const fetchvalueNative = async ( ) => {
    // £todo later
  }

  const fetchErc1155 = async (erc1155Addresses: `0x${string}`[]) => {
    let results: Token[] | undefined  

    const active1155Tokens = await fetch1155s(erc1155Addresses)
    if (active1155Tokens) {
      results = await fetch1155Metadata(active1155Tokens) 
      
    } 
    return results 
  } 

  const fetchTokens = useCallback( 
    async (powers: Powers) => {
        setStatus("pending")
        setError(null)
        const savedErc20s = JSON.parse(localStorage.getItem("powersProtocol_savedErc20s") || "[]")
        const selectedErc20s = powers?.metadatas?.erc20s ? powers?.metadatas?.erc20s : []
        // console.log("@useAssets, savedErc20s:", {savedErc20s})
        // console.log("@useAssets, selectedErc20s:", {selectedErc20s})
        const erc20s: Token[] = await fetchErc20Or721([...selectedErc20s, ...savedErc20s], "erc20", powers)
        // console.log("@useAssets, erc20s:", {erc20s})
        // const erc721s: Token[] | undefined =  await fetchErc20Or721(erc721, "erc721")
        // const erc1155s: Token[] | undefined = await fetchErc1155(erc1155)

        if (erc20s) {
          erc20s.sort((a: Token, b: Token) => a.balance > b.balance ? 1 : -1)
          // console.log("@useAssets, fetchedTokens:", {erc20s})
          setTokens(erc20s) 
          
        }
        setStatus("success") 
  }, [ ])

  const addErc20 = (erc20: `0x${string}`) => {
    setStatus("pending")
    const savedErc20s = JSON.parse(localStorage.getItem("powersProtocol_savedErc20s") || "[]")
    if (!savedErc20s.includes(erc20)) {
      localStorage.setItem("powersProtocol_savedErc20s", JSON.stringify([...savedErc20s, erc20]));
    }
    setStatus("success")
  }

  const resetErc20s = () => {
    setStatus("pending")
    localStorage.removeItem("powersProtocol_savedErc20s")
    setStatus("success")
  }

  return {status, error, tokens, native, fetchTokens, addErc20, resetErc20s }
}