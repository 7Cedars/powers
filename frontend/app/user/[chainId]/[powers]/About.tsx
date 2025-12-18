'use client'

import React, { useState } from 'react'
import { CommunicationChannels, Powers, Role } from '@/context/types'
import { useChains } from 'wagmi'
import { ArrowUpRightIcon, ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline'
import { useRouter } from 'next/navigation'
import { UserItem } from './UserItem'
import { bigintToRole } from '@/utils/bigintTo'
import { default as DynamicThumbnail } from '@/components/DynamicThumbnail'
import { usePowersStore } from '@/context/store'
import { MetadataLinks } from '@/components/MetadataLinks'

export default function About() {
  const powers = usePowersStore();
  const [isMandatesExpanded, setIsMandatesExpanded] = useState(false)
  const router = useRouter()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))

  console.log("@AboutPage:", {powers})

  return (
    <div className="w-full max-w-6xl mx-auto">
      {/* Protocol Header */}
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden">
        {/* Protocol Details */}
        <div className="p-6">
          {/* Description */}
          {powers.metadatas?.description && (
            <>
              <h3 className="text-lg font-semibold text-slate-800 mb-3">Description</h3>
              <p className="text-slate-600 leading-relaxed">
                {powers.metadatas.description}
              </p>
              </>
          )}

          {/* Metadata Links */}
          <div className='mb-6 pt-2'> 
          <MetadataLinks 
            website={powers?.metadatas?.website}
            codeOfConduct={powers?.metadatas?.codeOfConduct}
            disputeResolution={powers?.metadatas?.disputeResolution}
            communicationChannels={powers?.metadatas?.communicationChannels as CommunicationChannels}
            parentContracts={powers?.metadatas?.parentContracts}
            childContracts={powers?.metadatas?.childContracts}
            chainId={powers?.chainId}
          />
          </div>

          {/* Contract Information */}
          <div className="mb-3">
            <h3 className="text-lg font-semibold text-slate-800 mb-3">Contract Information</h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Contract Address</span>
                <a
                  href={`${supportedChain?.blockExplorers?.default.url}/address/${powers.contractAddress}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 transition-colors"
                >
                  <span className="truncate max-w-32">
                    {powers.contractAddress.slice(0, 8)}...{powers.contractAddress.slice(-6)}
                  </span>
                  <ArrowUpRightIcon className="w-4 h-4" />
                </a>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Network</span>
                <span className="text-sm text-slate-700">{supportedChain?.name || 'Unknown Chain'}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Chain ID</span>
                <span className="text-sm text-slate-700">{Number(powers.chainId)}</span>
              </div>
            </div>
          </div>

 
          {powers.uri && (
            <div className="mb-6">
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">URI</span>
                <a
                  href={powers.uri}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 transition-colors"
                >
                  <span className="truncate max-w-48">
                    {powers.uri.length > 40 ? `${powers.uri.slice(0, 40)}...` : powers.uri}
                  </span>
                  <ArrowUpRightIcon className="w-4 h-4" />
                </a>
              </div>
            </div>
          )}

          {/* Protocol Stats */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-slate-800 mb-3">Governance System</h3>
            
            {/* Roles Section */}
            <div className="mb-6">
              <h4 className="text-md font-medium text-slate-700 mb-3">Roles</h4>
              <div className="flex flex-wrap gap-3">
                {powers.roles?.map((role: Role, index: number) => {
                  const roleName = bigintToRole(role.roleId, powers as Powers)
                  return (
                    <div
                      key={index}
                      className="relative group"
                    >
                      <div className="w-18 h-18 bg-slate-50/30 backdrop-blur-sm rounded-lg hover:bg-slate-100/50 transition-colors cursor-pointer p-1">
                        <DynamicThumbnail
                          roleId={role.roleId}
                          powers={powers as Powers}
                          size={72}
                          className="object-cover rounded-md"
                        />
                      </div>
                      {/* Tooltip */}
                      <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-slate-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-10">
                        {roleName}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {/* Mandates Section */}
            <div className="mb-6">
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-md font-medium text-slate-700">
                  Mandates ({powers.mandates?.length || 0})
                </h4>
                <button
                  onClick={() => setIsMandatesExpanded(!isMandatesExpanded)}
                  className="flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 transition-colors"
                >
                  {isMandatesExpanded ? 'Hide' : 'Show'}
                  {isMandatesExpanded ? (
                    <ChevronUpIcon className="w-4 h-4" />
                  ) : (
                    <ChevronDownIcon className="w-4 h-4" />
                  )}
                </button>
              </div>
              
              {isMandatesExpanded && powers.mandates && (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {powers.mandates.map((mandate) => (
                    <div key={`${mandate.mandateAddress}-${mandate.index}`} className="border border-slate-200 rounded-md">
                      <UserItem
                        powers={powers}
                        mandate={mandate}
                        chainId={powers.chainId.toString()}
                        showLowerSection={false}
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

      
          

          {/* Governance System Button */}
          <div className="w-full mt-6">
            <button
              onClick={() => router.push(`/protocol/${Number(powers.chainId)}/${powers.contractAddress}`)}
              className="w-full text-slate-700 font-semibold py-4 px-8 border border-slate-300 hover:border-slate-500 rounded-lg text-lg transition-colors duration-200"
            >
              View Governance System
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
