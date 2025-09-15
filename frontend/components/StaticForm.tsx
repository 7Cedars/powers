"use client";

import React from "react";
import { useActionStore } from "@/context/store";
import { StaticInput } from "@/components/StaticInput";
import { Law } from "@/context/types";

type StaticFormProps = {
  law?: Law;
};

export function StaticForm({ law }: StaticFormProps) {
  const action = useActionStore();

  return (
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
        <label htmlFor="nonce" className="text-xs text-slate-600 ps-3 min-w-20">Nonce</label>
        <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-2 outline outline-1 outline-slate-300">
          <input 
            type="text" 
            name="nonce"
            className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0"  
            id="nonce" 
            value={action.nonce.toString()}
            disabled={true}
          />
        </div>
      </div>

      {/* reason */}
      <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 gap-3 min-h-24">
        <label htmlFor="reason" className="text-xs text-slate-600 ps-3 min-w-20 pt-1">Description</label>
        <div className="w-full flex items-center rounded-md bg-white outline outline-1 outline-slate-300">
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
    </form>
  );
}
