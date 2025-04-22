"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useActionStore, setAction } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter } from "next/navigation";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { decodeAbiParameters,  keccak256, parseAbiParameters, toHex } from "viem";
import { bytesToParams, parseParamValues, parseRole } from "@/utils/parsers";
import { InputType, Proposal } from "@/context/types";
import { StaticInput } from "./StaticInput";
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";
import { SectionText } from "@/components/StandardFonts";
import { useWallets } from "@privy-io/react-auth";
import { useChecks } from "@/hooks/useChecks";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600",
]

export function ProposalBox({proposal}: {proposal?: Proposal}) {
  const action = useActionStore(); 

  const {simulation, fetchSimulation} = useLaw();
  const {status: statusProposal, error, hasVoted, propose, castVote, checkHasVoted} = useProposal();
  const {status: statusChecks, error: errorChecks, checks, fetchChecks, checkProposalExists} = useChecks();

  const [paramValues, setParamValues] = useState<(InputType | InputType[])[]>([])
  const [description, setDescription] = useState<string>()
  const [calldata, setCalldata] = useState<`0x${string}`>()
  const [logSupport, setLogSupport] = useState<bigint>()
  const {wallets} = useWallets();

  const { data, isLoading, isError, error: paramsError } = useReadContract({
    abi: lawAbi,
    address: law.law,
    functionName: 'inputParams'
  })
  const params = bytesToParams(data as `0x${string}`)  
  const dataTypes = params.map(param => param.dataType) 

  console.log("@proposalBox: ", {statusProposal, proposal, action, checks, law, dataTypes})

  const handleSimulate = async () => {
      if (dataTypes && dataTypes.length > 0 && calldata && description) {
        try {
          const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), calldata);
          const valuesParsed = parseParamValues(values)
          setParamValues(valuesParsed)
        } catch {
          setParamValues([])
        }
        
        // simulating law. 
        fetchSimulation(
          law.law as `0x${string}`,
          calldata,
          keccak256(toHex(description))
        )

        fetchChecks(law, calldata, description)

        setAction({
          dataTypes: dataTypes,
          paramValues: paramValues,
          description: description,
          callData: calldata, 
          upToDate: true
        })
      
      }
  };

  const handlePropose = async () => {
    propose(
          law.law as `0x${string}`,
          calldata as `0x${string}`,
          description as string
      )
  };

  const handleCastVote = async (support: bigint) => { 
    const selectedProposal = description && calldata ? checkProposalExists(description, calldata, law) : undefined
    if (selectedProposal) {
      setLogSupport(support)
      castVote(
          BigInt(selectedProposal.actionId),
          support
        )
    }
  };

  useEffect(() => {
      handleSimulate()
  }, [description, calldata])

  useEffect(() => {
      setDescription(action.description)
      setCalldata(action.callData)
      if (proposal) checkHasVoted(
        BigInt(proposal.actionId), 
        wallets[0].address as `0x${string}`
      )
  }, [, proposal, action])

  useEffect(() => {
    if (statusProposal == 'success' && description && calldata) {
      // resetting action in zustand will trigger all components to reload.
      setAction({...action, upToDate: false })
      fetchChecks(law, action.callData, action.description)
      if (proposal) checkHasVoted(
        BigInt(proposal.actionId), 
        wallets[0].address as `0x${string}`
      )
      setAction({...action, upToDate: false })
    }
  }, [statusProposal])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[parseRole(law.allowedRole) % roleColour.length]} mt-2 rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={`Proposal: ${law?.name}`}
          subtext={law?.description}
          size = {0}
        /> 
      </div>

      {/* static form */}
      <form action="" method="get" className="w-full">
        {
          params.map((param, index) => 
            <StaticInput 
              dataType = {param.dataType} 
              varName = {param.varName} 
              values = {paramValues && paramValues[index] ? paramValues[index] : []} 
              key = {index}
              />)
        }
        <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={25} 
                value={description}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 bg-slate-100 pl-3 text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      <SimulationBox simulation = {simulation}/> 

      {/* execute button */}
        <div className="w-full h-fit p-6">
          { proposal && proposal.actionId != 0 ? 
              hasVoted ? 
              <div className = "w-full flex flex-row justify-center items-center gap-2 text-slate-400"> 
                Account has voted  
              </div>
              :
              <div className = "w-full flex flex-row gap-2"> 
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(1n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 1n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 1n ? 'disabled' 
                      : 
                      'idle'
                    }> 
                    For
                </Button>
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(0n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 0n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 0n ? 'disabled' 
                      :
                      'idle'
                    }> 
                    Against
                </Button>
                <Button 
                  size={1} 
                  selected={true}
                  filled={false}
                  onClick={() => handleCastVote(2n)} 
                  statusButton={
                    checks && !checks.authorised ? 
                      'disabled'
                      :  
                      statusProposal == 'pending' && logSupport == 2n ? 'pending' 
                      : 
                      statusProposal == 'pending' && logSupport != 2n ? 'disabled' 
                      :
                      'idle'
                    }> 
                    Abstain
                </Button>
              </div>
              :
              <Button 
              size={1} 
              onClick={handlePropose} 
              filled={false}
              selected={true}
              statusButton={
                checks && 
                checks.authorised && 
                checks.lawCompleted && 
                checks.lawNotCompleted
                ? 
                statusProposal : 'disabled'
                }> 
              Propose
            </Button>
          }
        </div>
      </section>
    </main>
  );
}
