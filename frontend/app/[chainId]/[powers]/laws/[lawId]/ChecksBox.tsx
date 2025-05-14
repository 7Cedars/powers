"use client";

import { CalendarDaysIcon, CheckIcon, QueueListIcon, UserGroupIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { parseRole, shorterDescription } from "@/utils/parsers";
import { useParams, useRouter } from "next/navigation";
import { Checks, Law, Powers, Status } from "@/context/types";
import { useActionStore } from "@/context/store";
import { LoadingBox } from "@/components/LoadingBox";
const roleColour = [  
  "blue-600", 
  "red-600", 
  "yellow-600", 
  "purple-600",
  "green-600", 
  "orange-600", 
  "slate-600"
]

export const ChecksBox = ({powers, law, checks, status}: {powers: Powers, law: Law | undefined, checks: Checks | undefined, status: Status}) => {
  const router = useRouter();
  const needCompletedLaw = powers?.laws?.find(l => l.index == law?.conditions?.needCompleted); 
  const needNotCompletedLaw = powers?.laws?.find(l => l.index == law?.conditions?.needNotCompleted); 
  const action = useActionStore()
  const { chainId } = useParams<{ chainId: string }>()

  // console.log("@ChecksBox, waypoint 1, law box:", {checks, powers})

  return (
    <section 
      className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600 aria-disabled:opacity-50" 
      aria-disabled={action?.upToDate == false}
    > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
        </div>

        <div className = "w-full h-full flex flex-col lg:min-h-fit overflow-x-scroll divide-y divide-slate-300 max-h-36 lg:max-h-full overflow-y-scroll">

        {/* authorised block */}
        {status == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        <>
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { checks?.authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            {checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

        {/* proposal passed */}
        {law?.conditions?.quorum != 0n && powers && powers.proposals && 
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
              { checks?.proposalPassed ? 
                <>
                  <CheckIcon className="w-4 h-4 text-green-600"/> 
                  <UserGroupIcon className="w-4 h-4 text-slate-700"/>
                  Proposal passed
                </>
                : 
                checks?.proposalExists ?
                <>
                  <XMarkIcon className="w-4 h-4 text-red-600"/>
                  <div className = "flex flex-row gap-2">
                    <UserGroupIcon className="w-5 h-5 text-slate-700"/>
                    Proposal not passed
                  </div>
                </>
                :
                <>
                  <XMarkIcon className="w-4 h-4 text-red-600"/>
                  Proposal not created
                </>
              }
              
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(law?.conditions?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => router.push(`/${chainId}/${powers?.contractAddress}/proposals/${checks?.proposalExists ? action?.actionId : `new`}`)}
                disabled = { checks?.proposalExists && checks?.authorised == false && checks?.lawCompleted == false && checks?.lawNotCompleted == false }
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1  px-2 py-1`}>
                {shorterDescription(law?.nameDescription, "short")}
                </div>
              </button>
            </div>
          </div> 
        }

        {/* Delay */}
        {law?.conditions?.delayExecution != 0n &&
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.delayPassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div className = "flex flex-row gap-2">
              <CalendarDaysIcon className="w-5 h-5 text-slate-700"/> 
              Delayed execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              {`This law can only be executed ${law?.conditions?.delayExecution } blocks after a vote passed.`}
            </div>
          </div>
        </div>  
        }

        {/* Throttle */}
        {law?.conditions?.throttleExecution != 0n &&
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.throttlePassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div className = "flex flex-row gap-2">
              <QueueListIcon className="w-5 h-5 text-slate-700"/> 
              Throttled execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              {`This law can only be executed once every ${law?.conditions?.throttleExecution} blocks.`}
            </div>
          </div>
        </div>
        }

        {/* proposal already executed */}
        {
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
              { checks?.actionNotCompleted == false  ? 
                <>
                  <XMarkIcon className="w-4 h-4 text-red-600"/> 
                  Action already completed
                </>
                : 
                <>
                  <CheckIcon className="w-4 h-4 text-green-600"/>
                  Action not yet completed
                </>
              }
            </div>
          </div>
        }

        {/* Executed */}
        {law?.conditions?.needCompleted != 0n && 
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
              Law executed
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needCompletedLaw?.conditions?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {
                  router.push(`/${chainId}/${powers?.contractAddress}/laws/${needCompletedLaw?.index}`)
                }}
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                {shorterDescription(needCompletedLaw?.nameDescription, "short")}
                </div>
              </button>
            </div>
          </div>
        }

        {/* Not executed */}
        {law?.conditions?.needNotCompleted != 0n && 
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawNotCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
                Law not executed
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needNotCompletedLaw?.conditions?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {
                  router.push(`/${chainId}/${powers?.contractAddress}/laws/${needNotCompletedLaw?.index}`)
                }}
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                 {shorterDescription(needNotCompletedLaw?.nameDescription, "short")}
                </div>
              </button>
            </div>
          </div>
        }
        </>
      }
      </div>
    </section>
  )
}