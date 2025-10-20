"use client";

import React, { useEffect } from "react";
import { setError, useActionStore, useErrorStore, usePowersStore } from "@/context/store";
import { Button } from "@/components/Button";
import { parseLawError, parseParamValues } from "@/utils/parsers";
import { Action, Checks, DataType, InputType, Law, Powers } from "@/context/types";
import { DynamicInput } from "@/components/DynamicInput";
import { Status } from "@/context/types";
import { setAction } from "@/context/store";
import { decodeAbiParameters, encodeAbiParameters, parseAbiParameters } from "viem";
import { SparklesIcon } from "@heroicons/react/24/outline";
import { hashAction } from "@/utils/hashAction";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { useChecks } from "@/hooks/useChecks";
import { useLaw } from "@/hooks/useLaw";
import { SimulationBox } from "./SimulationBox";

type DynamicFormProps = {
  law: Law;
  params: {
    varName: string;
    dataType: DataType;
    }[]; 
  status: Status;
  checks: Checks;
  onCheck: (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => void;
};

export function DynamicForm({law, params, status, checks, onCheck}: DynamicFormProps) {
  const action = useActionStore();
  const error = useErrorStore()
  const dataTypes = params.map(param => param.dataType) 
  const powers = usePowersStore();
  const {wallets, ready} = useWallets();
  const { simulation, simulate } = useLaw();

  const handleChange = (input: InputType | InputType[], index: number) => {
    // console.log("@handleChange: ", {input, index, action})
    let currentInput = action.paramValues 
    currentInput ? currentInput[index] = input : currentInput = [input]
    
    setAction({...action, paramValues: currentInput, upToDate: false})
  }

  useEffect(() => {
    // Only run if we have valid callData and it's not already processed
    if (!action.callData || action.callData === '0x0' || action.upToDate) {
      return;
    }

    // Additional guard: only process if dataTypes match the law
    if (dataTypes.length === 0) {
      return;
    }

    // console.log("useEffect triggered at DynamicForm")
    try {
      const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), action.callData as `0x${string}`);
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
      // Only set action if we haven't already (prevent infinite loop on decode errors)
      if (!action.upToDate) {
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
    }  
  }, [law.index, action.callData, action.upToDate])


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
      onCheck(law, lawCalldata, BigInt(action.nonce as string), wallets, powers)
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
        <label htmlFor="nonce" className="text-xs text-slate-600 ps-3 min-w-28 ">Nonce</label>
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
        <label htmlFor="uri" className="text-xs text-slate-600 ps-3 min-w-28 ">Description</label>
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

      { (!action.upToDate || checks == undefined) &&  (
        <div className="w-full flex flex-row justify-center items-center px-6 py-2 pt-6" help-nav-item="run-checks">
          <Button 
            size={0} 
            showBorder={true} 
            role={6}
            filled={false}
            selected={true}
            onClick={(e) => {
              e.preventDefault();
              handleSimulate(law, action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string)
            }}
            statusButton={ status == 'success' ? 'idle' : status } > 
            Check 
            </Button>
          </div>  
        )}
      </form>
      }
      
      { 
        simulation && action?.upToDate && <SimulationBox law = {law} simulation = {simulation} />
      } 

    </>
  );
}