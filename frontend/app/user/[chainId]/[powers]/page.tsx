'use client'

import React, { useState, useEffect, useCallback, useRef } from 'react'
import { useParams } from 'next/navigation'
import { useChains, useAccount, useSwitchChain } from 'wagmi'
import { parseChainId } from '@/utils/parsers'
import { Powers } from '@/context/types'
import { usePowers } from '@/hooks/usePowers'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { readContract } from 'wagmi/actions'
import { wagmiConfig } from '@/context/wagmiConfig'
import { powersAbi } from '@/context/abi'
import Image from 'next/image'
import { 
  PlusIcon,
  ArrowDownTrayIcon,
  CheckCircleIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline'
import DynamicThumbnail from '@/components/DynamicThumbnail'
import New from './New'
import Incoming from './Incoming'
import Fulfilled from './Fulfilled'
import About from './About'

export default function UserPage() {
  const [activeTab, setActiveTab] = useState('New')
  const [protocol, setProtocol] = useState<Powers | null>(null)
  const [hasRoles, setHasRoles] = useState<{role: bigint; since: bigint}[]>([])
  const [isValidBanner, setIsValidBanner] = useState(false)
  const [isImageLoaded, setIsImageLoaded] = useState(false)
  const [proposals, setProposals] = useState<any[]>([])
  const proposalsFetchedRef = useRef(false)
  
  // Refs to store reset functions from child components
  const newResetRef = useRef<(() => void) | null>(null)
  const incomingResetRef = useRef<(() => void) | null>(null)
  const fulfilledResetRef = useRef<(() => void) | null>(null)
  const tabs = [
    { id: 'New', label: 'New', icon: PlusIcon },
    { id: 'Incoming', label: 'Incoming', icon: ArrowDownTrayIcon },
    { id: 'Fulfilled', label: 'Fulfilled', icon: CheckCircleIcon },
    { id: 'About', label: 'About', icon: InformationCircleIcon }
  ]
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()
  const { refetchPowers, powers, fetchActions } = usePowers()
  const { wallets } = useWallets()
  const { authenticated } = usePrivy()
  const chains = useChains()
  const { chain } = useAccount()
  const { switchChain } = useSwitchChain()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const PUBLIC_ROLE = 115792089237316195423570985008687907853269984665640564039457584007913129639935n;

  // Handle tab click - reset selection if clicking on active tab
  const handleTabClick = useCallback((tabId: string) => {
    if (tabId === activeTab) {
      // If clicking on the currently active tab, try to reset selection
      if (tabId === 'New' && newResetRef.current) {
        newResetRef.current()
      } else if (tabId === 'Incoming' && incomingResetRef.current) {
        incomingResetRef.current()
      } else if (tabId === 'Fulfilled' && fulfilledResetRef.current) {
        fulfilledResetRef.current()
      }
    } else {
      // Normal tab switching
      setActiveTab(tabId)
    }
  }, [activeTab])

  // console.log("@UserPage, main", {chainId, powers, wallets: wallets[0].address})

  // Banner validation function
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

  // Fetch user roles function
  const fetchMyRoles = useCallback(
    async (account: `0x${string}`, roles: bigint[]) => {
      let role: bigint; 
      const fetchedHasRole: {role: bigint; since: bigint}[] = [{role: PUBLIC_ROLE, since: 1n}]; 
      const rolesFiltered = roles.filter(role => role != PUBLIC_ROLE)

      // console.log("@fetchMyRoles, waypoint 0", {roles, addressPowers})

      if (addressPowers) {
        try {
          for await (role of rolesFiltered) {
            const fetchedSince = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: addressPowers as `0x${string}`,
                functionName: 'hasRoleSince', 
                args: [account, role],
                chainId: parseChainId(chainId)
                })
              // Only include roles where since > 0 (user actually has the role)
              if ((fetchedSince as bigint) > 0n) {
                fetchedHasRole.push({role, since: fetchedSince as bigint})
              }
            }
            setHasRoles(fetchedHasRole)
          } catch (error) {
          console.error(error)
        }
      }
    }, [])

  const handleFetchActions = useCallback(() => {
    if (powers) {
      fetchActions(powers as Powers)
    }
  }, [powers, fetchActions])

  useEffect(() => {
    // Load the protocol from localStorage
    const loadProtocol = () => {
      try {
        const localStore = localStorage.getItem('powersProtocols')
        if (localStore && localStore !== 'undefined') {
          const protocols: Powers[] = JSON.parse(localStore)
          const foundProtocol = protocols.find(p => p.contractAddress === addressPowers)
          setProtocol(foundProtocol || null)
        }
      } catch (error) {
        console.error('Error loading protocol:', error)
      }
    }

    loadProtocol()
  }, [addressPowers])

  useEffect(() => {
    validateBannerImage(powers?.metadatas?.banner)
  }, [powers?.metadatas?.banner, validateBannerImage])

  useEffect(() => {
    if (wallets && powers?.roles) {
      // console.log("@useEffect, waypoint 1 fetch my roles", {wallets: wallets[0].address, roles: powers?.roles})
      fetchMyRoles(wallets[0].address as `0x${string}`, powers?.roles || [])
    }
  }, [, wallets?.[0]?.address, fetchMyRoles, powers?.roles])

  useEffect(() => {
    // console.log("@useEffect, waypoint 0 fetch powers", {addressPowers})
    if (addressPowers) {
      // Reset proposals ref when switching protocols
      proposalsFetchedRef.current = false
      setProposals([])
      refetchPowers(addressPowers as `0x${string}`)
    }
  }, [, addressPowers, refetchPowers])

  // Force chain switch to the selected chain
  useEffect(() => {
    const targetChainId = parseChainId(chainId)
    if (authenticated && chainId && supportedChain && targetChainId && chain?.id !== targetChainId) {
      // console.log("@useEffect, switching chain", { 
      //   currentChain: chain?.id, 
      //   targetChain: targetChainId,
      //   supportedChain: supportedChain.name 
      // })
      try {
        switchChain({ chainId: targetChainId })
      } catch (error) {
        console.error('Error switching chain:', error)
      }
    }
  }, [authenticated, chainId, supportedChain, chain?.id, switchChain])

  return (
    <div className="w-full h-full flex flex-col items-center pb-12 md:pb-0">
      {/* Protocol Banner */}
      <div className="w-full flex justify-center relative px-4 pt-20">
        <div className="max-w-6xl w-full relative">
          <div className="relative min-h-80 flex flex-col justify-between items-end text-slate-50 border border-slate-300 rounded-lg overflow-hidden pb-4">
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
                  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 100vw, 100vw"
                />
              </div>
            )}

            {/* Role Thumbnails - Top Left */}
            {authenticated && hasRoles.length > 0 && powers && (
              <div className="absolute top-4 left-4 flex flex-col gap-2">
                <div className="text-sm text-slate-50 font-medium" style={{ textShadow: '0 1px 13px rgba(0,0,0,1)' }}>
                  Your roles:
                </div>
                <div className="flex flex-row gap-2">
                  {hasRoles.map((roleData, index) => (
                    <div 
                      key={`${roleData.role}-${index}`}
                      className="bg-slate-50/30 backdrop-blur-sm rounded-lg"
                    >
                      <DynamicThumbnail
                        roleId={roleData.role}
                        powers={powers}
                        size={36}
                        className="object-cover rounded-md"
                      />
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Content with shaded text */}
            <div className="relative w-full max-w-fit h-full max-h-fit text-lg p-6 pt-3 pb-1" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
              {supportedChain && supportedChain.name}
            </div>
            <div className="relative w-full max-w-fit h-full max-h-fit text-6xl p-6 pt-1 pb-12" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
              {powers?.name || 'Unnamed Protocol'}
            </div>
          </div>
          
          {/* Horizontal Slider below banner */}
          <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 w-4/5 sm:w-2/3 bg-slate-100/90 backdrop-blur-sm border border-slate-300 rounded-lg z-20">
            <div className="px-4 sm:px-8 py-2">
              <div className="relative rounded-lg p-1">
                {/* Sliding background indicator */}
                <div 
                  className="absolute top-1 bottom-1 bg-white rounded-md shadow-sm transition-all duration-300 ease-in-out"
                  style={{
                    width: `${100 / tabs.length}%`,
                    left: `${(tabs.findIndex(tab => tab.id === activeTab) * 100) / tabs.length}%`
                  }}
                />
                
                {/* Tab buttons */}
                <div className="relative flex">
                  {tabs.map((tab) => (
                    <button
                      key={tab.id}
                      onClick={() => handleTabClick(tab.id)}
                      className={`flex-1 px-4 py-2 text-center font-medium transition-colors duration-200 rounded-md relative z-10 flex items-center justify-center gap-2 ${
                        activeTab === tab.id 
                          ? 'text-slate-900' 
                          : 'text-slate-600 hover:text-slate-800'
                      }`}
                    >
                      {/* Icon - always visible */}
                      <tab.icon className="w-5 h-5" />
                      {/* Text - hidden on small screens */}
                      <span className="hidden sm:inline">{tab.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Tab Content */}
      <div className="w-full flex justify-center relative px-4 overflow-y-auto z-10">
        <div className="max-w-6xl w-full flex-1 flex flex-col justify-start items-center pt-12 pb-8">
          {activeTab === 'New' && <New hasRoles={hasRoles} powers={powers as Powers} resetRef={newResetRef}/>}
          {/* NB! Loading still needs to be fixed   */}
          {activeTab === 'Incoming' && <Incoming hasRoles={hasRoles} powers={powers as Powers} proposals={proposals} loading={"idle"} onRefresh={handleFetchActions} resetRef={incomingResetRef}/>}
          {activeTab === 'Fulfilled' && <Fulfilled hasRoles={hasRoles} powers={powers as Powers} resetRef={fulfilledResetRef}/>}
          {activeTab === 'About' && <About powers={powers as Powers}/>}
        </div>
      </div>
    </div>
  )
}
