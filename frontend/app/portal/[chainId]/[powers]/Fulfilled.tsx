'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { PortalItem } from './PortalItem'
import { Law, Powers, LawExecutions } from '@/context/types'
import { useLaw } from '@/hooks/useLaw'
import { readContract } from 'wagmi/actions'
import { lawAbi } from '@/context/abi'
import { wagmiConfig } from '@/context/wagmiConfig'

type ExecutionWithLaw = {
  law: Law
  execution: bigint
  actionId: bigint
}

export default function Fulfilled({hasRoles, powers}: {hasRoles: {role: bigint, since: bigint}[], powers: Powers}) {
  const { chainId } = useParams<{ chainId: string }>()
  const { authenticated } = usePrivy()
  const { fetchExecutions } = useLaw()
  const [executionsWithLaws, setExecutionsWithLaws] = useState<ExecutionWithLaw[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Filter laws based on user roles (same logic as New.tsx) - memoized to prevent infinite loops
  const filteredLaws = useMemo(() => {
    return powers?.laws?.filter(
      law => law.conditions?.needCompleted !== 0n && hasRoles.some(role => role.role == law.conditions?.allowedRole)
    )
  }, [powers?.laws, hasRoles])

  // Fetch executions for all filtered laws
  const fetchAllExecutions = useCallback(async () => {
    if (!filteredLaws || filteredLaws.length === 0) {
      setExecutionsWithLaws([])
      return
    }

    setLoading(true)
    setError(null)
    
    try {
      const allExecutions: ExecutionWithLaw[] = []
      
      // Fetch executions for each law
      for (const law of filteredLaws) {
        try {
          const lawExecutions = await readContract(wagmiConfig, {
            abi: lawAbi,
            address: law.lawAddress as `0x${string}`,
            functionName: 'getExecutions',
            args: [law.powers, law.index]
          }) as LawExecutions

          // Add each execution with its corresponding law
          if (lawExecutions.executions && lawExecutions.actionsIds) {
            for (let i = 0; i < lawExecutions.executions.length; i++) {
              allExecutions.push({
                law,
                execution: lawExecutions.executions[i],
                actionId: lawExecutions.actionsIds[i]
              })
            }
          }
        } catch (lawError) {
          console.error(`Error fetching executions for law ${law.index}:`, lawError)
          // Continue with other laws even if one fails
        }
      }

      // Sort by execution block number (most recent first)
      allExecutions.sort((a, b) => Number(b.execution) - Number(a.execution))
      
      setExecutionsWithLaws(allExecutions)
    } catch (err) {
      console.error('Error fetching executions:', err)
      setError('Failed to fetch executions')
    } finally {
      setLoading(false)
    }
  }, [filteredLaws])

  // Fetch executions when component mounts or when filtered laws change
  useEffect(() => {
    if (authenticated && filteredLaws) {
      fetchAllExecutions()
    }
  }, [authenticated, filteredLaws])

  if (!authenticated) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              Please connect your wallet to view fulfilled actions
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              Loading fulfilled actions...
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-red-500 italic">
              {error}
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (executionsWithLaws.length === 0) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
            <p className="text-sm text-slate-600">Completed actions and proposals</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              No fulfilled actions found for your roles
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full mx-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-200">
          <h2 className="text-lg font-semibold text-slate-800">Fulfilled</h2>
          <p className="text-sm text-slate-600">Completed actions and proposals</p>
        </div>
        
        {/* Render PortalItem components for each execution */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {executionsWithLaws.map((executionData, index) => (
            <div 
              key={`${executionData.law.lawAddress}-${executionData.law.index}-${executionData.execution}-${index}`}
              className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
            >
              <PortalItem
                powers={powers as Powers}
                law={executionData.law}
                chainId={chainId as string}
                showLowerSection={false}
                selectedExecution={{
                  log: {
                    transactionHash: executionData.actionId.toString() // Using actionId as transaction hash for now
                  }
                }}
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
