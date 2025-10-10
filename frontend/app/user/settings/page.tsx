'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useChains } from 'wagmi'
import { Powers } from '@/context/types'
import Image from 'next/image'
import { ArrowUpRightIcon } from '@heroicons/react/24/outline'


import { useWallets } from '@privy-io/react-auth'
import { useRouter } from 'next/navigation'

export default function SettingsPage() {
  const [savedProtocols, setSavedProtocols] = useState<Powers[]>([])
  const [selectedProtocols, setSelectedProtocols] = useState<Record<string, Powers[]>>({})
  const [combinedProtocols, setCombinedProtocols] = useState<Powers[]>([])
  const chains = useChains()
  const { wallets } = useWallets()
  const connectedAddress = wallets?.[0]?.address
  const router = useRouter()

  // Default Powers 101 protocol
  const defaultPowers101 = {
    contractAddress: '0x0000000000000000000000000000000000000001' as `0x${string}`,
    chainId: 11155111n,
    name: 'Powers 101',
    uri: 'https://powers-protocol.com/metadata/powers101.json',
    metadatas: {
      icon: '/logo1_notext.png',
      banner: '/orgMetadatas/PowersDAO_Banner.png',
      description: 'Learn the basics of Powers Protocol - a comprehensive introduction to decentralized governance and law execution.',
      erc20s: [],
      erc721s: [],
      erc1155s: [],
      attributes: []
    },
    lawCount: 0n,
    laws: [],
    ActiveLaws: [],
    proposals: [],
    roles: [],
    roleLabels: [],
    roleHolders: [],
    deselectedRoles: []
  }

  useEffect(() => {
    // Read from localStorage on component mount and ensure Powers 101 exists
    const loadSavedProtocols = () => {
      try {
        const localStore = localStorage.getItem('powersProtocols')
        let protocols: Powers[] = []
        
        if (localStore && localStore !== 'undefined') {
          protocols = JSON.parse(localStore)
        }

        // Check if Powers 101 already exists
        const powers101Exists = protocols.some(p => p.name === 'Powers 101')
        
        if (!powers101Exists) {
          // Add Powers 101 to the list
          protocols.unshift(defaultPowers101) // Add to beginning of array
          localStorage.setItem('powersProtocols', JSON.stringify(protocols, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ))
        }

        setSavedProtocols(protocols)
      } catch (error) {
        console.error('Error loading saved protocols:', error)
        // If there's an error, at least show Powers 101
        setSavedProtocols([defaultPowers101])
      }
    }

    loadSavedProtocols()
  }, [ ])

  useEffect(() => {
    // Load selected protocols for the connected wallet
    const loadSelectedProtocols = () => {
      try {
        const localStore = localStorage.getItem('selectedProtocols')
        if (localStore && localStore !== 'undefined') {
          const parsed = JSON.parse(localStore)
          setSelectedProtocols(parsed)
        }
      } catch (error) {
        console.error('Error loading selected protocols:', error)
      }
    }

    loadSelectedProtocols()
  }, [])

  // Function to combine saved protocols and selected protocols, removing duplicates
  const combineProtocols = useCallback(
  (saved: Powers[], selected: Record<string, Powers[]>) => {
    const combined: Powers[] = [...saved]
    
    // Add selected protocols for the current wallet
    if (connectedAddress && selected[connectedAddress]) {
      selected[connectedAddress].forEach(selectedProtocol => {
        // Check if this protocol already exists in saved protocols
        const exists = combined.some(savedProtocol => 
          savedProtocol.contractAddress === selectedProtocol.contractAddress
        )
        if (!exists) {
          combined.push(selectedProtocol)
        }
      })
    }
    
    return combined
  }, [connectedAddress])

  // Update combined protocols whenever saved or selected protocols change
  useEffect(() => {
    const combined = combineProtocols(savedProtocols, selectedProtocols)
    setCombinedProtocols(combined)
  }, [savedProtocols, selectedProtocols, connectedAddress, combineProtocols])

  const handleAddToProfile = (protocol: Powers) => {
    if (!connectedAddress) return

    try {
      // Get current selected protocols
      const currentSelected = { ...selectedProtocols }
      
      // Initialize array for this wallet if it doesn't exist
      if (!currentSelected[connectedAddress]) {
        currentSelected[connectedAddress] = []
      }

      // Check if protocol is already selected
      const isAlreadySelected = currentSelected[connectedAddress].some(
        p => p.contractAddress === protocol.contractAddress
      )

      if (!isAlreadySelected) {
        // Add protocol to selected list
        currentSelected[connectedAddress].push(protocol)
        
        // Update localStorage
        localStorage.setItem('selectedProtocols', JSON.stringify(currentSelected, (key, value) =>
          typeof value === "bigint" ? value.toString() : value,
        ))
        
        // Update state
        setSelectedProtocols(currentSelected)
      }
    } catch (error) {
      console.error('Error adding protocol to profile:', error)
    }
  }

  const handleRemoveFromProfile = (protocol: Powers) => {
    if (!connectedAddress) return

    try {
      // Get current selected protocols
      const currentSelected = { ...selectedProtocols }
      
      if (currentSelected[connectedAddress]) {
        // Remove protocol from selected list
        currentSelected[connectedAddress] = currentSelected[connectedAddress].filter(
          p => p.contractAddress !== protocol.contractAddress
        )
        
        // Update localStorage
        localStorage.setItem('selectedProtocols', JSON.stringify(currentSelected, (key, value) =>
          typeof value === "bigint" ? value.toString() : value,
        ))
        
        // Update state
        setSelectedProtocols(currentSelected)
      }
    } catch (error) {
      console.error('Error removing protocol from profile:', error)
    }
  }

  const isProtocolSelected = (protocol: Powers) => {
    if (!connectedAddress) return false
    return selectedProtocols[connectedAddress]?.some(
      p => p.contractAddress === protocol.contractAddress
    ) || false
  }

  const getChainName = (chainId: bigint) => {
    const parsedChainId = Number(chainId)
    const chain = chains.find(chain => chain.id === parsedChainId)
    return chain?.name || 'Unknown Chain'
  }

  return (
    <div className="w-full h-full flex flex-col justify-start items-center p-4 pt-20 overflow-y-auto">
      <div className="max-w-6xl w-full">
        <div className="flex items-center justify-between mb-6">
          <button
            onClick={() => router.back()}
            className="flex items-center gap-2 text-slate-600 hover:text-slate-800 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back
          </button>
          <div className="text-center flex-1">
            <h1 className="text-3xl font-bold text-slate-800">
              Settings
            </h1>
            <p className="text-lg text-slate-600">
              Select your favorite Powers Protocols or add new ones.
            </p>
          </div>
          <div className="w-20"></div> {/* Spacer for centering */}
        </div>

        {/* Combined Protocols Section */}
        <section className="w-full mb-8">
          {combinedProtocols.length === 0 ? (
            <div className="text-center py-12 bg-slate-50 rounded-lg border border-slate-200">
              <p className="text-slate-500 text-lg">
                No protocols available. Visit a protocol page to save it here or add protocols to your profile.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
              {combinedProtocols.map((protocol, index) => {
                const chainName = getChainName(protocol.chainId)
                
                return (
                  <div 
                    key={`${protocol.contractAddress}-${index}`}
                    className="bg-white rounded-lg border flex flex-col justify-start border-slate-200 shadow-sm hover:shadow-md transition-all overflow-hidden"
                  >
                    {/* Content wrapper with opacity */}
                    <div className={`flex flex-col justify-start flex-1 ${
                      isProtocolSelected(protocol) ? 'opacity-100' : 'opacity-50'
                    }`}>
                      {/* Protocol Banner Header - similar to protocol page */}
                      <div className="relative min-h-48 flex flex-col justify-between items-end text-slate-50 border border-slate-300 rounded-t-lg overflow-hidden">
                        {/* Gradient background (always present) */}
                        <div className="absolute inset-0 bg-gradient-to-br to-indigo-500 from-orange-400" />
                        
                        {/* Banner image (if available) */}
                        {protocol.metadatas?.banner && (
                          <div className="absolute inset-0">
                            <Image
                              src={protocol.metadatas.banner}
                              alt={`${protocol.name} banner`}
                              fill
                              className="object-cover"
                              sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                            />
                          </div>
                        )}

                        {/* Content with shaded text */}
                        <div className="relative w-full max-w-fit h-full max-h-fit text-lg p-4" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
                          {chainName}
                        </div>
                        <div className="relative w-full max-w-fit h-full max-h-fit text-3xl p-4" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
                          {protocol.name || 'Unnamed Protocol'}
                        </div>
                      </div>

                      {/* Description and Contract Address - right beneath banner */}
                      <div className="p-4 pb-0">
                        {/* Description */}
                        {protocol.metadatas?.description && (
                          <div className="mb-4">
                            <p className="text-sm text-slate-600 text-left text-pretty">
                              {protocol.metadatas.description}
                            </p>
                          </div>
                        )}

                        {/* Contract Address */}
                        <div className="mb-4">
                          <div className="flex items-center justify-between">
                            <span className="text-xs text-slate-500">Contract Address</span>
                            <a
                              href={`/protocol/${Number(protocol.chainId)}/${protocol.contractAddress}`}
                              className="flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800 transition-colors"
                            >
                              <span className="truncate max-w-28">
                                {protocol.contractAddress.slice(0, 8)}...{protocol.contractAddress.slice(-6)}
                              </span>
                              <ArrowUpRightIcon className="w-3 h-3" />
                            </a>
                          </div>
                        </div>

                        {/* Protocol Stats */}
                        <div className="grid grid-cols-2 gap-3 text-xs mb-6">
                          <div className="text-center bg-slate-50 rounded p-2">
                            <div className="font-medium text-slate-700">
                              {protocol.lawCount ? Number(protocol.lawCount) : 0}
                            </div>
                            <div className="text-slate-500">Laws</div>
                          </div>
                          <div className="text-center bg-slate-50 rounded p-2">
                            <div className="font-medium text-slate-700">
                              {protocol.roles ? protocol.roles.length : 0}
                            </div>
                            <div className="text-slate-500">Roles</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Button section - always at opacity 100 */}
                    <div className="px-4 pb-4 mt-auto opacity-100">
                      {!connectedAddress ? (
                        <button 
                          className="w-full bg-gray-400 text-white text-sm py-2 px-3 rounded-md cursor-not-allowed"
                          disabled
                        >
                          Please connect wallet
                        </button>
                      ) : isProtocolSelected(protocol) ? (
                        <button 
                          onClick={() => handleRemoveFromProfile(protocol)}
                          className="w-full bg-blue-600 text-white text-sm py-2 px-3 rounded-md hover:bg-blue-700 transition-all"
                        >
                          Remove from Profile
                        </button>
                      ) : (
                        <button 
                          onClick={() => handleAddToProfile(protocol)}
                          className="w-full bg-blue-600 text-white text-sm py-2 px-3 rounded-md hover:bg-blue-700 transition-all"
                        >
                          Add to Profile
                        </button>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </section>
      </div>
    </div>
  )
}
