"use client";

import React, { useEffect, useState } from "react";
import { setError, useActionStore, useErrorStore } from "@/context/store";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon, PlusIcon, SparklesIcon, UserGroupIcon, CheckIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { SectionText } from "@/components/StandardFonts";
import { useChainId, useChains } from 'wagmi'
import { decodeAbiParameters, parseAbiParameters, toHex } from "viem";
import { parseChainId, parseLawError, parseParamValues, parseRole, parseTrueFalse, shorterDescription } from "@/utils/parsers";
import { Checks, DataType, Execution, InputType, Law, LawSimulation, Powers } from "@/context/types";
import { DynamicInput } from "@/components/DynamicInput";
import { SimulationBox } from "@/components/SimulationBox";
import { Status } from "@/context/types";
import { setAction } from "@/context/store";
import { useParams, useRouter } from "next/navigation";
import { hashAction } from "@/utils/hashAction";
import HeaderLaw from '@/components/HeaderLaw';
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo';

type DynamicFormProps = {
  powers: Powers;
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

export function DynamicForm({powers, law, checks, params, status, simulation, selectedExecution, onChange, onSimulate, onExecute}: DynamicFormProps) {
  const action = useActionStore();
  const error = useErrorStore()
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  const dataTypes = params.map(param => param.dataType) 
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))

  // console.log("@DynamicForm:", {checks, action})
  console.log("@DynamicForm:", {error})

  const handleChange = (input: InputType | InputType[], index: number) => {
    // console.log("@handleChange: ", {input, index, action})
    let currentInput = action.paramValues 
    currentInput ? currentInput[index] = input : currentInput = [input]
    
    setAction({...action, paramValues: currentInput, upToDate: false})
  }

  useEffect(() => {
    // console.log("useEffect triggered at DynamicForm")
      try {
        const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), action.callData);
        const valuesParsed = parseParamValues(values) 
        // console.log("@DynamicForm: useEffect triggered at DynamicForm", {values, valuesParsed})
        if (dataTypes.length != valuesParsed.length) {
          // console.log("@DynamicForm: dataTypes.length != valuesParsed.length", {dataTypes, valuesParsed})
          setAction({...action, paramValues: dataTypes.map(dataType => {
            const isArray = dataType.indexOf('[]') > -1;
            if (dataType.indexOf('string') > -1) {
              return isArray ? [""] : "";
            } else if (dataType.indexOf('bool') > -1) {
              return isArray ? [false] : false;
            } else {
              return isArray ? [0] : 0;
            }
          }), upToDate: true})
        } else {
          setAction({...action, paramValues: valuesParsed, upToDate: true})
        }
      } catch(error) { 
        console.error("Error decoding abi parameters at action calldata: ", error)
        setAction({...action, paramValues: dataTypes.map(dataType => {
          const isArray = dataType.indexOf('[]') > -1;
          if (dataType.indexOf('string') > -1) {
            return isArray ? [""] : "";
          } else if (dataType.indexOf('bool') > -1) {
            return isArray ? [false] : false;
          } else {
            return isArray ? [0] : 0;
          }
        }), upToDate: true})
      }  
  }, [ , law ])

  return (
    <> 
    {
      action && 
      <form onSubmit={(e) => e.preventDefault()} className="w-full">
        {
          params.map((param, index) => {
            // console.log("@dynamic form", {param, index, paramValues: action.paramValues, values: action.paramValues && action.paramValues[index] !== undefined ? action.paramValues[index] : []})
            
            return (
              <DynamicInput 
                  dataType = {param.dataType} 
                  varName = {param.varName} 
                  index = {index}
                  values = {action.paramValues && action.paramValues[index] !== undefined ? action.paramValues[index] : ""}
                  onChange = {(input)=> {handleChange(input, index)}}
                  key = {index}
                  />
            )
          })
        }
      <div className="w-full mt-4 flex flex-row justify-center items-center ps-3 pe-6 gap-3">
        <label htmlFor="nonce" className="text-xs text-slate-600 ps-3 min-w-20 ">Nonce</label>
        <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-2 outline outline-1 outline-slate-300">
            <input 
              type="number"   
              name={`nonce`} 
              id={`nonce`}
              value = {action.nonce}
              className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
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

        <div className="w-full mt-4 flex flex-row justify-center items-center ps-3 pe-6 gap-3">
        <label htmlFor="uri" className="text-xs text-slate-600 ps-3 min-w-20 ">Description</label>
          <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-2 outline outline-1 outline-slate-300">
              <input 
                type="text"
                name="uri" 
                id="uri"
                value={action.description}
                className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
                placeholder="Enter URI to file with notes on the action here."
                onChange={(event) => {  
                  event.preventDefault()
                  setAction({...action, description: event.target.value, upToDate: false}); 
                }} />
            </div>
        </div>
      

      {/* Errors */}
      { error.error &&
        <div className="w-full flex flex-col gap-0 justify-start items-center text-red text-center text-sm text-red-800 pt-8 pb-4 px-8">
          <div>
            {`Failed check${parseLawError(error.error)}`}     
          </div>
        </div>
      }

        <div className="w-full flex flex-row justify-center items-center px-6 py-2 pt-6" help-nav-item="run-checks">
          <Button 
            size={0} 
            showBorder={true} 
            role={6}
            filled={false}
            selected={true}
            onClick={(e) => {
              e.preventDefault();
              onSimulate(action.paramValues ? action.paramValues : [], BigInt(action.nonce), action.description)
            }} 
            statusButton={
               action && action.description && action.description.length > 0 && action.nonce && action.paramValues ? 'idle' : 'disabled'
              }> 
            Check 
          </Button>
        </div>  
      </form>
      }
      {/* dynamic form end */}

    </>
  );
}