"use client";

import React, { Children, useEffect } from "react";
import { LawBox } from "@/app/[chainId]/[powers]/laws/[lawId]/LawBox";
import { setAction, setError, useActionStore, useErrorStore, useChecksStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { InputType, Law, Powers, Checks } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { LoadingBox } from "@/components/LoadingBox";
import { Executions } from "./Executions";
import { useChecks } from "@/hooks/useChecks";
import { LawLink } from "@/components/LawLink";
import { TitleText } from "@/components/StandardFonts";
import { parseTrueFalse } from "@/utils/parsers";

const Page = () => {
  const {wallets, ready} = useWallets();
  const action = useActionStore();
  const { chainChecks } = useChecksStore();
  const { powers: addressPowers, lawId } = useParams<{ powers: string, lawId: string }>()  
  const { powers, fetchPowers, status: statusPowers } = usePowers() 
  const { fetchChainChecks, status: statusChecks } = useChecks()
  const { status: statusLaw, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, simulate, execute } = useLaw();
  const law = powers?.laws?.find(law => BigInt(law.index) == BigInt(lawId))
  // console.log("@Law page: waypoint 1", {law, powers})
  // Get checks for this specific law from Zustand store
  const checks = law && chainChecks ? chainChecks.get(String(law.index)) : undefined
  
  // Debug logging to understand what's happening with checks
  // console.log( "@Law page FLOW: ", {
  //   executions, 
  //   errorUseLaw, 
  //   checks, 
  //   powers,
  //   law: law ? { index: law.index, nameDescription: law.nameDescription } : null, 
  //   statusLaw, 
  //   action, 
  //   ready, 
  //   wallets: wallets.length, 
  //   addressPowers, 
  //   simulation,
  //   chainChecks: chainChecks ? {
  //     size: chainChecks.size,
  //     keys: Array.from(chainChecks.keys()),
  //     hasLawId: lawId ? chainChecks.has(lawId) : false,
  //     hasLawIndex: law ? chainChecks.has(String(law.index)) : false
  //   } : null,
  //   lawId,
  //   lawIndex: law ? String(law.index) : null
  // })
  
  useEffect(() => {
    if (addressPowers) {
      // console.log("useEffect, fetchPowers triggered at Law page:", {addressPowers})
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers])

 
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
        fetchChainChecks(law.index, lawCalldata, BigInt(action.nonce), wallets, powers)

        // console.log("Handle Simulate waypoint 3b")
        setAction({
          ...action,
          lawId: law.index,
          caller: wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: paramValues,
          nonce: nonce.toString(),
          description: description,
          callData: lawCalldata,
          upToDate: true
        })
        // console.log("Handle Simulate waypoint 3b", {action, wallets, lawCalldata, nonce, law})
        
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
        {/* title */}
        <div className="w-full flex flex-col justify-start items-center px-4">
          <TitleText 
            title="Act"
            subtitle="Create a new action. Execution is restricted by the conditions of the law."
            size={2}
          />
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
        <div className="w-full flex flex-col gap-3 justify-start items-center ps-4 pe-12 pb-20"> 
          {law && <Executions roleId = {law.conditions?.allowedRole as bigint} lawExecutions = {executions} powers = {powers} status = {statusLaw} onRefresh={() => fetchExecutions(law)}/>}
        </div>        
    </main>
  )

}

export default Page

