"use client";

import React, { useEffect, useState } from "react";
import { setError, useActionStore, useErrorStore } from "@/context/store";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon, PlusIcon, SparklesIcon } from "@heroicons/react/24/outline";
import { SectionText } from "@/components/StandardFonts";
import { useChainId, useChains } from 'wagmi'
import { decodeAbiParameters, parseAbiParameters, toHex } from "viem";
import { parseChainId, parseLawError, parseParamValues, parseRole, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation } from "@/context/types";
import { DynamicInput } from "@/app/[chainId]/[powers]/laws/[lawId]/DynamicInput";
import { SimulationBox } from "@/components/SimulationBox";
import { Status } from "@/context/types";
import { setAction } from "@/context/store";
import { useParams } from "next/navigation";

type LawBoxProps = {
  law: Law;
  checks: Checks;
  params: {
    varName: string;
    dataType: DataType;
    }[]; 
  simulation?: LawSimulation;
  selectedExecution?: Execution | undefined;
  status: Status; 
  // onChange: (input: InputType | InputType[]) => void;
  onChange: () => void;
  onSimulate: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
  onExecute: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
};

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600",
] 
export function LawBox({law, checks, params, status, simulation, selectedExecution, onChange, onSimulate, onExecute}: LawBoxProps) {
  const action = useActionStore();
  const error = useErrorStore()
  const { chainId } = useParams<{ chainId: string }>()
  const dataTypes = params.map(param => param.dataType) 
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  // console.log("@LawBox:", {law, action, status, checks, selectedExecution, dataTypes, error, params})

  const handleChange = (input: InputType | InputType[], index: number) => {
    let currentInput = action.paramValues 
    currentInput ? currentInput[index] = input : currentInput = [input]
    
    setAction({...action, paramValues: currentInput, upToDate: false})
  }

  useEffect(() => {
    // console.log("useEffect triggered at LawBox")
      try {
        const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), action.callData);
        const valuesParsed = parseParamValues(values) 
        // console.log("@LawBox: useEffect triggered at LawBox", {values, valuesParsed})
        if (dataTypes.length != valuesParsed.length) {
          setAction({...action, paramValues: dataTypes.map(dataType => dataType == "string" ? [""] : dataType == "bool" ? [false] : [0]), upToDate: false})
        } else {
          setAction({...action, paramValues: valuesParsed, upToDate: false})
        }
      } catch(error) { 
        setAction({...action, paramValues: [], upToDate: false})
        // console.error("Error decoding abi parameters at action calldata: ", error)
      }  
  }, [ , law ])

  return (
    <main className="w-full h-full">
      <section className={`w-full h-full bg-slate-50 border ${roleColour[parseRole(law?.conditions?.allowedRole) % roleColour.length]} rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-col gap-2 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={shorterDescription(law?.nameDescription, "short")}
          subtext={shorterDescription(law?.nameDescription, "long")}
          size = {0}
        /> 
         <a
            href={`${supportedChain?.blockExplorers?.default.url}/address/${law.lawAddress}#code`} target="_blank" rel="noopener noreferrer"
            className="w-full"
          >
          <div className="flex flex-row gap-1 items-center justify-start">
            <div className="text-left text-sm text-slate-500 break-all w-fit">
              Law: {law.lawAddress }
            </div> 
              <ArrowUpRightIcon
                className="w-4 h-4 text-slate-500"
                />
            </div>
          </a>
          {selectedExecution && 
            <a
            href={`${supportedChain?.blockExplorers?.default.url}/tx/${selectedExecution.log.transactionHash}`} target="_blank" rel="noopener noreferrer"
              className="w-full"
            >
            <div className="flex flex-row gap-1 items-center justify-start">
              <div className="text-left text-sm text-slate-500 break-all w-fit">
                Tx: {selectedExecution.log.transactionHash }
              </div> 
                <ArrowUpRightIcon
                  className="w-4 h-4 text-slate-500"
                  />
              </div>
            </a>
          }
      </div>

      {/* dynamic form */}
      { 
      action && 
      <form action="" method="get" className="w-full">
        {
          params.map((param, index) => {
            // console.log("@dynamic form", {param, index, paramValues})
            
            return (
              <DynamicInput 
                  dataType = {param.dataType} 
                  varName = {param.varName} 
                  values = {action.paramValues ? action.paramValues[index] : []} 
                  onChange = {(input)=> {handleChange(input, index)}}
                  key = {index}
                  />
            )
          })
        }
      <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3">
        <label htmlFor="nonce" className="text-sm text-slate-600 ps-3 pt-1 pe-11 ">Nonce</label>
        <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-3 outline outline-1 outline-slate-300">
            <input 
              type="number"   
              name={`nonce`} 
              id={`nonce`}
              value = {action.nonce}
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
              placeholder={`Enter random number.`}
              onChange={(event) => {
                event.preventDefault()
                setAction({...action, nonce: event.target.value, upToDate: false})
              }}
            />
          </div>
          <button 
              className = "h-8 min-w-8 py-2 grow flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
              onClick = {(event) => {
                event.preventDefault()
                setAction({...action, nonce: BigInt(Math.floor(Math.random() * 1000000000000000000000000)).toString(), upToDate: false})
              }}
              > 
              <SparklesIcon className = "h-5 w-5"/> 
          </button>    
        </div>

        <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3">
        <label htmlFor="uri" className="text-sm text-slate-600 ps-3 pt-1 pe-4 ">Description</label>
          <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-3 outline outline-1 outline-slate-300">
              <input 
                type="text"
                name="uri" 
                id="uri" 
                value={action.uri}
                className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Enter URI to file with notes on the action here."
                onChange={(event) => {  
                  event.preventDefault()
                  setAction({...action, uri: event.target.value, upToDate: false}); 
                }} />
            </div>
        </div>
      

      {/* Errors */}
      { error.error && action.upToDate &&
        <div className="w-full flex flex-col gap-0 justify-start items-center text-red text-sm text-red-800 pt-8 pb-4 px-8">
          <div>
            An error occurred. This is often because the law has additional checks that did not pass or there is an error in the data provided. 
            For more details, check the console.   
          </div>
        </div>
      }

        <div className="w-full flex flex-row justify-center items-center pt-6 px-6">
          <Button 
            size={1} 
            showBorder={true} 
            role={law?.conditions?.allowedRole == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(law?.conditions?.allowedRole)}
            filled={false}
            selected={true}
            onClick={() => {
              onSimulate(action.paramValues ? action.paramValues : [], BigInt(action.nonce), action.uri)
            }} 
            statusButton={
               !action.upToDate && action.uri && action.uri.length > 0 ? 'idle' : 'disabled'
              }> 
            Check 
          </Button>
        </div>  
      </form>
      }

      {/* fetchSimulation output */}
      {simulation && <SimulationBox law = {law} simulation = {simulation} />}

      {/* execute button */}
        <div className="w-full h-fit p-6">
          <Button 
            size={1} 
            role={law?.conditions?.allowedRole == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(law?.conditions?.allowedRole)}
            onClick={() => {
              onExecute(action.paramValues ? action.paramValues : [], BigInt(action.nonce), action.uri)
            }} 
            filled={false}
            selected={true}
            statusButton={
              action.upToDate && checks.allPassed && !error.error ? 
              status : 'disabled' 
              }> 
            Execute
          </Button>
        </div>
      </section>
    </main>
  );
}
