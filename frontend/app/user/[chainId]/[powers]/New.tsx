'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { usePrivy } from '@privy-io/react-auth'
import { useWallets } from '@privy-io/react-auth'
import { UserItem } from './UserItem'
import { InputType, Law, Powers, Checks, Action } from '@/context/types'
import { useActionStore, setError, setAction, useStatusStore, usePowersStore } from '@/context/store'
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { useChecks } from '@/hooks/useChecks'
import { useLaw } from '@/hooks/useLaw'
import { ArrowLeftIcon } from '@heroicons/react/24/outline'
import { UserLawBox } from './UserLawBox'
import { hashAction } from '@/utils/hashAction'

export default function New({hasRoles, resetRef}: {hasRoles: bigint[], resetRef: React.MutableRefObject<(() => void) | null>}) {
  const { chainId } = useParams<{ chainId: string }>()
  const powers = usePowersStore();
  const {wallets, ready} = useWallets();
  const { authenticated } = usePrivy()

  const [selectedLaw, setSelectedLaw] = useState<Law | null>(null);
  const { fetchChecks, status: statusChecks, checks } = useChecks()
  const { simulate, propose, request } = useLaw();
  const finalFilteredLaws = powers?.laws?.filter(law => 
    law.active && 
    law.conditions && 
    hasRoles.some(role => role === law?.conditions?.allowedRole as bigint)
  )
  const status = useStatusStore(); 
  const action = useActionStore();
  
  console.log("@New, waypoint 0", {powers, finalFilteredLaws, hasRoles, wallets, ready})

  // Reset function to go back to list view
  const resetSelection = useCallback(() => {
    setSelectedLaw(null)
  }, [])

  // Assign reset function to ref
    useEffect(() => {
      resetRef.current = resetSelection
      return () => {
        resetRef.current = null
      }
    }, [resetSelection, resetRef])

  const handleSimulate = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    // console.log("Handle Simulate called:", {paramValues, nonce, law})
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    // console.log("Handle Simulate waypoint 1")
    if (paramValues.length > 0 && paramValues) {
      try {
        // console.log("Handle Simulate waypoint 2a")
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 
        // console.log("Handle Simulate waypoint 2b", {lawCalldata}) 
      } catch (error) {
        console.log("Handle Simulate waypoint 2c")
        setError({error: error as Error})
      }
    } else {
      // console.log("Handle Simulate waypoint 2d")
      lawCalldata = '0x0'
    }
    // resetting store
    // console.log("Handle Simulate waypoint 3a", {lawCalldata, ready, wallets, powers})
    if (lawCalldata && ready && wallets && powers?.contractAddress) { 
      fetchChecks(law, lawCalldata, BigInt(action.nonce as string), wallets, powers)
      const actionId = hashAction(law.index, lawCalldata, BigInt(action.nonce as string)).toString()

      const newAction: Action = {
        ...action,
        actionId: actionId,
        state: 0, // non existent
        lawId: law.index,
        caller: wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
        dataTypes: law.params?.map(param => param.dataType),
        paramValues,
        nonce: nonce.toString(),
        description,
        callData: lawCalldata,
        upToDate: true
      }

      // console.log("Handle Simulate waypoint 3b")
      setAction(newAction)
      // fetchVoteData(newAction, powers as Powers)

      try {
      // simulating law. 
        const success = await simulate(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
          newAction.callData as `0x${string}`,
          BigInt(newAction.nonce as string),
          law
        )
        if (success) { 
          // setAction({...newAction, state: 8})
          console.log("Handle Simulate", {newAction})
        }
        // fetchAction(newAction, powers as Powers, true)
      } catch (error) {
        // console.log("Handle Simulate waypoint 3c")
        setError({error: error as Error})
      }
    }
  };

  const handlePropose = async (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    console.log("@handlePropose: waypoint 0", {paramValues, nonce, description})
    if (!selectedLaw) return
    
    setError({error: null})
    let lawCalldata: `0x${string}` = '0x0'
    
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
      const success = await propose(
        selectedLaw.index as bigint,
        lawCalldata,
        nonce,
        description,
        powers as Powers
        )
      // console.log("@handlePropose: waypoint 1", {paramValues, nonce, description})
    }
  };

  const handleExecute = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
      // console.log("Handle Execute called:", {paramValues, nonce})
      setError({error: null})
      let lawCalldata: `0x${string}` | undefined
      // console.log("Handle Simulate waypoint 1")
      if (paramValues.length > 0 && paramValues) {
        try {
          // console.log("Handle Simulate waypoint 2a")
          lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 
          // console.log("Handle Simulate waypoint 2b", {lawCalldata})
        } catch (error) {
          // console.log("Handle Simulate waypoint 2c")
          setError({error: error as Error})
        }
      } else {
        // console.log("Handle Simulate waypoint 2d")
        lawCalldata = '0x0'
      }

      const success = await request(
        law, 
        lawCalldata as `0x${string}`,
        nonce,
        description
      )
      console.log("@handleExecute: waypoint 1", {paramValues, nonce, description})
  };

  // resetting DynamicForm and fetching executions when switching laws: 
  useEffect(() => {
    if (selectedLaw) {
      // console.log("useEffect triggered at Law page:", action.dataTypes, dataTypes)
      const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != selectedLaw.params?.[index]?.dataType) : [true] 
      // console.log("useEffect triggered at Law page:", {dissimilarTypes, action, law})
      
      if (dissimilarTypes.find(type => type == true)) {
        // console.log("useEffect triggered at Law page, action.dataTypes != dataTypes")
        setAction({
          lawId: selectedLaw.index,
          dataTypes: selectedLaw.params?.map(param => param.dataType),
          paramValues: [],
          nonce: '0',
          callData: '0x0',
          upToDate: false
        })
      } else {
        // console.log("useEffect triggered at Law page, action.dataTypes == dataTypes")
        setAction({
          ...action,  
          lawId: selectedLaw.index,
          upToDate: false
        })
      }
      setError({error: null})
    }
  }, [selectedLaw])  

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
            <UserLawBox 
              powers={powers as Powers}
              law={selectedLaw}
              checks={checks as Checks}
              status={statusChecks}
              statusChecks={statusChecks}
              params={selectedLaw.params || []}
              onChange={() => {
                setAction({...action, upToDate: false})
              }}
              onSimulate={(paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => handleSimulate(selectedLaw, paramValues, nonce, description)}
              onExecute={(paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => handleExecute(selectedLaw, paramValues, nonce, description)}
              onPropose={handlePropose}
            />

            {/* Enables section */}
            {/* {selectedLaw.conditions?.needFulfilled && selectedLaw.conditions.needFulfilled.length > 0 && (
              <div className="mt-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3 italic">Execution <b>enables</b> the following laws: </h3>
                <div className="space-y-2">
                  {selectedLaw.conditions.enabledLaws.map((law: Law) => (
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
            )} */}
            
            {/* Blocks section */}
            {/* {blockedLaws.length > 0 && (
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
            )} */}
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
          </div>
        </div>
        
        {/* Render UserItem components for each filtered law */}
        <div className="max-h-[calc(100vh-200px)] overflow-y-auto divide-y divide-slate-200">
          {status.status === "pending" ? (
            <div className="p-4">
              <div className="flex items-center justify-center py-8">
                <div className="text-sm text-slate-500">Loading laws...</div>
              </div>
            </div>
          ) : (
            finalFilteredLaws && finalFilteredLaws.map((law: Law) => (
              <div 
                key={`${law.lawAddress}-${law.index}`}
                className="cursor-pointer hover:bg-slate-100 transition-colors rounded-md p-2"
                onClick={() => setSelectedLaw(law)}
              >
                <UserItem 
     powers={powers}
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
