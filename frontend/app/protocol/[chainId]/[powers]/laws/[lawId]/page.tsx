"use client";

import React, { useEffect, useState } from "react";
import { LawBox } from "./LawBox";
import { setAction, setError, useActionStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { InputType, Law, Powers, Checks, Action, ActionVote, Role } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { LoadingBox } from "@/components/LoadingBox";
import { LawActions } from "./LawActions";
import { useChecks } from "@/hooks/useChecks";
import { TitleText } from "@/components/StandardFonts";
import { hashAction } from "@/utils/hashAction";
import { Voting } from "@/components/Voting";
import { Votes } from "@/components/Votes";

const Page = () => {
  const {wallets, ready} = useWallets();
  const action = useActionStore();  
  const { powers: addressPowers, lawId } = useParams<{ powers: string, lawId: string }>()  
  const { powers, fetchPowers, status: statusPowers, fetchActions, fetchRoles } = usePowers() 
  const { fetchChecks, checks } = useChecks()
  const { status: statusLaw, error: errorUseLaw, simulation, actionVote, resetStatus, simulate, request, propose, fetchVoteData } = useLaw();
  const law = powers?.laws?.find(law => BigInt(law.index) == BigInt(lawId)) 

  // console.log("@Page: waypoint 0", {law, action, actionVote, statusLaw, statusPowers, errorUseLaw, powers, checks})

  // Helper function to map state numbers to their labels
  const getStateLabel = (state: number | undefined): string => {
    switch (state) {
      case 0: return "Non Existent"
      case 1: return "Proposed"
      case 2: return "Cancelled"
      case 3: return "Active Vote"
      case 4: return "Defeated"
      case 5: return "Succeeded"
      case 6: return "Requested"
      case 7: return "Fulfilled"
      default: return "Non Existent"
    }
  }

  useEffect(() => {
    if (addressPowers) {
      // console.log("useEffect, fetchPowers triggered at Law page:", {addressPowers})
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers])

  useEffect(() => {
     if (statusLaw == "success") {
      resetStatus()
    }
  }, [statusLaw])

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
          // console.log("Handle Simulate waypoint 2c")
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
        
        try {
        // simulating law. 
          const success = await simulate(
            wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
            newAction.callData as `0x${string}`,
            BigInt(newAction.nonce as string),
            law
          )
          if (success) { 
            setAction({...newAction, state: 8})
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
    if (!law) return
    
    setError({error: null})
    let lawCalldata: `0x${string}` = '0x0'
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }
 
    if (lawCalldata && ready && wallets && powers?.contractAddress) {
      const success = await propose(
        law.index as bigint,
        lawCalldata,
        nonce,
        description,
        powers as Powers
        )
      if (success) {
        setAction({...action, state: 3})
        console.log("Handle Propose", {action})
      }
      console.log("@handlePropose: waypoint 1", {paramValues, nonce, description})
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
      if (success) {
        setAction({...action, state: 6})
        console.log("Handle Execute", {action})
      }
      console.log("@handleExecute: waypoint 1", {paramValues, nonce, description})
  };

  // resetting DynamicForm and fetching executions when switching laws: 
  useEffect(() => {
    if (law) {
      // console.log("useEffect triggered at Law page:", action.dataTypes, dataTypes)
      const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != law.params?.[index]?.dataType) : [true] 
      // console.log("useEffect triggered at Law page:", {dissimilarTypes, action, law})
      
      if (dissimilarTypes.find(type => type == true)) {
        // console.log("useEffect triggered at Law page, action.dataTypes != dataTypes")
        setAction({
          lawId: law.index,
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: [],
          nonce: '0',
          callData: '0x0',
          upToDate: false
        })
      } else {
        // console.log("useEffect triggered at Law page, action.dataTypes == dataTypes")
        setAction({
          ...action,  
          lawId: law.index,
          upToDate: false
        })
      }
      resetStatus()
      setError({error: null})
    }
  }, [law])




  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])


  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16">
        {/* title */}
        <div className="w-full flex flex-col justify-start items-center px-4">
          <TitleText 
            title="Act"
            subtitle="Create a new action. Execution is restricted by the conditions of the law."
            size={2}
          />
        </div>

        {/* Action info - shown only when action is up to date */}
        
          <div className="w-full flex flex-row justify-between items-end ps-4 pe-12 py-2 text-sm text-slate-600">
            <div className="flex flex-col gap-1">
              <div className="flex flex-row gap-2">
                <span className="font-semibold">ActionId:</span>
                <span className="font-mono">
                  {action?.actionId ? `${action?.actionId.slice(0, 10)}...${action?.actionId.slice(-8)}` : '-'}
                </span>
              </div>
              <div className="flex flex-row gap-2">
                <span className="font-semibold">Status:</span>
                <span className={`px-2 rounded ${
                  action?.state === undefined ? 'text-slate-500 bg-slate-100' : // NonExistent
                  action?.state === 1 ? 'text-blue-600 bg-blue-100' : // Proposed
                  action?.state === 2 ? 'text-red-600 bg-red-100' : // Cancelled  
                  action?.state === 3 ? 'text-orange-600 bg-orange-100' : // Active
                  action?.state === 4 ? 'text-red-600 bg-red-100' : // Defeated
                  action?.state === 5 ? 'text-green-600 bg-green-100' : // Succeeded
                  action?.state === 6 ? 'text-blue-600 bg-blue-100' : // Requested
                  action?.state === 7 ? 'text-green-600 bg-green-100' : // Fulfilled
                  'text-slate-500 bg-slate-100'
                }`}>
                  {getStateLabel(action?.state)}
                </span>
              </div>
            </div>
            <button
              onClick={
                () => {
                  powers && fetchActions(powers as Powers)
                  fetchVoteData(action, powers as Powers)
                  powers && fetchRoles(powers as Powers)
                }
              }
              disabled={statusPowers === 'pending'}
              className="flex items-center justify-center w-9 h-9 bg-slate-50 border border-slate-300 rounded-md hover:bg-slate-100 transition-colors disabled:opacity-50 flex-shrink-0"
              aria-label="Refetch action state"
            >
              <svg 
                className={`h-5 w-5 text-slate-600 ${statusPowers === 'pending' ? 'animate-spin' : ''}`} 
                xmlns="http://www.w3.org/2000/svg" 
                fill="none" 
                viewBox="0 0 24 24" 
                stroke="currentColor"
              >
                <path 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeWidth={2} 
                  d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" 
                />
              </svg>
            </button>
          </div>

        <div className="w-full flex min-h-fit ps-4 pe-12"> 
          {
          statusPowers == "pending" ?
          <div className = "w-full flex flex-col justify-center items-center p-4 border border-slate-300 bg-slate-50 rounded-md"> 
            <LoadingBox />
          </div>
          :   
          law && 
          <LawBox 
              powers = {powers as Powers}
              law = {law}
              checks = {checks as Checks} 
              params = {law.params || []}
              status = {statusLaw}  
              onPropose = {(paramValues, nonce, description) => handlePropose(paramValues, nonce, description)}
              simulation = {simulation} 
              onChange = {() => { 
                setAction({...action, upToDate: false})
                }
              }
              onSimulate = {(paramValues, nonce, description) => handleSimulate(law, paramValues, nonce, description)} 
              onExecute = {(paramValues, nonce, description) => handleExecute(law, paramValues, nonce, description)}
              /> 
            }
        </div>

        {/* Voting, Latest Actions section */}
        <div className="w-full flex flex-col gap-3 justify-start items-center ps-4 pe-12 pb-20"> 
          {/* Conditional if a law.condition.quorum >0 && action.state != 0 && action.upToDate: show vote and voting */}
          {Number(law?.conditions?.quorum) > 0 && action?.state != 0 && action?.state != 8 && (
            <>
              <Voting powers={powers} status={statusLaw} actionVote={actionVote as ActionVote} />
              <Votes actionId={action?.actionId as string} lawId={law?.index as bigint} action={action as Action} powers={powers} status={statusLaw} />
            </>
          )}
          
          {/* Latest actions */}
          {law && <LawActions lawId = {law.index} powers = {powers} status = {statusLaw} onRefresh={() => fetchActions(powers as Powers)}/>}
        </div>        
    </main>
  )

}

export default Page

