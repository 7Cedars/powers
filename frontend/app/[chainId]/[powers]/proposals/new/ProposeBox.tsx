"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useActionStore, setAction } from "@/context/store";
import { Button } from "@/components/Button";
import { useParams, useRouter } from "next/navigation";
import { useBlockNumber, useReadContract, useTransactionConfirmations } from 'wagmi'
import { lawAbi, powersAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { parseRole } from "@/utils/parsers";
import { InputType, Law, Proposal, Powers } from "@/context/types";
import { StaticInput } from "@/components/StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { SectionText } from "@/components/StandardFonts";
import { useWatchContractEvent } from 'wagmi'
import { usePowers } from "@/hooks/usePowers";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600",
]

export function ProposeBox({law, powers, proposalExists, authorised}: {law?: Law, powers: Powers, proposalExists: boolean, authorised: boolean}) {
  const router = useRouter();
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposals, error, transactionHash, propose} = useProposal();
  const { chainId } = useParams<{ chainId: string }>()

  // console.log("@ProposeBox, waypoint 1", {law, powers, proposalExists, authorised, action})

  useEffect(() => {
    simulate(
      action.caller,
      action.callData,
      BigInt(action.nonce),
      law as Law
    )
  }, [law, action])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[parseRole(law?.conditions?.allowedRole ?? 0n) % roleColour.length]} mt-2 rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={`Proposal: ${law?.nameDescription}`}
          size = {0}
        /> 
      </div>

      {/* static form */}
      <form action="" method="get" className="w-full">
        {
          law?.params?.map((param, index) => 
            <StaticInput 
              dataType = {param.dataType} 
              varName = {param.varName} 
              values = {action.paramValues && action.paramValues[index] ? action.paramValues[index] : []} 
              key = {index}
              />)
        }
        {/* nonce */}
        <div className="w-full mt-4 flex flex-row justify-center items-start px-6 pb-4">
          <label htmlFor="nonce" className="min-w-20 w-fit text-sm/6 font-medium text-slate-600 pb-1">Nonce</label>
          <div className="w-full h-8 flex items-center pe-2 pl-3 text-slate-600 placeholder:text-gray-400 bg-slate-100 rounded-md outline outline-1 outline-gray-300 sm:text-sm">
          <input 
              type="text" 
              name="nonce"
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6"  
              id="nonce" 
              value={action.nonce.toString()}
              disabled={true}
              />
          </div>
        </div>
        {/* reason */}
        <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={25} 
                value={action.uri}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 bg-slate-100 pl-3 text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      {simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> }

      {/* execute button */}
        <div className="w-full h-fit p-6">
            <Button 
              size={1} 
              onClick={() => propose(
                law?.index as bigint, 
                action.callData, 
                BigInt(action.nonce),
                action.uri,
                powers as Powers
              )} 
              filled={false}
              selected={true}
              statusButton={(!authorised || proposalExists) ? 'disabled' : statusProposals }
              > 
              Propose
            </Button>
        </div>
      </section>
    </main>
  );
}

