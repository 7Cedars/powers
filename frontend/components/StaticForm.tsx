"use client";

import React, { useEffect } from "react";
import { setAction, setError, useActionStore, useErrorStore, usePowersStore, useStatusStore } from "@/context/store";
import { StaticInput } from "@/components/StaticInput";
import { Action, InputType, Law, Powers } from "@/context/types";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";
import { decodeAbiParameters, encodeAbiParameters, parseAbiParameters } from "viem";
import { parseLawError, parseParamValues } from "@/utils/parsers";
import { hashAction } from "@/utils/hashAction";
import { useLaw } from "@/hooks/useLaw";
import { Button } from "@/components/Button";
import { SimulationBox } from "./SimulationBox";

type StaticFormProps = {
  law?: Law;
  staticDescription?: boolean;
  onCheck: (law: Law, callData: `0x${string}`, nonce: bigint, wallets: ConnectedWallet[], powers: Powers) => void;
};

export function StaticForm({ law, staticDescription = true, onCheck }: StaticFormProps) {
  const action = useActionStore();
  const { simulation, simulate } = useLaw();
  const { wallets, ready } = useWallets();
  const powers = usePowersStore();
  const status = useStatusStore();
  const error = useErrorStore();

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
    <form action="" method="get" className="w-full">
      {
        law?.params?.map((param, index) => 
          <StaticInput 
            dataType={param.dataType} 
            varName={param.varName} 
            values={action.paramValues && action.paramValues[index] ? action.paramValues[index] : []} 
            key={index}
          />)
      }
      {/* nonce */}
      <div className="w-full mt-4 flex flex-row justify-center items-center ps-3 pe-6 gap-3">
        <label htmlFor="nonce" className="text-xs text-slate-600 ps-3 min-w-28">Nonce</label>
        <div className="w-full h-fit flex items-center text-md justify-center rounded-md ps-2 outline outline-1 outline-slate-300">
          <input 
            type="text" 
            name="nonce"
            className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0"  
            id="nonce" 
            value={action?.nonce?.toString()}
            disabled={true}
          />
        </div>
      </div>

      {/* reason */}
      {staticDescription && 
      <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3 min-h-24">
        <label htmlFor="reason" className="text-xs text-slate-600 ps-3 min-w-28 pt-1">Description</label>
        <div className="w-full flex items-center rounded-md outline outline-1 outline-slate-300">
          <textarea 
            name="reason" 
            id="reason" 
            rows={5} 
            cols={25} 
            value={action.description}
            className="w-full py-1.5 ps-2 pe-3 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
            placeholder="Enter URI to file with notes on the action here."
            disabled={true} 
          />
        </div>
      </div>
      }

            {/* Errors */}
      { error.error &&
        <div className="w-full flex flex-col gap-0 justify-start items-center text-red text-center text-sm text-red-800 pt-8 pb-4 px-8">
          <div>
            {`Failed check${parseLawError(error.error)}`}     
          </div>
        </div>
      }

      { (!action.upToDate) &&  (
        <div className="w-full flex flex-row justify-center items-center px-6 py-2 pt-6" help-nav-item="run-checks">
          <Button 
            size={0} 
            showBorder={true} 
            role={6}
            filled={false}
            selected={true}
            onClick={(e) => {
              e.preventDefault();
              handleSimulate(law as Law, action.paramValues ? action.paramValues : [], BigInt(action.nonce as string), action.description as string)
            }}
            statusButton={ status.status == 'success' ? 'idle' : status.status } > 
            Check 
            </Button>
          </div>  
        )}
      </form> 
      { 
        simulation && action.upToDate && <SimulationBox law = {law as Law} simulation = {simulation} />
      } 
    </>
  );
}
