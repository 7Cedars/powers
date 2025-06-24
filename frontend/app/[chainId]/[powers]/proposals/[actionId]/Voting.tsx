"use client";

import { powersAbi } from "@/context/abi";
import { parseChainId, parseVoteData } from "@/utils/parsers";
import { Action, Powers, Status } from "@/context/types";
import { CheckIcon, XMarkIcon} from "@heroicons/react/24/outline";
import { useBlockNumber, useChains, useReadContracts } from "wagmi";
import { LoadingBox } from "@/components/LoadingBox";
import { useParams } from "next/navigation";
import { getConstants } from "@/context/constants";

export const Voting = ({action, powers, status: statusPowers}: {action: Action, powers: Powers | undefined, status: Status}) => {
  // console.log("@Voting: waypoint 0", {proposal, powers})

  const { chainId } = useParams<{ chainId: string }>()
  const { data: blockNumber } = useBlockNumber()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === parseChainId(chainId))
  const law = action?.lawId ? powers?.laws?.find(law => law.index == action?.lawId) : undefined
  const constants = getConstants(parseChainId(chainId) as number)

  // I try to avoid fetching in info blocks, but we do not do anything else with this data: only for viewing purposes.. 
  const powersContract = {
    address: powers?.contractAddress, 
    abi: powersAbi,
  } as const
  const { isSuccess, status, data } = useReadContracts({
    contracts: [
      {
        ...powersContract, 
        functionName: 'getProposedActionVotes',
        args: [action?.actionId]
      }, 
      {
        ...powersContract,
        functionName: 'getAmountRoleHolders', 
        args: [law?.conditions?.allowedRole]
      }, 
      {
        ...powersContract,
        functionName: 'getProposedActionDeadline', 
        args: [action?.actionId]
      }, 
      {
        ...powersContract,
        functionName: 'state', 
        args: [action?.actionId]
      }, 
    ]
  })

  // console.log("@Voting: waypoint 0", {data})
  
  const allVotes = Number(action.forVotes) + Number(action.againstVotes) + Number(action.abstainVotes)
  const quorum = isSuccess ? Math.floor((parseVoteData(data).holders * Number(law?.conditions?.quorum)) / 100) : 0
  const threshold = isSuccess ? Math.floor((parseVoteData(data).holders * Number(law?.conditions?.succeedAt)) / 100) : 0
  const deadline = isSuccess ? parseVoteData(data).deadline : 0
  const state = isSuccess ? parseVoteData(data).state : 0
  const layout = `w-full flex flex-row justify-center items-center px-2 py-1 text-bold rounded-md`

  // console.log("@Voting: waypoint 1", {votes, quorum, threshold, deadline, isSuccess, action, state})

  return (
      <div className="w-full h-fit flex flex-col gap-3 justify-start items-center bg-slate-50">
      <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600 border border-slate-300 rounded-md overflow-hidden" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 bg-slate-100">
          <div className="text-left w-52">
            Voting
          </div> 
        </div>

        {statusPowers == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>  
        :
        <div className = "w-full h-full flex flex-col lg:min-h-fit overflow-x-scroll divide-y divide-slate-300 max-h-full overflow-y-scroll">
        
        {/* Proposal state block */}
        <div className = "w-full flex flex-col justify-center items-center p-4 py-3"> 
            { 
              !state == undefined ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> No Proposal Found </div>
              :
              state == 0 ? 
                <div className={`${layout} text-blue-500 bg-blue-100`}> Active </div>
              :
              state == 1 ? 
                <div className={`${layout} text-orange-500 bg-orange-100`}> Cancelled </div>
              :
              state ==  2 ? 
                <div className={`${layout} text-red-500 bg-red-100`}> Defeated </div>
              :
              state ==  3 ? 
                <div className={`${layout} text-green-500 bg-green-100`}> Succeeded </div>
              :
              state == 4 ? 
                <div className={`${layout} text-slate-700 bg-slate-200`}> Requested </div>
              :
              state == 5 ? 
                <div className={`${layout} text-slate-700 bg-slate-200`}> Fulfilled </div>
              :
              state == 6 ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> NonExistent </div>
              :
              null 
            }
        </div>
        
        {/* Quorum block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { Number(action.forVotes) + Number(action.abstainVotes) >= quorum ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { Number(action.forVotes) + Number(action.abstainVotes) >= quorum ? "Quorum passed" : "Quorum not passed"}
            </div>
          </div>
          <div className={`relative w-full leading-none rounded-sm h-3 border border-slate-300 overflow-hidden`}>
            <div 
              className={`absolute bottom-0 leading-none h-3 bg-slate-400`}
              style={{width:`${((Number(action.forVotes) + Number(action.abstainVotes)) * 100) / quorum }%`}}> 
            </div>
          </div>
          <div className="w-full text-sm text-left text-slate-500"> 
           {isSuccess ? `${Number(action.forVotes) + Number(action.abstainVotes) } / ${quorum} votes` : ""}
          </div>
        </div>

        {/* Threshold block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { Number(action.forVotes) >= threshold ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { Number(action.forVotes) >= threshold ? "Threshold passed" : "Threshold not passed"}
            </div>
          </div>
          <div className={`relative w-full flex flex-row justify-start leading-none rounded-sm h-3 border border-slate-300`}>
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-gray-400`} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-red-400`} style={{width:`${((Number(action.forVotes) + Number(action.againstVotes)) / allVotes)*100}%`}} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-green-400`} style={{width:`${((Number(action.forVotes)) / allVotes)*100}%`}} />
            <div className={`absolute -top-2 w-full leading-none h-6 border-r-4 border-green-500`} style={{width:`${law?.conditions?.succeedAt}%`}} />
          </div>
          <div className="w-full flex flex-row justify-between items-center"> 
            <div className="w-fit text-sm text-center text-green-500">
              {isSuccess ? `${Number(action.forVotes)} for` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-red-500">
              {isSuccess ? `${Number(action.againstVotes)} against` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-gray-500">
            {isSuccess ? `${Number(action.abstainVotes)} abstain` : "na"}
            </div>
          </div>
        </div>

        {/* Vote still active block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { blockNumber && blockNumber <= deadline ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { blockNumber && blockNumber >= deadline ? "Vote has closed" : "Vote still active"}
            </div>
          </div>
          {blockNumber && blockNumber < deadline &&  
            <div className = "w-full flex flex-row justify-between items-center">
              {`Vote will end in ${Math.floor((deadline - Number(blockNumber)) * 60 / constants.BLOCKS_PER_HOUR)} minutes`}
            </div>  
          }
        </div>
        </div> 
        }
      </section>
    </div>
  )
}