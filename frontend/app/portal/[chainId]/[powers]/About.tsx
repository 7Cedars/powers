'use client'

import React from 'react'
import { Powers } from '@/context/types'
import { useChains } from 'wagmi'
import { parseChainId } from '@/utils/parsers'
import { ArrowUpRightIcon } from '@heroicons/react/24/outline'
import Image from 'next/image'
import { useRouter } from 'next/navigation'

interface AboutProps {
  powers: Powers
}

export default function About({ powers }: AboutProps) {
  const chains = useChains()
  const router = useRouter()
  const supportedChain = chains.find(chain => chain.id === Number(powers.chainId))

  const handleGovernanceClick = () => {
    router.push(`/protocol/${Number(powers.chainId)}/${powers.contractAddress}`)
  }

  return (
    <div className="w-full max-w-6xl mx-auto">
      {/* Protocol Header */}
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm mb-6 overflow-hidden">
        {/* Protocol Details */}
        <div className="p-6">
          {/* Description */}
          {powers.metadatas?.description && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-3">Description</h3>
              <p className="text-slate-600 leading-relaxed">
                {powers.metadatas.description}
              </p>
            </div>
          )}

          {/* Contract Information */}
          <div className="mb-6">
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

          {/* Protocol Stats */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-slate-800 mb-3">Protocol Statistics</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center bg-slate-50 rounded-lg p-4">
                <div className="text-2xl font-bold text-slate-800">
                  {powers.roles ? powers.roles.length : 0}
                </div>
                <div className="text-sm text-slate-500">Roles</div>
              </div>
              <div className="text-center bg-slate-50 rounded-lg p-4">
                <div className="text-2xl font-bold text-slate-800">
                  {powers.activeLaws ? powers.activeLaws.length : 0}
                </div>
                <div className="text-sm text-slate-500">Active Laws</div>
              </div>
              <div className="text-center bg-slate-50 rounded-lg p-4">
                <div className="text-2xl font-bold text-slate-800">
                  {powers.proposals ? powers.proposals.length : 0}
                </div>
                <div className="text-sm text-slate-500">Proposals</div>
              </div>
            </div>
          </div>

          {/* Metadata URI */}
          {powers.uri && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-3">Metadata</h3>
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

          {/* Tokens */}
          {(powers.metadatas?.erc20s?.length || powers.metadatas?.erc721s?.length || powers.metadatas?.erc1155s?.length) && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-3">Supported Tokens</h3>
              <div className="space-y-2">
                {powers.metadatas?.erc20s?.length > 0 && (
                  <div className="text-sm text-slate-600">
                    <span className="font-medium">ERC-20:</span> {powers.metadatas.erc20s.length} tokens
                  </div>
                )}
                {powers.metadatas?.erc721s?.length > 0 && (
                  <div className="text-sm text-slate-600">
                    <span className="font-medium">ERC-721:</span> {powers.metadatas.erc721s.length} tokens
                  </div>
                )}
                {powers.metadatas?.erc1155s?.length > 0 && (
                  <div className="text-sm text-slate-600">
                    <span className="font-medium">ERC-1155:</span> {powers.metadatas.erc1155s.length} tokens
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Governance System Button */}
          <div className="w-full mt-6">
            <button
              onClick={handleGovernanceClick}
              className="w-full bg-slate-200 hover:bg-slate-300 text-slate-700 font-semibold py-4 px-8 rounded-lg text-lg transition-colors duration-200"
            >
              View Governance System
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
