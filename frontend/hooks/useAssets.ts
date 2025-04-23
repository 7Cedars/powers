// ok, what does this need to do? 

import { erc1155Abi, erc20Abi, erc721Abi, ownableAbi } from "@/context/abi"
import { supportedChains } from "@/context/chains"
import { publicClient } from "@/context/clients"
import { Powers, Status, Token } from "@/context/types"
import { useCallback, useState } from "react"
import { useBalance, useBlockNumber, useChainId } from "wagmi"
import { Abi, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig"
import { parse1155Metadata, parseMetadata } from "@/utils/parsers"

// NB! ALSO retrieve balance in native currency! 

export const useAssets = (powers: Powers | undefined) => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [tokens, setTokens] = useState<Token[]>()
  const chainId = useChainId()
  const {data: native, status: statusBalance}  = useBalance({
    address: powers?.contractAddress
  }) 
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

   const fetchErc20Or721 = async (tokenAddresses: `0x${string}`[], type: "erc20" | "erc721") => {
     let token: `0x${string}`
     let tokens: Token[] = [] 
 
     if (publicClient) {
         for await (token of tokenAddresses) {
          try {
            // console.log("fetching token: ", token)
           if (powers?.contractAddress) {
            const name = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'name' 
            })
            const nameParsed = name as string

            const symbol = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'symbol' 
            })
            const symbolParsed = symbol as string

            const balance = await readContract(wagmiConfig, {
              abi: type ==  "erc20" ? erc20Abi : erc721Abi,
              address: token,
              functionName: 'balanceOf', 
              args: [powers.contractAddress] 
            })
            const balanceParsed = balance as bigint

            let decimalParsed: bigint = 8n
            if ( type == "erc20") {
              const decimal = await readContract(wagmiConfig, {
                abi: erc20Abi,
                address: token,
                functionName: 'decimals'
              })
              decimalParsed = decimal as bigint
            }

            // console.log("@useAssets:", {nameParsed, symbolParsed, balanceParsed, decimalParsed})

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

            // console.log("@useAssets:", {tokens, nameParsed, symbolParsed, balanceParsed, decimalParsed, type})
              
           } 
         } catch (error) {
          setStatus("error") 
          setError({error, token})
         }
       } 
    } return tokens
  }


  const fetch1155s = async (erc1155Addresses: `0x${string}`[]) => {
    let token: `0x${string}`
    let erc1155s: Array<Token> = []
    const Ids = 10 // this hook checks the first 50 tokens Ids for a balance. 
    const IdsToCheck: bigint[] = new Array(Ids).fill(null).map((_, i) => BigInt(i + 1));
    

    if (publicClient) {
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
      } 
    }
  }

  const fetch1155Metadata = async (erc1155s: Token[]) => {
    let token: Token
    let erc1155sMetadata: Token[] = []

    if (publicClient) {
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
        }
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
    async (erc20: `0x${string}`[], erc721: `0x${string}`[], erc1155: `0x${string}`[]) => {
        setError(null)
        setStatus("pending")

        // console.log("@useAssets, fetchTokens called:", {erc20, erc721, erc1155})

        // NOTE: at the moment I only save the Erc20s. I might change this later. 
        
        const erc20s: Token[] | undefined = await fetchErc20Or721(erc20, "erc20")
        // const erc721s: Token[] | undefined =  await fetchErc20Or721(erc721, "erc721")
        // const erc1155s: Token[] | undefined = await fetchErc1155(erc1155)

        if (erc20s) {
          const fetchedTokens = [...erc20s]
          // order by balance (I can order by value as a second step later) 
          fetchedTokens.sort((a: Token, b: Token) => a.balance > b.balance ? 1 : -1)

          // console.log("@useAssets, fetchedTokens:", {fetchedTokens})

          setTokens(fetchedTokens) 
          localStorage.setItem("powersProtocol_savedTokens", JSON.stringify(fetchedTokens, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ));

          setStatus("success") 
        }

        
  }, [ ])

  const initialise = () => {
        // console.log("waypoint 1: initialise called")
        setStatus("pending")
        let localStore = localStorage.getItem("powersProtocol_savedTokens")
        const saved: Token[] = localStore ? JSON.parse(localStore) : []
        // console.log("waypoint 2: local storage queried:", {saved})
  
        if (saved.length == 0) { fetchTokens(
          supportedChain?.erc20s ? supportedChain?.erc20s : [`0x0`], 
          supportedChain?.erc721s ? supportedChain?.erc721s : [`0x0`],
          supportedChain?.erc1155s ? supportedChain?.erc1155s : [`0x0`]
        )} else {
          setTokens(saved)
          setStatus("success")
        }
      } 

  const update = useCallback(
        async (erc20: `0x${string}`) => {
          setStatus("pending")
    
          let localStore = localStorage.getItem("powersProtocol_savedTokens")
          const saved: Token[] = localStore ? JSON.parse(localStore) : []
          
          let erc20s: Token[] | undefined
          if (!saved.map(saved => saved.address).includes(erc20)) {
            erc20s  = await fetchErc20Or721([erc20], "erc20")
          } else {
            setStatus("error")
            setError("Token already added.")
          }
          if (erc20s && erc20s.length > 0) {
            const fetchedTokens = [...erc20s, ...saved]
            // order by balance (I can order by value as a second step later)
            fetchedTokens.sort((a: Token, b: Token) => a.balance > b.balance ? 1 : -1)
 
            setTokens(fetchedTokens)
            localStorage.setItem("powersProtocol_savedTokens", JSON.stringify(fetchedTokens, (key, value) =>
              typeof value === "bigint" ? value.toString() : value,
            ));
            setStatus("success")
          }
      }, [])
  
  return {status, error, tokens, native, fetchTokens, initialise, update }
}