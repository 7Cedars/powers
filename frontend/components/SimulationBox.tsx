"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { bytesToParams, parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { LawSimulation, Law } from "@/context/types";

type SimulationBoxProps = {
  law: Law;
  simulation: LawSimulation | undefined;
};

export const SimulationBox = ({law, simulation}: SimulationBoxProps) => {
  // console.log("@SimulationBox: waypoint 1", {law, simulation})
  const {status, error} = useLaw();
  const [jsxSimulation, setJsxSimulation] = useState<React.JSX.Element[][]> ([]); 
  const { data, isLoading, isError, error: stateVarsError } = useReadContract({
        abi: lawAbi,
        address: law.lawAddress,
        functionName: 'stateVars'
      })
  const params =  bytesToParams(data as `0x${string}`)  
  const dataTypes = params.map(param => param.dataType) 

  // console.log("@SimulationBox: waypoint 2", {jsxSimulation})
    
  useEffect(() => {

    let jsxElements0: React.JSX.Element[] = []; 
    let jsxElements1: React.JSX.Element[] = []; 

    if (simulation && simulation.length > 0) {
      for (let i = 0; i < simulation[1].length; i++) {
        jsxElements0 = [ 
          ... jsxElements0, 
          <tr
            key={i}
            className={`text-xs font-mono text-slate-800 h-16 p-2 overflow-x-scroll`}
          >
            {/*  */}
            <td className="ps-6 text-left font-mono text-slate-500"> {simulation[1][i]} </td> 
            <td className="text-center font-mono text-slate-500"> {String(simulation[2][i])} </td>
            <td className="pe-4 text-left font-mono text-slate-500"> {simulation[3][i]} </td>
          </tr>
        ];
      }
    }  
  
    if (simulation && simulation[4] && simulation[4] != "0x") {
        const stateVars = dataTypes.length > 0 ? decodeAbiParameters(parseAbiParameters(dataTypes.toString()), simulation[4]) : [];
        const stateVarsParsed = parseParamValues(stateVars)
        for (let i = 0; i < stateVarsParsed.length; i++) {
        jsxElements1 = [ 
          ... jsxElements1, 
          <tr
            key={i}
            className={`text-xs font-mono text-slate-800 h-16 p-2 overflow-x-scroll`}
          >
            {/*  */}
            <td className="ps-6 text-left font-mono text-slate-500"> {dataTypes[i]} </td> 
            <td className="text-left font-mono text-slate-500"> {String(stateVarsParsed[i])} </td>
            </tr>
        ];
      }
    }  
    const sim = [jsxElements1, jsxElements0]
    setJsxSimulation(sim)
  }, [simulation])

  return (
    <section className="w-full flex flex-col gap-6 justify-start items-center px-6 pt-4">
    {dataTypes.length > 0 ? 
      <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 border rounded-md border-slate-300 overflow-hidden">
          <div className="w-full text-xs text-center font-medium text-slate-600 p-2 bg-slate-100 border-b border-slate-300">
            State variables to be saved in law 
          </div>
          <div className="w-full h-fit overflow-scroll">
            <table className="table-auto w-full ">
              <thead className="w-full border-b border-slate-300">
                <tr className="w-96 bg-slate-50 text-xs font-light font-mono text-left text-slate-600">
                    <th className="ps-6 py-2 font-light"> Data type </th>
                    <th className="font-light text-left"> Value </th>
                </tr>
              </thead>
                <tbody className="w-full text-xs text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                  { jsxSimulation[0] ? jsxSimulation[0].map(row => {return (row)} ) : null } 
                </tbody>
              </table>
            </div>
        </div>
        : 
        null
      }

      <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 border rounded-md border-slate-300 overflow-hidden">
        <div className="w-full text-xs text-center font-medium text-slate-600 p-2 bg-slate-100 border-b border-slate-300">
          Calldata to be send to Powers  
        </div>
        <div className="w-full h-fit overflow-scroll">
          <table className="table-auto w-full ">
            <thead className="w-full border-b border-slate-300">
              <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-600">
                  <th className="ps-6 py-2 font-light"> Target contracts </th>
                  <th className="font-light pe-4"> Value </th>
                  <th className="font-light"> Calldata </th>
              </tr>
            </thead>
              <tbody className="w-full text-xs text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                { 
                  jsxSimulation[1] ? 
                    jsxSimulation[1].map(row => {return (row)} ) 
                  : status && status == "error" ?
                    <div className="w-full flex flex-col gap-0 justify-start items-center text-red-800 text-xs p-4">
                      <div className="font-medium">Error:</div>
                      <div className="font-mono">{String(error)}</div>
                    </div>  
                  :
                  null 
                  } 
              </tbody>
            </table>
          </div>
          
      </div>
    </section>
  )
}