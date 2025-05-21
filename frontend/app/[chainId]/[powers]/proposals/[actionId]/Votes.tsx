"use client";

import { powersAbi } from "@/context/abi";
import { parseChainId, parseVoteData } from "@/utils/parsers";
import { Powers, Proposal, Status } from "@/context/types";
import { CheckIcon, XMarkIcon} from "@heroicons/react/24/outline";
import { useBlockNumber, useChains, useReadContracts } from "wagmi";
import { blocksToHoursAndMinutes } from "@/utils/toDates";
import { LoadingBox } from "@/components/LoadingBox";
import { useParams } from "next/navigation";
import { getConstants } from "@/context/constants";

export const Votes = ({proposal, powers, status: statusPowers}: {proposal: Proposal, powers: Powers | undefined, status: Status}) => {
  // console.log("@Votes: waypoint 0", {proposal, powers})

  const { chainId } = useParams<{ chainId: string }>()
  const { data: blockNumber } = useBlockNumber()
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id === parseChainId(chainId))
  const law = proposal?.lawId ? powers?.laws?.find(law => law.index == proposal?.lawId) : undefined
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
        args: [proposal?.actionId]
      }, 
      {
        ...powersContract,
        functionName: 'getAmountRoleHolders', 
        args: [law?.conditions?.allowedRole]
      }, 
      {
        ...powersContract,
        functionName: 'getProposedActionDeadline', 
        args: [proposal?.actionId]
      }, 
    ]
  })
  const votes = isSuccess ? parseVoteData(data).votes : [0, 0, 0]
  const init = 0
  const allVotes = votes.reduce((acc, current) => acc + current, init)
  const quorum = isSuccess ? Math.floor((parseVoteData(data).holders * Number(law?.conditions?.quorum)) / 100) : 0
  const threshold = isSuccess ? Math.floor((parseVoteData(data).holders * Number(law?.conditions?.succeedAt)) / 100) : 0
  const deadline = isSuccess ? parseVoteData(data).deadline : 0

  // console.log("@Votes: waypoint 1", {votes, quorum, threshold, deadline})

  return (
      <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-72">
      <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Votes
          </div> 
        </div>

        {statusPowers == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>  
        :
        <div className = "w-full h-full flex flex-col lg:min-h-fit overflow-x-scroll divide-y divide-slate-300 max-h-36 lg:max-h-full overflow-y-scroll">
        {/* Quorum block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { votes[1] + votes[2] >= quorum ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { votes[1] + votes[2] >= quorum ? "Quorum passed" : "Quorum not passed"}
            </div>
          </div>
          <div className={`relative w-full leading-none rounded-sm h-3 border border-slate-300 overflow-hidden`}>
            <div 
              className={`absolute bottom-0 leading-none h-3 bg-slate-400`}
              style={{width:`${((votes[1] + votes[2]) * 100) / quorum }%`}}> 
            </div>
          </div>
          <div className="w-full text-sm text-left text-slate-500"> 
           {isSuccess ? `${votes[1] + votes[2] } / ${quorum} votes` : ""}
          </div>
        </div>

        {/* Threshold block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { votes[1] >= threshold ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { votes[1] >= threshold ? "Threshold passed" : "Threshold not passed"}
            </div>
          </div>
          <div className={`relative w-full flex flex-row justify-start leading-none rounded-sm h-3 border border-slate-300`}>
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-gray-400`} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-red-400`} style={{width:`${((votes[1] + votes[0]) / allVotes)*100}%`}} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-green-400`} style={{width:`${((votes[1]) / allVotes)*100}%`}} />
            <div className={`absolute -top-2 w-full leading-none h-6 border-r-4 border-green-500`} style={{width:`${law?.conditions?.succeedAt}%`}} />
          </div>
          <div className="w-full flex flex-row justify-between items-center"> 
            <div className="w-fit text-sm text-center text-green-500">
              {isSuccess ? `${votes[1]} for` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-red-500">
              {isSuccess ? `${votes[0]} against` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-gray-500">
            {isSuccess ? `${votes[2]} abstain` : "na"}
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