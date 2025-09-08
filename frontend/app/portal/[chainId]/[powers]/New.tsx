'use client'

import React, { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { PortalItem } from './PortalItem'
import { LawBox } from '@/components/LawBox'
import { InputType, Law, Powers, Checks } from '@/context/types'
import { useErrorStore, useActionStore, useChecksStore, setError, setAction } from '@/context/store'
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { useChecks } from '@/hooks/useChecks'
import { useLaw } from '@/hooks/useLaw'
import { usePowers } from '@/hooks/usePowers'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'

export default function New({hasRoles, powers}: {hasRoles: {role: bigint, since: bigint}[], powers: Powers}) {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()
  const { authenticated } = usePrivy()
  const {wallets, ready} = useWallets();
  const action = useActionStore();
  const { chainChecks } = useChecksStore();
  const { fetchChainChecks, status: statusChecks } = useChecks()
  const { status: statusLaw, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, simulate, execute } = useLaw();
  
  // State to track selected law
  const [selectedLaw, setSelectedLaw] = useState<Law | null>(null)
  
  // Get checks for the selected law from Zustand store
  const checks = selectedLaw && chainChecks ? chainChecks.get(String(selectedLaw.index)) : undefined

  // Filter laws based on criteria
  console.log("@New, powers", powers)
  console.log("@New, hasRoles", hasRoles)
  const finalFilteredLaws = powers?.laws?.filter(
    law => law.conditions?.needCompleted !== 0n && hasRoles.some(role => role.role == law.conditions?.allowedRole))
  console.log("@New, filteredLaws", finalFilteredLaws)

  // Reset lawBox and fetch executions when switching laws
  useEffect(() => {
    if (selectedLaw) {
      const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != selectedLaw.params?.[index]?.dataType) : [true] 
      
      if (dissimilarTypes.find(type => type == true)) {
        setAction({
          lawId: selectedLaw.index,
          dataTypes: selectedLaw.params?.map(param => param.dataType),
          paramValues: [],
          nonce: '0',
          callData: '0x0',
          upToDate: false
        })
      } else {
        setAction({
          ...action,  
          lawId: selectedLaw.index,
          upToDate: false
        })
      }
      fetchExecutions(selectedLaw)
      resetStatus()
    }
  }, [selectedLaw])

  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])

  const handleSimulate = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    if (!selectedLaw) return
    
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(selectedLaw.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }
    
    if (lawCalldata && ready && wallets && powers?.contractAddress) { 
      fetchChainChecks(selectedLaw.index, lawCalldata, BigInt(action.nonce), wallets, powers)

      setAction({
        ...action,
        lawId: selectedLaw.index,
        caller: wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
        dataTypes: selectedLaw.params?.map(param => param.dataType),
        paramValues,
        nonce: nonce.toString(),
        description,
        callData: lawCalldata,
        upToDate: true
      })
      
      try {
        simulate(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
          action.callData as `0x${string}`,
          BigInt(action.nonce),
          selectedLaw
        )
      } catch (error) {
        setError({error: error as Error})
      }
    }
  };

  const handleExecute = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    if (!selectedLaw) return
    
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(selectedLaw.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }

    execute(
      selectedLaw, 
      lawCalldata as `0x${string}`,
      nonce,
      description
    )
  };


  // If a law is selected, show the LawBox
  if (selectedLaw) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSelectedLaw(null)}
                className="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
              >
                <ArrowLeftIcon className="w-4 h-4" />
                Back to laws
              </button>
            </div>
          </div>
          
          <div className="p-4 max-h-[calc(100vh-200px)] ">
            <LawBox 
              powers={powers as Powers}
              law={selectedLaw}
              checks={checks as Checks}
              params={selectedLaw.params || []}
              status={statusLaw}
              simulation={simulation}
              onChange={() => {
                setAction({...action, upToDate: false})
              }}
              onSimulate={handleSimulate}
              onExecute={handleExecute}
            />
          </div>
        </div>
      </div>
    )
  }

  if (!authenticated) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">New</h2>
            <p className="text-sm text-slate-600">New proposals and actions</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              Please connect your wallet to view available laws
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (finalFilteredLaws && finalFilteredLaws.length === 0) {
    return (
      <div className="w-full mx-auto">
        <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
          <div className="p-4 border-b border-slate-100">
            <h2 className="text-lg font-semibold text-slate-800">New</h2>
            <p className="text-sm text-slate-600">New proposals and actions</p>
          </div>
          <div className="p-4">
            <p className="text-sm text-slate-500 italic">
              No new laws available for your roles
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
          <h2 className="text-lg font-semibold text-slate-800">New</h2>
          <p className="text-sm text-slate-600">Available laws for your roles</p>
        </div>
        
        {/* Render PortalItem components for each filtered law */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {finalFilteredLaws && finalFilteredLaws.map((law: Law, index: number) => (
            <div 
              key={`${law.lawAddress}-${law.index}`}
              className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
              onClick={() => setSelectedLaw(law)}
            >
              <PortalItem
                powers={powers as Powers}
                law={law}
                chainId={chainId as string}
                showLowerSection={false}
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
