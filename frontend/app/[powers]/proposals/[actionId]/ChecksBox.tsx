"use client";

import {  CheckIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { Checks, Powers, Law, Status } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { useRouter } from "next/navigation";
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

export function ChecksBox ({checks, powers, law, status}: {checks: Checks | undefined, powers: Powers | undefined, law: Law | undefined, status: Status}) {
  const router = useRouter(); 
  const needCompletedLaw = powers?.laws?.find(l => l.index == law?.conditions.needCompleted); 
  const needNotCompletedLaw = powers?.laws?.find(l => l.index == law?.conditions.needNotCompleted); 

  console.log("@checksBox: ", {checks, powers, law})

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
        </div>

        {/* authorised block */}
        {status == "pending" || status == "idle" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        <>
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { checks?.authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

        {/* Executed */}
          {law && law.conditions.needCompleted != 0n  ?  
            <div className = "w-full flex flex-col justify-center items-center p-2"> 
              <div className = "w-full flex flex-row px-2 justify-between items-center">
              { checks?.lawCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
                Law executed
              </div>
              <div className = "w-full flex flex-row px-2 py-1">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needCompletedLaw?.conditions.allowedRole)]} disabled:opacity-50`}
                  onClick = {() => {
                    router.push(`/${powers?.contractAddress}/laws/${needCompletedLaw?.index}`)
                  }}
                  >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                  {needCompletedLaw?.description}
                  </div>
                </button>
              </div>
            </div>  
            :
            null
          }
  
          {/* Not executed */}
          {law && law.conditions.needNotCompleted != 0n ? 
            <div className = "w-full flex flex-col justify-center items-center p-2"> 
              <div className = "w-full flex flex-row px-2 justify-between items-center">
              { checks?.lawNotCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
                  Law not executed
              </div>
              <div className = "w-full flex flex-row px-2 py-1">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border border-${roleColour[parseRole(needNotCompletedLaw?.conditions.allowedRole)]} disabled:opacity-50`}
                  onClick = {() => {
                    router.push(`/${powers?.contractAddress}/laws/${needNotCompletedLaw?.index}`)
                  }}
                  >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                    {needNotCompletedLaw?.description}
                  </div>
                </button>
              </div>
            </div>
            : null    
          }
        </>
        }
    </section>  
  )
}