'use client'

import React, { useState, useEffect } from 'react'
import { useChains } from 'wagmi'
import { Powers } from '@/context/types'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { TrashIcon, XMarkIcon } from '@heroicons/react/24/outline'
import { Footer } from '@/app/Footer'

export default function ProfilePage() {
  const [savedProtocols, setSavedProtocols] = useState<Powers[]>([])
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [protocolToDelete, setProtocolToDelete] = useState<Powers | null>(null)
  
  const chains = useChains()
  const router = useRouter()

  // Default Powers 101 protocol
  const defaultPowers101: Powers = {
    contractAddress: '0x15c7ce6f92d62266800c625caa16556c4bf0d08b' as `0x${string}`,
    chainId: 11155420n,
    name: 'Powers Base',
    uri: 'https://powers-protocol.com/metadata/powers101.json',
    metadatas: {
      icon: '/logo1_notext.png',
      banner: '/orgMetadatas/PowersDAO_Banner.png',
      description: 'Learn the basics of Powers Protocol - a comprehensive introduction to decentralized governance and law execution.',
      attributes: []
    },
    lawCount: 0n,
    laws: [],
    roles: [],
  }

  const defaultPowerLabs: Powers = {
    contractAddress: '0x15c7ce6f92d62266800c625caa16556c4bf0d08b' as `0x${string}`,
    chainId: 11155420n,
    name: 'Powers Base',
    uri: 'https://powers-protocol.com/metadata/powers101.json',
    metadatas: {
      icon: '/logo1_notext.png',
      banner: '/orgMetadatas/PowersDAO_Banner.png',
      description: 'Learn the basics of Powers Protocol - a comprehensive introduction to decentralized governance and law execution.',
      attributes: []
    },
    lawCount: 0n,
    laws: [],
    roles: [],
  }
  useEffect(() => {
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
          protocols.unshift(defaultPowers101) 
          localStorage.setItem('powersProtocols', JSON.stringify(protocols, (key, value) =>
            typeof value === "bigint" ? value.toString() : value,
          ))
        }

        setSavedProtocols(protocols)
      } catch (error) {
        console.error('Error loading saved protocols:', error)
        setSavedProtocols([defaultPowers101])
      }
    }

    loadSavedProtocols()
  }, [])

  const getChainName = (chainId: bigint) => {
    const parsedChainId = Number(chainId)
    const chain = chains.find(chain => chain.id === parsedChainId)
    return chain?.name || 'Unknown Chain'
  }

  const handleProtocolClick = (protocol: Powers) => {
    const chainId = protocol.chainId ? Number(protocol.chainId).toString() : '11155111'
    router.push(`/user/${chainId}/${protocol.contractAddress}`)
  }

  const handleDeleteClick = (e: React.MouseEvent, protocol: Powers) => {
    e.stopPropagation()
    setProtocolToDelete(protocol)
    setIsDeleteModalOpen(true)
  }

  const confirmDelete = () => {
    if (!protocolToDelete) return

    const updatedProtocols = savedProtocols.filter(
      p => p.contractAddress !== protocolToDelete.contractAddress
    )

    localStorage.setItem('powersProtocols', JSON.stringify(updatedProtocols, (key, value) =>
      typeof value === "bigint" ? value.toString() : value,
    ))

    setSavedProtocols(updatedProtocols)
    setIsDeleteModalOpen(false)
    setProtocolToDelete(null)
  }

  return (
    <div className="w-full h-full flex flex-col justify-between items-center overflow-y-auto">
      <div className="w-full flex-1 flex flex-col items-center p-4 pt-20">
        <div className="max-w-6xl w-full">
          {/* <h1 className="text-3xl font-bold text-slate-800 mb-3 text-center">
            Home
          </h1> */}
          <h1 className="text-lg text-slate-600 text-center mb-8">
            Your saved Powers Protocols
          </h1>

          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {savedProtocols.map((protocol, index) => {
              const chainName = getChainName(protocol.chainId)
              
              return (
                <div
                  key={`${protocol.contractAddress}-${index}`}
                  onClick={() => handleProtocolClick(protocol)}
                  className="bg-white rounded-lg border border-slate-200 shadow-sm hover:shadow-md transition-all overflow-hidden cursor-pointer group relative"
                >
                  <div className="relative min-h-48 flex flex-col justify-between items-end text-slate-50 border border-slate-300 rounded-t-lg overflow-hidden">
                    <div className="absolute inset-0 bg-gradient-to-br to-indigo-500 from-orange-400" />
                    
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

                    <div className="relative w-full max-w-fit h-full max-h-fit text-lg p-4" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
                      {chainName}
                    </div>
                    <div className="relative w-full max-w-fit h-full max-h-fit text-3xl p-4" style={{ textShadow: '0 2px 10px rgba(0,0,0,0.8)' }}>
                      {protocol.name || 'Unnamed Protocol'}
                    </div>
                  </div>

                  {/* Trash Icon - visible on hover */}
                  <button
                      onClick={(e) => handleDeleteClick(e, protocol)}
                      className="absolute bottom-2 right-2 p-2 bg-white/80 rounded-full text-red-500 hover:bg-white hover:text-red-600 opacity-0 group-hover:opacity-100 transition-opacity duration-200 shadow-sm z-10"
                      title="Delete Protocol"
                  >
                      <TrashIcon className="w-5 h-5" />
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      </div>

      <Footer />

      {/* Delete Confirmation Modal */}
      {isDeleteModalOpen && protocolToDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6 relative">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-600"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
            
            <h3 className="text-xl font-bold text-slate-800 mb-4">
              Delete Protocol?
            </h3>
            
            <div className="space-y-4 text-slate-600">
              <p>
                Are you sure you want to delete <span className="font-semibold">{protocolToDelete.name}</span>?
              </p>
              
              <div className="bg-slate-50 p-3 rounded border border-slate-200 text-sm break-all">
                <p className="font-mono text-xs text-slate-500 mb-1">Contract Address:</p>
                {protocolToDelete.contractAddress}
              </div>
              
              <p className="text-sm text-slate-500">
                You can add this protocol again by visiting:
                <br />
                <span className="text-blue-600 break-all">/protocol/{Number(protocolToDelete.chainId)}/{protocolToDelete.contractAddress}</span>
              </p>
            </div>

            <div className="flex gap-3 mt-6 justify-end">
              <button
                onClick={() => setIsDeleteModalOpen(false)}
                className="px-4 py-2 rounded text-slate-600 hover:bg-slate-100 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmDelete}
                className="px-4 py-2 rounded bg-red-600 text-white hover:bg-red-700 transition-colors shadow-sm"
              >
                Delete Protocol
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
