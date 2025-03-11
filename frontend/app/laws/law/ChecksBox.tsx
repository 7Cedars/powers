"use client";

import { setLaw, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import { CalendarDaysIcon, CheckIcon, QueueListIcon, UserGroupIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { parseRole } from "@/utils/parsers";
import { useRouter } from "next/navigation";
import { Checks } from "@/context/types";

const roleColour = [  
  "blue-600", 
  "red-600", 
  "yellow-600", 
  "purple-600",
  "green-600", 
  "orange-600", 
  "slate-600"
]

export const ChecksBox = ({checks}: {checks: Checks}) => {
  const router = useRouter();
  const law = useLawStore();
  const organisation = useOrgStore();
  const needCompletedLaw = organisation?.laws?.find(l => l.law == law.config.needCompleted); 
  const needNotCompletedLaw = organisation?.laws?.find(l => l.law == law.config.needNotCompleted); 

  // console.log("@fetchChecks, waypoint for, law box:", {checks} )

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
        </div>

        <div className = "w-full h-full flex flex-col lg:min-h-fit overflow-x-scroll divide-y divide-slate-300 max-h-36 lg:max-h-full overflow-y-scroll">

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { checks?.authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            {checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

        {/* proposal passed */}
        {law.config.quorum != 0n ?
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
              { checks?.proposalPassed ? 
                <>
                  <CheckIcon className="w-4 h-4 text-green-600"/> 
                  <UserGroupIcon className="w-4 h-4 text-slate-700"/>
                  Proposal passed
                </>
                : 
                <>
                  <XMarkIcon className="w-4 h-4 text-red-600"/>
                  <div className = "flex flex-row gap-2">
                    <UserGroupIcon className="w-5 h-5 text-slate-700"/>
                    Proposal not passed
                  </div>
                </>
              }
              
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(law.allowedRole)]} disabled:opacity-50`}
                onClick = {() => router.push('/proposals/proposal')}
                disabled = { checks.proposalExists && checks.authorised == false && checks.lawCompleted == false && checks.lawNotCompleted == false }
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1  px-2 py-1`}>
                {  law.name }
                </div>
              </button>
            </div>
          </div>
          : null
        }

        {/* Delay */}
        {law.config.delayExecution != 0n?
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
              {`This law can only be executed ${law.config.delayExecution } blocks after a vote passed.`}
            </div>
          </div>
        </div>
        : null  
        }

        {/* Throttle */}
        {law.config.throttleExecution != 0n ? 
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
              {`This law can only be executed once every ${law.config.throttleExecution} blocks.`}
            </div>
          </div>
        </div>
        : null
        }

        {/* proposal already executed */}
        {
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
              { checks?.proposalNotCompleted  ? 
                <>
                  <CheckIcon className="w-4 h-4 text-green-600"/> 
                  Action not yet executed
                </>
                : 
                <>
                  <XMarkIcon className="w-4 h-4 text-red-600"/>
                  Action executed
                </>
              }
            </div>
          </div>
        }

        {/* Executed */}
        {law.config.needCompleted != `0x${'0'.repeat(40)}`  ?  
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
              Law executed
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needCompletedLaw?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {setLaw(needCompletedLaw ? needCompletedLaw : law)}}
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                {needCompletedLaw?.name}
                </div>
              </button>
            </div>
          </div>
          :
          null
        }

        {/* Not executed */}
        {law.config.needNotCompleted != `0x${'0'.repeat(40)}` ? 
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawNotCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
                Law not executed
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needNotCompletedLaw?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {setLaw(needNotCompletedLaw ? needNotCompletedLaw : law)}}
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                 {needNotCompletedLaw?.name}
                </div>
              </button>
            </div>
          </div>
          : null
          }


      
      </div>
    </section>
  )
}