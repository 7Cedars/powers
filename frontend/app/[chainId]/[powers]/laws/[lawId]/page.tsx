"use client";

import React, { Children, useEffect } from "react";
import { LawBox } from "@/app/[chainId]/[powers]/laws/[lawId]/LawBox";
import { setAction, setError, useActionStore, useErrorStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useChecks } from "@/hooks/useChecks";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { InputType, Law, Powers } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { LoadingBox } from "@/components/LoadingBox";
import { Executions } from "./Executions";

const Page = () => {
  const {wallets, ready} = useWallets();
  const action = useActionStore();;

  const { powers: addressPowers, lawId } = useParams<{ powers: string, lawId: string }>()  
  
  const { powers, fetchPowers, checkSingleLaw, status: statusPowers } = usePowers()
  const { status: statusLaw, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, simulate, execute } = useLaw();
  const { checks, fetchChecks } = useChecks(powers as Powers); 
  const law = powers?.laws?.find(law => law.index == BigInt(lawId))
  
  console.log( "@Law page FLOW: ", {executions, errorUseLaw, checks, law, statusLaw, action, ready, wallets, addressPowers, simulation})
  
  useEffect(() => {
    if (!powers) {
      // console.log("useEffect, fetchPowers triggered at Law page:", {addressPowers})
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [powers])

 
  const handleSimulate = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
      // console.log("Handle Simulate called:", {paramValues, nonce})
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
      if (lawCalldata && ready && wallets && powers?.contractAddress) { 
        // console.log("Handle Simulate waypoint 3a")
        setAction({
          lawId: law.index,
          caller: wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: paramValues,
          nonce: nonce.toString(),
          uri: description,
          callData: lawCalldata,
          upToDate: true
        })

        // console.log("Handle Simulate waypoint 3b", {action, wallets, lawCalldata, nonce, law})
        fetchChecks(law, action.callData as `0x${string}`, BigInt(action.nonce), wallets, powers as Powers) 
        
        try {
        // simulating law. 
          simulate(
            wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
            action.callData as `0x${string}`,
            BigInt(action.nonce),
            law
          )
        } catch (error) {
          // console.log("Handle Simulate waypoint 3c")
          setError({error: error as Error})
        }

        
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

      execute(
        law, 
        lawCalldata as `0x${string}`,
        nonce,
        description
      )
  };

  // resetting lawBox and fetching executions when switching laws: 
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
      fetchExecutions(law)
      // fetchChecks(law, action.callData as `0x${string}`, action.nonce, wallets, powers as Powers)
      resetStatus()
    }
  }, [, law])


  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16">
        <div className="w-full flex my-2 min-h-fit ps-4 pe-12"> 
          {
          statusPowers == "pending" ?
          <div className = "w-full flex flex-col justify-center items-center p-4 border border-slate-300 bg-slate-50 rounded-md"> 
            <LoadingBox />
          </div>
          :   
          law && 
          <LawBox 
              law = {law}
              checks = {checks || {}} 
              params = {law.params || []}
              status = {statusLaw}  
              simulation = {simulation} 
              onChange = {() => { 
                setAction({...action, upToDate: false})
                }
              }
              onSimulate = {(paramValues, nonce, description) => handleSimulate(law, paramValues, nonce, description)} 
              onExecute = {(paramValues, nonce, description) => handleExecute(law, paramValues, nonce, description)}/> 
              } 
        </div>

        {/* right panel: info boxes should only reads from zustand.  */}
        <div className="w-full flex flex-col justify-start items-center ps-4 pe-12"> 
          <div className="w-full max-h-fit py-1 grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md">
            <Executions lawExecutions = {executions} law = {law} status = {statusLaw}/>
          </div>
        </div>
        
    </main>
  )

}

export default Page

