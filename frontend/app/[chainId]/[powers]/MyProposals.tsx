`use client`

import { setAction } from "@/context/store";
import { Law, Powers, Proposal, Status } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { toFullDateFormat } from "@/utils/toDates";
import { GetBlockReturnType } from "@wagmi/core";
import { parseRole } from "@/utils/parsers";
import { LoadingBox } from "@/components/LoadingBox";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

type MyProposalProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  proposals: Proposal[] | undefined; 
  powers: Powers | undefined;
  status: Status;
}

type ProposalAndLaw = {
  proposal: Proposal; 
  law: Law; 
}

export function MyProposals({ hasRoles, authenticated, proposals, powers, status}: MyProposalProps ) {
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.role > 0).map(hasRole => hasRole.role)
  const { chainId } = useParams<{ chainId: string }>()

  // bit convoluted, can be optimised. // £todo
  const active = proposals?.map((proposal: Proposal) => {
    const law = powers?.laws?.find(law => law.index == proposal.lawId)
    if (law && law.conditions && law.conditions.allowedRole != undefined && myRoles.includes(law.conditions.allowedRole) && proposal.state == 0) {
      return {
        proposal: proposal, 
        law: law
      } as ProposalAndLaw
    }
  }) 
  const activeProposals = active?.filter(item => item != undefined)

  // console.log("@myProposals: ",  {activeProposals})

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80"> 
      <button
        onClick={() => 
          { 
             // here have to set deselectedRoles
            router.push(`/${chainId}/${powers?.contractAddress}/proposals`)
          }
        } 
        className="w-full border-b border-slate-300 p-2"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
        <div className="text-left text-sm text-slate-600 w-52">
          My active proposals
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {
        status == "pending" || status == "idle" ? 
        <div className="w-full h-full flex flex-col justify-start text-sm text-slate-500 items-start p-3">
          <LoadingBox /> 
        </div>
        :  
        authenticated ?
        proposals && proposals.length > 0 ? 
          <div className = "w-full h-fit lg:max-h-48 max-h-32 flex flex-col gap-2 justify-start items-center overflow-x-scroll p-2 px-1">
          {
            activeProposals?.map((item: ProposalAndLaw, i) => 
                <div className = "w-full px-2" key={i}>
                  <button 
                    className = {`w-full h-full disabled:opacity-50 rounded-md border ${roleColour[parseRole(item.law.conditions?.allowedRole || 0n)]} text-sm p-1 px-2`} 
                    onClick={
                      () => {
                        setAction({
                          description: item.proposal.description,
                          callData: item.proposal.calldata,
                          nonce: item.proposal.nonce,
                          lawId: item.proposal.lawId,
                          caller: item.proposal.caller,
                          dataTypes: item.law.params?.map(param => param.dataType),
                          upToDate: true
                        })
                        router.push(`/${chainId}/${powers?.contractAddress}/proposals/${item.proposal.actionId}`)
                        }
                      }>
                      <div className ="w-full flex flex-col gap-1 text-sm text-slate-600 justify-center items-center">
                        <div className = "w-full flex flex-row justify-between items-center text-left">
                          <p> Date: </p> 
                          <p> {toFullDateFormat(Number(item.proposal.voteStartBlockData?.timestamp))}  </p>
                        </div>

                        <div className = "w-full flex flex-row justify-between items-center text-left">
                          <p> Law: </p> 
                          <p> {item.law.nameDescription?.length && item.law.nameDescription?.length > 24 ? item.law.nameDescription?.substring(0, 24) + "..." : item.law.nameDescription}  </p>
                        </div>
                      </div>
                  </button>
                </div>
            )
          }
        </div>

      :
      <div className = "w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
        No proposals found
      </div>
      :   
      <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
        Connect your wallet to see your proposals. 
      </div>
    }
    </div>
  )
}