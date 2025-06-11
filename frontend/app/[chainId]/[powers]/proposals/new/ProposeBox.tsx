"use client";

import React, { useEffect } from "react";
import { useActionDataStore, useActionStore } from "@/context/store";
import { Button } from "@/components/Button";
import { useParams, useRouter } from "next/navigation";
import { useLaw } from "@/hooks/useLaw";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { Law, Powers, Action, Status } from "@/context/types";
import { StaticInput } from "@/components/StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { ConnectedWallet, useWallets } from "@privy-io/react-auth";

const roleColor = [  
  "#007bff",
  "#dc3545",
  "#ffc107",
  "#6f42c1",
  "#28a745",
  "#fd7e14",
  "#17a2b8",
]

export function ProposeBox({law, powers, proposalExists, authorised, onCheck, status}: {law?: Law, powers: Powers, status: Status, proposalExists: boolean, authorised: boolean, onCheck: (law: Law, action: Action, wallets: ConnectedWallet[], powers: Powers) => void}) {
  const action = useActionStore(); 
  const {simulation, simulate} = useLaw();
  const {status: statusProposals, propose} = useProposal();
  const { wallets } = useWallets();
  const { actionData } = useActionDataStore();

  console.log("@ProposeBox: waypoint 0", {actionData})

  useEffect(() => {
    simulate(
      action.caller as `0x${string}`,
      action.callData,
      BigInt(action.nonce),
      law as Law
    )
  }, [law, action])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border-2 mt-2 rounded-md overflow-hidden`} style={{ borderColor: roleColor[parseRole(law?.conditions?.allowedRole ?? 0n) % roleColor.length] }}>
      {/* title  */}
      <div className="w-full flex flex-col gap-2 justify-start items-start border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
        <div className="text-md font-bold text-slate-800 break-all w-fit">
          📋 #{law?.index}: {shorterDescription(law?.nameDescription, "short")}
        </div>
        <div className="text-sm text-slate-800 break-all w-fit">
          {shorterDescription(law?.nameDescription, "long")}
        </div>
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
                cols ={25} 
                value={action.description}
                className="w-full py-1.5 ps-2 pe-3 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
                placeholder="Enter URI to file with notes on the action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      <div className="w-full flex flex-row justify-center items-center px-6 py-2 pt-6">
        <Button 
            size={0} 
            showBorder={true} 
            role={law?.conditions?.allowedRole == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(law?.conditions?.allowedRole)}
            filled={false}
            selected={true}
            onClick={() => 
              onCheck(law as Law, action, wallets, powers as Powers)
            } 
            statusButton={
                action.description && action.description.length > 0 && status == "success" ? 'idle' : 'disabled'
              }> 
            Check 
        </Button>
      </div>

      {simulation && <SimulationBox simulation = {simulation} law = {law as Law}/> }

      {/* execute button */}
        <div className="w-full h-fit px-6 py-2 pb-6">
            <Button 
              size={0} 
              onClick={() => propose(
                law?.index as bigint, 
                action.callData, 
                BigInt(action.nonce),
                action.description,
                powers as Powers
              )} 
              filled={false}
              selected={true}
              statusButton={(!authorised || proposalExists) ? 'disabled' : statusProposals }
              > 
              {proposalExists 
                ? 'Proposal Exists' 
                : !authorised 
                  ? 'Not authorised to make proposal' 
                  : 'Propose'
              }
            </Button>
        </div>
      </section>
    </main>
  );
}

