"use client";

import React, { useEffect, useState } from "react";
import { useActionStore } from "../../../../context/store";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { SectionText } from "@/components/StandardFonts";
import { useChainId } from 'wagmi'
import { decodeAbiParameters, parseAbiParameters, toHex } from "viem";
import { parseLawError, parseParamValues, parseRole, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation } from "@/context/types";
import { DynamicInput } from "@/app/[powers]/laws/[lawId]/DynamicInput";
import { SimulationBox } from "@/components/SimulationBox";
import { supportedChains } from "@/context/chains";
import { Status } from "@/context/types";
import { setAction } from "@/context/store";
import { LoadingBox } from "@/components/LoadingBox";

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
  error?: any;  
  // onChange: (input: InputType | InputType[]) => void;
  onChange: () => void;
  onSimulate: (paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void;
  onExecute: (description: string, nonce: bigint) => void;
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
export function LawBox({law, checks, params, status, error, simulation, selectedExecution, onChange, onSimulate, onExecute}: LawBoxProps) {
  const action = useActionStore(); 
  const dataTypes = params.map(param => param.dataType) 
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  console.log("@LawBox:", {law, action, status, checks, selectedExecution, dataTypes})

  const handleChange = (input: InputType | InputType[], index: number) => {
    let currentInput = action.paramValues 
    currentInput ? currentInput[index] = input : currentInput = [input]
    
    setAction({...action, paramValues: currentInput, upToDate: false})
  }

  useEffect(() => {
    console.log("useEffect triggered at LawBox")
      try {
        const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), action.callData);
        const valuesParsed = parseParamValues(values) 
        console.log("@LawBox: useEffect triggered at LawBox", {values, valuesParsed})
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
      <section className={`w-full h-full bg-slate-50 border ${roleColour[parseRole(law.conditions.allowedRole) % roleColour.length]} rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-col gap-2 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={shorterDescription(law?.description, "short")}
          subtext={shorterDescription(law?.description, "long")}
          size = {0}
        /> 
         <a
            href={`${supportedChain?.blockExplorerUrl}/address/${law.lawAddress}#code`} target="_blank" rel="noopener noreferrer"
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
            href={`${supportedChain?.blockExplorerUrl}/tx/${selectedExecution.log.transactionHash}`} target="_blank" rel="noopener noreferrer"
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
              value = {action.nonce == 0n ? "" : String(action.nonce)}
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
              placeholder={`Enter random number.`}
              onChange={(event) => {
                setAction({...action, nonce: BigInt(Number(event.target.value)), upToDate: false})
              }}
            />
          </div>        
        </div>

        <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 pb-4 min-h-24">
          <label htmlFor="reason" className="text-sm text-slate-600 pb-1 pe-12 ps-3">Reason</label>
          <div className="w-full h-fit flex items-center text-md justify-start rounded-md bg-white pl-3 outline outline-1 outline-slate-300">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={60} 
                value={action.description}
                className="min-w-0 p-1 ps-0 w-full text-sm text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0" 
                placeholder="Describe reason for action here."
                onChange={(event) => {  
                  setAction({...action, description: event.target.value, upToDate: false}); 
                }} />
            </div>
        </div>
      

      {/* Errors */}
      { error && 
        <div className="w-full flex flex-col gap-0 justify-start items-center text-red text-sm text-red-800 pb-4 px-6">
          There is an error with this call. Please check the console for more details.   
        </div>
      }

        <div className="w-full flex flex-row justify-center items-center pt-2 px-6">
          <Button 
            size={1} 
            showBorder={true} 
            role={law.conditions.allowedRole == 4294967295n ? 6 : Number(law.conditions.allowedRole)}
            filled={false}
            selected={true}
            onClick={() => {
              onSimulate(action.paramValues ? action.paramValues : [], action.nonce, action.description)
            }} 
            statusButton={
               !action.upToDate && action.description.length > 0 ? 'idle' : 'disabled'
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
            role={law.conditions.allowedRole == 4294967295n ? 6 : Number(law.conditions.allowedRole)}
            onClick={() => {
              onExecute(action.description, action.nonce)
            }} 
            filled={false}
            selected={true}
            statusButton={
              action.upToDate && checks.allPassed ? 
              status : 'disabled' 
              }> 
            Execute
          </Button>
        </div>
      </section>
    </main>
  );
}
