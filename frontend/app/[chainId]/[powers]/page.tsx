'use client'

import React, { useCallback, useEffect, useState } from 'react'
import { Button } from '@/components/Button'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { useParams } from 'next/navigation'
import { parseChainId } from '@/utils/parsers'
import { usePowers } from '@/hooks/usePowers'
import { useChains } from 'wagmi'
import { readContract } from 'wagmi/actions'
import { wagmiConfig } from '@/context/wagmiConfig'
import { powersAbi } from '@/context/abi'
import Image from 'next/image'
import { ArrowUpRightIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
import { Assets } from './Assets'
import { MyProposals } from './MyProposals'
import { MyRoles } from './MyRoles'
import { Logs } from './Logs'
import { Powers } from '@/context/types'

export default function FlowPage() {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()  
  const { fetchPowers, checkLaws, status: statusPowers, powers, fetchLawsAndRoles, fetchExecutedActions, fetchProposals } = usePowers()
  const { wallets } = useWallets()
  const { authenticated } = usePrivy(); 
  const [hasRoles, setHasRoles] = useState<{role: bigint; since: bigint}[]>([])
  const [isValidBanner, setIsValidBanner] = useState(false)
  const [isImageLoaded, setIsImageLoaded] = useState(false)
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  
  // console.log("@home:", {chains, supportedChain, powers})

  const validateBannerImage = useCallback(async (url: string | undefined) => {
      if (!url) {
          setIsValidBanner(false)
          return
      }

      try {
          const response = await fetch(url)
          const contentType = response.headers.get('content-type')
          if (contentType?.includes('image/png')) {
              setIsValidBanner(true)
          } else {
              setIsValidBanner(false)
          }
      } catch (error) {
          setIsValidBanner(false)
      }
  }, [])

  useEffect(() => {
      validateBannerImage(powers?.metadatas?.banner)
  }, [powers?.metadatas?.banner, validateBannerImage])

  const fetchMyRoles = useCallback(
    async (account: `0x${string}`, roles: bigint[]) => {
      let role: bigint; 
      let fetchedHasRole: {role: bigint; since: bigint}[] = []; 

      try {
        for await (role of roles) {
          const fetchedSince = await readContract(wagmiConfig, {
              abi: powersAbi,
              address: addressPowers as `0x${string}`,
              functionName: 'hasRoleSince', 
              args: [account, role]
              })
            fetchedHasRole.push({role, since: fetchedSince as bigint})
            }
            setHasRoles(fetchedHasRole)
        } catch (error) {
        console.error(error)
      }
    }, [])

  useEffect(() => {
    if (wallets && wallets[0]) {
      fetchMyRoles(wallets[0].address as `0x${string}`, powers?.roles || [])
    }
  }, [wallets?.[0]?.address, fetchMyRoles, powers?.roles])

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [, addressPowers, fetchPowers]) // updateProposals 

  // Memoize the fetch functions to prevent infinite loops
  const handleFetchProposals = useCallback(() => {
    if (powers) {
      fetchProposals(powers as Powers, 10n, 9000n)
    }
  }, [powers, fetchProposals])

  const handleFetchExecutedActions = useCallback(() => {
    if (powers) {
      fetchExecutedActions(powers as Powers)
    }
  }, [powers, fetchExecutedActions])
  
  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-3 px-2 overflow-x-scroll pt-16 pe-10">
    {/* hero banner  */}
    <section className="w-full min-h-64 flex flex-col justify-between items-end text-slate-50 border border-slate-300 rounded-md relative overflow-hidden">
      {/* Gradient background (always present) */}
      <div className="absolute inset-0 bg-gradient-to-br to-indigo-500 from-orange-400" />
      
      {/* Banner image (if valid) */}
      {isValidBanner && powers?.metadatas?.banner && (
        <div className={`absolute inset-0 transition-opacity duration-500 ${isImageLoaded ? 'opacity-100' : 'opacity-0'}`}>
          <Image
            src={powers.metadatas.banner}
            alt={`${powers.name} banner`}
            fill
            className="object-cover"
            priority
            quality={100}
            onLoadingComplete={() => setIsImageLoaded(true)}
          />
        </div>
      )}

      {/* Content */}
      <div className="relative w-full max-w-fit h-full max-h-fit text-lg p-6" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
        {supportedChain && supportedChain.name}
      </div>
      <div className="relative w-full max-w-fit h-full max-h-fit text-6xl p-6" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
        {powers?.name}
      </div>

      {/* Reload button */}
      {/* <button
        onClick={() => addressPowers && fetchLawsAndRoles(powers as Powers)}
        className="absolute top-4 left-4 p-2 rounded-md bg-slate-50/25 hover:bg-slate-100/90 border border-slate-300/50 shadow-sm transition-all duration-200 backdrop-blur-sm"
        title="Reload powers data"
        disabled={statusPowers === "pending"}
      >
        <ArrowPathIcon 
          className={`w-4 h-4 text-slate-700 ${statusPowers === "pending" ? 'animate-spin' : ''}`}
        />
      </button> */}
    </section>
    
    {/* Description + link to powers protocol deployment */}  
    <section className="w-full h-fit flex flex-col gap-2 justify-left items-center border border-slate-300 rounded-md bg-slate-50 lg:max-w-full max-w-3xl p-4">
      <>
      <div className="w-full text-slate-800 text-left text-pretty">
         {powers?.metadatas?.description} 
      </div>
      <a
        href={`${supportedChain?.blockExplorers?.default.url}/address/${addressPowers as `0x${string}`}#code`} target="_blank" rel="noopener noreferrer"
        className="w-full"
      >
      <div className="flex flex-row gap-1 items-center justify-start">
        <div className="text-left text-sm text-slate-500 break-all w-fit">
          {addressPowers as `0x${string}`}
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-500"
            />
        </div>
      </a>
      </>
      {/* } */}
    </section>
    
    {/* main body  */}
    <section className="w-full h-fit flex flex-wrap gap-3 justify-between items-start pb-20">
      <Logs hasRoles = {hasRoles} authenticated = {authenticated} powers = {powers} status = {statusPowers} onRefresh = {handleFetchExecutedActions}/>

      <MyProposals hasRoles = {hasRoles} authenticated = {authenticated} proposals = {powers?.proposals || []} powers = {powers} status = {statusPowers} onFetchProposals = {handleFetchProposals}/> 
      
      <Assets status = {statusPowers} powers = {powers}/> 
      
      <MyRoles hasRoles = {hasRoles} authenticated = {authenticated} powers = {powers} status = {statusPowers}/>
      
    </section>
  </main>
  )
} 