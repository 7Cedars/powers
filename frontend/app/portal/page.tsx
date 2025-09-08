'use client'

import React, { useState, useEffect } from 'react'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { useChains } from 'wagmi'
import { parseChainId } from '@/utils/parsers'
import { Powers } from '@/context/types'
import Image from 'next/image'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function ProfilePage() {
  const [selectedProtocols, setSelectedProtocols] = useState<Powers[]>([])
  const chains = useChains()
  const { authenticated } = usePrivy()
  const { wallets } = useWallets()
  const connectedAddress = wallets?.[0]?.address
  const router = useRouter()

  useEffect(() => {
    // Load selected protocols for the connected wallet
    const loadSelectedProtocols = () => {
      try {
        const localStore = localStorage.getItem('selectedProtocols')
        if (localStore && localStore !== 'undefined' && connectedAddress) {
          const parsed = JSON.parse(localStore)
          const userProtocols = parsed[connectedAddress] || []
          setSelectedProtocols(userProtocols)
        } else {
          setSelectedProtocols([])
        }
      } catch (error) {
        console.error('Error loading selected protocols:', error)
        setSelectedProtocols([])
      }
    }

    loadSelectedProtocols()
  }, [connectedAddress])

  const getChainName = (chainId: string) => {
    const parsedChainId = parseChainId(chainId)
    const chain = chains.find(chain => chain.id === parsedChainId)
    return chain?.name || 'Unknown Chain'
  }

  const getChainIdFromAddress = (address: string) => {
    // Extract chainId from the first few characters of the address
    // This is a simplified approach - in a real implementation you might want to store chainId with each protocol
    return '11155111' // Default to Ethereum Sepolia for now
  }

  const handleProtocolClick = (protocol: Powers) => {
    const chainId = getChainIdFromAddress(protocol.contractAddress)
    router.push(`/portal/${chainId}/${protocol.contractAddress}`)
  }

  if (!authenticated) {
    return (
      <div className="w-full h-full flex flex-col justify-start items-center p-4 pt-20 overflow-y-auto">
        <div className="max-w-6xl w-full">
          <h1 className="text-3xl font-bold text-slate-800 mb-3 text-center">
            Profile
          </h1>
          <p className="text-lg text-slate-600 text-center mb-8">
            Your selected Powers Protocols
          </p>

          {/* Connect Wallet Banner */}
          <div className="relative min-h-64 flex flex-col justify-center items-center text-slate-50 border border-slate-300 rounded-lg overflow-hidden">
            {/* Gradient background */}
            <div className="absolute inset-0 bg-gradient-to-br to-indigo-500 from-orange-400" />
            
            {/* Content with shaded text */}
            <div className="relative text-center p-8" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
              <h2 className="text-4xl font-bold mb-4">
                Connect Your Wallet
              </h2>
              <p className="text-xl">
                Please connect your wallet to view your selected protocols
              </p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (selectedProtocols.length === 0) {
    return (
      <div className="w-full h-full flex flex-col justify-center items-center p-8">
        <div className="max-w-4xl w-full bg-white rounded-lg shadow-lg p-8 text-center">
          <h1 className="text-3xl font-bold text-slate-800 mb-6">
            Profile
          </h1>
          <p className="text-lg text-slate-600 mb-8">
            You haven't selected any protocols yet.
          </p>
          <Link 
            href="/portal/settings"
            className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors text-lg"
          >
            Go to Settings to Add Protocols
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full h-full flex flex-col justify-start items-center p-4 pt-20 overflow-y-auto">
      <div className="max-w-6xl w-full">
        <h1 className="text-3xl font-bold text-slate-800 mb-3 text-center">
          Profile
        </h1>
        <p className="text-lg text-slate-600 text-center mb-8">
          Your selected Powers Protocols
        </p>

        {/* Protocol Banners Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {selectedProtocols.map((protocol, index) => {
            const chainId = getChainIdFromAddress(protocol.contractAddress)
            const chainName = getChainName(chainId)
            
            return (
              <button
                key={`${protocol.contractAddress}-${index}`}
                onClick={() => handleProtocolClick(protocol)}
                className="bg-white rounded-lg border border-slate-200 shadow-sm hover:shadow-md transition-all overflow-hidden text-left focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                {/* Protocol Banner Header - similar to settings page but as button */}
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
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
