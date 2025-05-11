"use client";

import React, { useEffect, useState } from "react";
import { LawBox } from "./LawBox";
import { ChecksBox } from "./ChecksBox";
import { Children } from "./Children";
import { Executions } from "./Executions";
import { setAction, setError, useActionStore, useErrorStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useChecks } from "@/hooks/useChecks";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { InputType, Law, Powers } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { LoadingBox } from "@/components/LoadingBox";
 
const Page = () => {
  const {wallets, ready} = useWallets();
  const action = useActionStore();;
  const error = useErrorStore()
  const { powers: addressPowers, lawId } = useParams<{ powers: string, lawId: string }>()  
  
  const { powers, fetchPowers, status: statusPowers } = usePowers()
  const { status: statusLaw, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, simulate, execute } = useLaw();
  const { checks, fetchChecks } = useChecks(powers as Powers); 
  const law = powers?.laws?.find(law => law.index == BigInt(lawId))

  // console.log( "@Law page: ", {executions, errorUseLaw, checks, law, statusLaw, action, ready, wallets, addressPowers, simulation})

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
          nonce: nonce,
          description: description,
          callData: lawCalldata,
          upToDate: true
        })

        // console.log("Handle Simulate waypoint 3b", {action, wallets, lawCalldata, nonce, law})
        fetchChecks(law, action.callData as `0x${string}`, action.nonce, wallets, powers as Powers) 
        
        try {
        // simulating law. 
        simulate(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
          action.callData as `0x${string}`,
          action.nonce,
          law
        )
        } catch (error) {
          // console.log("Handle Simulate waypoint 3c")
          setError({error: error as Error})
        }

        
      }
  };

  const handleExecute = async (law: Law) => {
      execute(
        law, 
        action.callData as `0x${string}`,
        action.nonce,
        action.description
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
          nonce: 0n,
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
    if (addressPowers) {
      fetchPowers() // addressPowers as `0x${string}`
    }
  }, [addressPowers, fetchPowers])

  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll max-w-6xl">
      <div className = "h-fit w-full mt-2">
        <GovernanceOverview law = {law} powers = {powers} /> 
      </div>
      {/* main body  */}
      <section className="w-full px-4 lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start">

        {/* left panel: writing, fetching data is done here  */}
        {
        <div className="lg:w-5/6 max-w-3xl w-full flex my-2 pb-16 min-h-fit"> 
          {statusPowers == "pending" || statusPowers == "idle" ?
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
              onExecute = {() => handleExecute(law)}/> 
              }
        </div>
        }
        
        {/* right panel: info boxes should only reads from zustand.  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 min-h-48 lg:max-h-full lg:w-96 lg:my-2 my-0 lg:flex-col lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-scroll overflow-y-hidden scroll-snap-x">
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            {powers && <ChecksBox checks = {checks} law = {law} powers = {powers} status = {statusPowers} />} 
          </div>
            {<Children law = {law} powers = {powers} status = {statusPowers}/>} 
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            {<Executions executions = {executions} law = {law} status = {statusLaw}/> }
          </div>
        </div>
        
      </section>
    </main>
  )

}

export default Page

