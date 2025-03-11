"use client";

import React, { useEffect, useState } from "react";
import { LawBox } from "./LawBox";
import { ChecksBox } from "./ChecksBox";
import { Children } from "./Children";
import { Executions } from "./Executions";
import { deleteAction, notUpToDate, setAction, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useChecks } from "@/hooks/useChecks";
import { decodeAbiParameters, encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { lawAbi } from "@/context/abi";
import { useReadContract } from "wagmi";
import { bytesToParams, parseParamValues } from "@/utils/parsers";
import { Execution, InputType, Law } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { GovernanceOverview } from "@/components/GovernanceOverview";
 
const Page = () => {
  const {wallets} = useWallets();
  const {status, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, execute, fetchSimulation} = useLaw();
  const action = useActionStore();
  const law = useLawStore(); 
  const {checks, fetchChecks} = useChecks(); 
  const [error, setError] = useState<any>();
  const [selectedExecution, setSelectedExecution] = useState<Execution | undefined>()
  const { data, isLoading, isError, error: errorInputParams } = useReadContract({
        abi: lawAbi,
        address: law.law,
        functionName: 'inputParams'
      })
  const params =  bytesToParams(data as `0x${string}`)  
  const dataTypes = params.map(param => param.dataType) 

  console.log( "@Law page: ", {executions, errorUseLaw, checks, law, status, errorInputParams, action})

  const handleSimulate = async (paramValues: (InputType | InputType[])[], description: string) => {
      // console.log("Handle Simulate called:", {paramValues, description})

      setError("")
      let lawCalldata: `0x${string}` | undefined
      // console.log("Handle Simulate waypoint 1") 
      if (paramValues.length > 0 && paramValues) {
        try {
          // console.log("Handle Simulate waypoint 2a") 
          lawCalldata = encodeAbiParameters(parseAbiParameters(dataTypes.toString()), paramValues); 

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
          dataTypes: dataTypes,
          paramValues: paramValues,
          description: description,
          callData: lawCalldata,
          upToDate: true
        })
        // console.log("Handle Simulate called, action updated?", {action})
        
        // simulating law. 
        fetchSimulation(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
          lawCalldata as `0x${string}`,
          description
        )

        fetchChecks(law, lawCalldata, description) 
      }
  };

  const handleExecute = async (description: string) => {
      execute(
          law.law as `0x${string}`,
          action.callData as `0x${string}`,
          description
      )
  };

  // resetting lawBox and fetching executions when switching laws:
  // note, as of now executions are not saved in memory & fetched every time. To do for later..  
  useEffect(() => {
    // console.log("useEffect triggered at Law page:", action.dataTypes, dataTypes)
    const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != dataTypes[index]) : [true] 
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
    fetchExecutions() 
    fetchChecks(law, action.callData, action.description)
    resetStatus()
  }, [, law])

  // combining error messages. 
  useEffect(() => {
    if (errorInputParams) {
      setError(errorInputParams)
    }
    if (errorUseLaw) {
      setError(errorUseLaw)
    }
  }, [errorInputParams, errorUseLaw])


  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-2 pt-16 overflow-x-scroll">
      <div className = "h-fit w-full mt-2">
        <GovernanceOverview law = {law} /> 
      </div>
      {/* main body  */}
      <section className="w-full px-4 lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start">

        {/* left panel: writing, fetching data is done here  */}
        <div className="lg:w-5/6 max-w-3xl w-full flex my-2 pb-16 min-h-fit"> 
          {checks && <LawBox 
              checks = {checks} 
              params = {params}
              status = {status} 
              error = {error} 
              simulation = {simulation} 
              selectedExecution = {selectedExecution}
              onChange = {() => { 
                notUpToDate({})
                setSelectedExecution(undefined)
                }
              }
              onSimulate = {handleSimulate} 
              onExecute = {handleExecute}/> 
              }
        </div>

        {/* right panel: info boxes should only reads from zustand.  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 min-h-48 lg:max-h-full lg:w-96 lg:my-2 my-0 lg:flex-col lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-scroll overflow-y-hidden scroll-snap-x">
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            {checks && <ChecksBox checks = {checks} />} 
          </div>
            <Children /> 
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80">
            <Executions executions = {executions} onClick = {(execution) => setSelectedExecution(execution) }/> 
          </div>
        </div>
        
      </section>
    </main>
  )

}

export default Page

