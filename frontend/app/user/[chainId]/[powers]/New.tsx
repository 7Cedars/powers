'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { UserItem } from './UserItem'
import { InputType, Law, Powers, Checks } from '@/context/types'
import { useErrorStore, useActionStore, useChecksStore, setError, setAction } from '@/context/store'
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { useChecks } from '@/hooks/useChecks'
import { useLaw } from '@/hooks/useLaw'
import { usePowers } from '@/hooks/usePowers'
import { ArrowLeftIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
import { LawBox } from './LawBox'
import HeaderLaw from '@/components/HeaderLaw'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'
import { useChains } from 'wagmi'
import { useAction } from '@/hooks/useAction'
import { hashAction } from '@/utils/hashAction'

export default function New({hasRoles, powers, refetchPowers, fetchActions, resetRef}: {hasRoles: {role: bigint, since: bigint}[], powers: Powers, refetchPowers: (address: `0x${string}`) => void, fetchActions: (powers: Powers) => void, resetRef: React.MutableRefObject<(() => void) | null>}) {
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>()
  const { authenticated } = usePrivy()
  const {wallets, ready} = useWallets();
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === Number(chainId))
  const action = useActionStore();
  const { fetchChecks, status: statusChecks, checks } = useChecks()
  const { fetchAction } = useAction()
  const { status: statusLaw, error: errorUseLaw, simulation, resetStatus, simulate, propose, request } = useLaw();

  console.log("@New:", {powers, action})
  
  // State to track selected law
  const [selectedLaw, setSelectedLaw] = useState<Law | null>(null)
  const [reloading, setReloading] = useState(false)

  // Reset function to go back to list view
  const resetSelection = useCallback(() => {
    setSelectedLaw(null)
  }, [])

  // Assign reset function to ref
  React.useEffect(() => {
    resetRef.current = resetSelection
    return () => {
      resetRef.current = null
    }
  }, [resetSelection, resetRef])

  // Filter laws based on criteria
  // console.log("@New, powers", powers)
  // console.log("@New, hasRoles", hasRoles)
  const finalFilteredLaws = powers?.laws?.filter(
    law => law.conditions?.needFulfilled == 0n && law.active && hasRoles.some(role => role.role == law.conditions?.allowedRole)
  )
  // console.log("@New, filteredLaws", finalFilteredLaws)

  // Get laws that will be enabled by executing the selected law
  const enabledLaws = selectedLaw && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needFulfilled == selectedLaw.index
    ) : []

  // Get laws that will be blocked by executing the selected law
  const blockedLaws = selectedLaw && powers?.laws ? 
    powers.laws.filter(law => 
      law.active && 
      law.conditions?.needNotFulfilled == selectedLaw.index
    ) : []

  // console.log("@New, selectedLaw", selectedLaw)
  // console.log("@New, enabledLaws", enabledLaws)
  // console.log("@New, blockedLaws", blockedLaws)

  // Reset DynamicForm and fetch executions when switching laws
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
      resetStatus()
    }
  }, [selectedLaw])

  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])

  // Handle reload button click
  const handleReload = async () => {
    if (!addressPowers) return
    
    setReloading(true)
    setError({error: null})
    
    try {
      // console.log("@New: Starting reload of laws")
      await refetchPowers(addressPowers as `0x${string}`)
      //  console.log("@New: Successfully reloaded laws")
    } catch (error) {
      console.error("Error reloading laws:", error)
      setError({error: error as Error})
    } finally {
      setReloading(false)
    }
  }

  const handleSimulate = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    if (!selectedLaw) return
    console.log("@handleSimulate: waypoint 0", {paramValues, nonce, description})

    
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    console.log("@handleSimulate: waypoint 1", {paramValues, nonce, description})

    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(selectedLaw.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }

    console.log("@handleSimulate: waypoint 1.5", {lawCalldata, ready, wallets, powers})
    if (lawCalldata && ready && wallets && powers?.contractAddress) { 
      fetchChecks(selectedLaw, lawCalldata, BigInt(action.nonce as string), wallets, powers)
      const actionId = hashAction(selectedLaw.index, lawCalldata, BigInt(action.nonce as string)).toString()
      const actionData = await fetchAction({actionId: actionId, lawId: selectedLaw.index}, powers as Powers)
      
      console.log("@handleSimulate: waypoint 2", {actionData, actionId})

      setAction({
        ...action,
        state: actionData?.state == undefined ? 0 : actionData.state,
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
          BigInt(action.nonce as string),
          selectedLaw
        )
      } catch (error) {
        setError({error: error as Error})
      }
    }
  };

  const handlePropose = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    console.log("@handlePropose: waypoint 0", {paramValues, nonce, description})
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
      propose(
        selectedLaw.index as bigint,
        lawCalldata,
        nonce,
        description,
        powers as Powers
      )
      console.log("@handlePropose: waypoint 1", {paramValues, nonce, description})
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

    request(
      selectedLaw, 
      lawCalldata as `0x${string}`,
      nonce,
      description
    )
  };


  // If a law is selected, show the either LawBox or ProposalBox
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
              statusChecks={statusChecks}
              params={selectedLaw.params || []}
              status={statusLaw}
              simulation={simulation}
              onChange={() => {
                setAction({...action, upToDate: false})
              }}
              onSimulate={handleSimulate}
              onExecute={handleExecute}
              onPropose={handlePropose}
            />
            
            {/* Enables section */}
            {enabledLaws.length > 0 && (
              <div className="mt-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Execution <b>enables</b> the following laws: </h3>
                <div className="space-y-2">
                  {enabledLaws.map((law: Law) => (
                    <div 
                      key={`enabled-${law.lawAddress}-${law.index}`}
                      className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
                    >
                      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                        <HeaderLaw
                          powers={powers as Powers}
                          lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
                          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
                          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
                          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
                          contractAddress={law.lawAddress}
                          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            
            {/* Blocks section */}
            {blockedLaws.length > 0 && (
              <div className="mt-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Execution <b>blocks</b> the following laws: </h3>
                <div className="space-y-2">
                  {blockedLaws.map((law: Law) => (
                    <div 
                      key={`blocked-${law.lawAddress}-${law.index}`}
                      className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
                    >
                      <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
                        <HeaderLaw
                          powers={powers as Powers}
                          lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
                          roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
                          numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
                          description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
                          contractAddress={law.lawAddress}
                          blockExplorerUrl={supportedChain?.blockExplorers?.default.url}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  /// Error messages /// 

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
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-800">New</h2>
              <p className="text-sm text-slate-600">Available laws for your roles</p>
            </div>
            <button 
              onClick={handleReload}
              disabled={reloading}
              className="p-2 text-slate-500 hover:text-slate-700 transition-colors disabled:opacity-50"
            >
              <ArrowPathIcon className={`w-5 h-5 ${reloading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
        
        {/* Render UserItem components for each filtered law */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {reloading ? (
            <div className="p-4">
              <div className="flex items-center justify-center py-8">
                <div className="text-sm text-slate-500">Loading laws...</div>
              </div>
            </div>
          ) : (
            finalFilteredLaws && finalFilteredLaws.map((law: Law, index: number) => (
              <div 
                key={`${law.lawAddress}-${law.index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => setSelectedLaw(law)}
              >
                <UserItem
                  powers={powers as Powers}
                  law={law}
                  chainId={chainId as string}
                  showLowerSection={false}
                />
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
