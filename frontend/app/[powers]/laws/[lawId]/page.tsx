"use client";

import React, { useEffect, useState } from "react";
import { LawBox } from "./LawBox";
import { ChecksBox } from "./ChecksBox";
import { Children } from "./Children";
import { Executions } from "./Executions";
import { deleteAction, setAction, useActionStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useChecks } from "@/hooks/useChecks";
import { decodeAbiParameters, encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { lawAbi } from "@/context/abi";
import { useReadContract } from "wagmi";
import { bytesToParams, parseParamValues } from "@/utils/parsers";
import { Execution, InputType, Law, Powers } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
 
const Page = () => {
  const {wallets} = useWallets();
  const { powers: addressPowers, lawId } = useParams<{ powers: string, lawId: string }>()  
  const { powers, fetchPowers } = usePowers()
  const {status, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, execute, fetchSimulation} = useLaw();
  const action = useActionStore();
  
  const {checks, fetchChecks} = useChecks(powers as Powers); 
  const [error, setError] = useState<any>();
  const [selectedExecution, setSelectedExecution] = useState<Execution | undefined>()
  const law = powers?.laws?.find(law => law.index == BigInt(lawId))

  console.log( "@Law page: ", {executions, errorUseLaw, checks, law, status, action})

  const handleSimulate = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint) => {
      // console.log("Handle Simulate called:", {paramValues, description})
      setError("")
      let lawCalldata: `0x${string}` | undefined
      // console.log("Handle Simulate waypoint 1") 
      if (paramValues.length > 0 && paramValues) {
        try {
          // console.log("Handle Simulate waypoint 2a") 
          lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues); 

        } catch (error) {
          // console.log("Handle Simulate waypoint 2b") 
          setError(error as Error)
        }
      } else {
        // console.log("Handle Simulate waypoint 2c") 
        lawCalldata = '0x0'
      }
        // resetting store
      if (lawCalldata) { 
        // console.log("Handle Simulate waypoint 3:", {lawCalldata, dataTypes, paramValues, description}) 
        setAction({
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: paramValues,
          nonce: nonce,
          callData: lawCalldata,
          upToDate: true
        })
        // console.log("Handle Simulate called, action updated?", {action})
        
        // simulating law. 
        fetchSimulation(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
          lawCalldata as `0x${string}`,
          nonce,
          law
        )

        fetchChecks(law, lawCalldata as `0x${string}`, nonce) 
      }
  };

  const handleExecute = async (law: Law, nonce: bigint) => {
      execute(
        law, 
        action.callData as `0x${string}`,
        nonce,
        action.description
      )
  };

  // resetting lawBox and fetching executions when switching laws: 
  useEffect(() => {
    if (law) {
      // console.log("useEffect triggered at Law page:", action.dataTypes, dataTypes)
      const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != law.params?.[index]?.dataType) : [true] 
      if (dissimilarTypes.find(type => type == true)) {
        // console.log("useEffect triggered at Law page, action.dataTypes != dataTypes")
        deleteAction({})
      } else {
        // console.log("useEffect triggered at Law page, action.dataTypes == dataTypes")
        setAction({
          ...action, 
          upToDate: false
        })
      }
    }
  }, [, law])

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll">
      <div className = "h-fit w-full mt-2">
        <GovernanceOverview law = {law} powers = {powers} /> 
      </div>
      {/* main body  */}
      <section className="w-full px-4 lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start">

        {/* left panel: writing, fetching data is done here  */}
        {law && 
        <div className="lg:w-5/6 max-w-3xl w-full flex my-2 pb-16 min-h-fit"> 
          {law && <LawBox 
              law = {law}
              checks = {checks || {}} 
              params = {law.params || []}
              status = {status} 
              error = {error} 
              simulation = {simulation} 
              selectedExecution = {selectedExecution}
              onChange = {() => { 
                setAction({...action, upToDate: false})
                setSelectedExecution(undefined)
                }
              }
              onSimulate = {(paramValues, nonce) => handleSimulate(law, paramValues, nonce)} 
              onExecute = {(description, nonce) => handleExecute(law, nonce)}/> 
              }
        </div>
        }
        
        {/* right panel: info boxes should only reads from zustand.  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 min-h-48 lg:max-h-full lg:w-96 lg:my-2 my-0 lg:flex-col lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-scroll overflow-y-hidden scroll-snap-x">
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            {<ChecksBox checks = {checks} law = {law} powers = {powers} />} 
          </div>
          {<Children law = {law} powers = {powers} />} 
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            <Executions executions = {executions} onClick = {(execution) => setSelectedExecution(execution) }/> 
          </div>
        </div>
        
      </section>
    </main>
  )

}

export default Page

