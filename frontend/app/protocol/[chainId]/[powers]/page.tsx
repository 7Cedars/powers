'use client'

import { useCallback, useEffect, useState } from 'react'
import { Button } from '@/components/Button'
import { useParams, useRouter } from 'next/navigation'
import { parseChainId } from '@/utils/parsers'
import { usePowers } from '@/hooks/usePowers'
import { useChains } from 'wagmi'
import Image from 'next/image'
import { ArrowUpRightIcon } from '@heroicons/react/24/outline'
import { Assets } from './Assets'
import { Roles } from './Roles'
import { Laws } from './Laws'
import { Actions } from './Actions'
import { Powers } from '@/context/types'
import { MetadataLinks } from '@/components/MetadataLinks'

export default function FlowPage() {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()  
  const { fetchPowers, status: statusPowers, powers, fetchActions } = usePowers()
  const router = useRouter()
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


  useEffect(() => {
    // console.log("@useEffect, waypoint 0 fetch powers", {addressPowers})
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers]) // updateProposals 

  const handleFetchActions = useCallback(() => {
    if (powers) {
      fetchActions(powers as Powers)
    }
  }, [powers, fetchActions])

  const navigateToUserUser = () => {
    router.push(`/user/${chainId}/${addressPowers}`)
  }
  
  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-3 px-2 overflow-x-scroll pt-16 pe-10" >
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
    
    {/* Metadata Links */}
    <MetadataLinks 
      website={powers?.metadatas?.website}
      codeOfConduct={powers?.metadatas?.["code-of-conduct"]}
      disputeResolution={powers?.metadatas?.["dispute-resolution"]}
      communicationChannels={powers?.metadatas?.["communication-channels"]}
    />
    
    {/* main body  */}
    <section className="w-full h-fit flex flex-wrap gap-3 justify-between items-start" help-nav-item="home-screen">
      <Assets status = {statusPowers} powers = {powers}/> 
      
      <Actions powers = {powers} status = {statusPowers} onRefresh = {handleFetchActions}/>
      
      <Roles powers = {powers} status = {statusPowers}/>
      
      <Laws powers = {powers} status = {statusPowers}/>      
      
    </section>

    {/* Go to user portal button */}
    <section className="w-full flex justify-center items-center py-4 text-slate-800 opacity-75 hover:opacity-100">
      <div className="w-full">
        <Button 
          size={0} 
          showBorder={true} 
          role={6}
          filled={false}
          selected={true}
          onClick={navigateToUserUser}
          statusButton="idle"
        > 
          <div className="flex flex-row gap-1 items-center justify-center">
            Go to user portal
            <ArrowUpRightIcon className="w-4 h-4" />
          </div>
        </Button>
      </div>
    </section>
  </main>
  )
} 