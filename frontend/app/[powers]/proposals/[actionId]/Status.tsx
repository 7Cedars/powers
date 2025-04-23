"use client";

import { useReadContract } from 'wagmi'
import { powersAbi } from "@/context/abi";
import { Proposal } from "@/context/types";

export const Status = ({proposal}: {proposal?: Proposal}) => {
  const layout = `w-full flex flex-row justify-center items-center px-2 py-1 text-bold rounded-md`
  // const { status: readContractStatus, data: ActionState, error: readContractError } = useReadContract({
  //   address: proposal?.action?.caller,
  //   abi: powersAbi,  
  //   functionName: 'state',
  //   args: [proposal?.actionId],
  // })

  // console.log("@status block: ", {proposal, ActionState, readContractError, readContractStatus})

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Status
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
            { 
              !proposal ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> No Proposal Found </div>
              :
              proposal.state == 0 ? 
                <div className={`${layout} text-blue-500 bg-blue-100`}> Active </div>
              :
              proposal.state == 1 ? 
                <div className={`${layout} text-orange-500 bg-orange-100`}> Cancelled </div>
              :
              proposal.state ==  2 ? 
                <div className={`${layout} text-red-500 bg-red-100`}> Defeated </div>
              :
              proposal.state ==  3 ? 
                <div className={`${layout} text-green-500 bg-green-100`}> Succeeded </div>
              :
              proposal.state == 4 ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> Executed </div>
              :
              null 
            }
        </div>
    </section>
  )
}