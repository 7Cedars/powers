"use client";

import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { Checks } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { useRouter } from "next/navigation";

const roleColour = [  
  "blue-600", 
  "red-600", 
  "yellow-600", 
  "purple-600",
  "green-600", 
  "orange-600", 
  "slate-600"
]

export function ChecksBox ({checks}: {checks: Checks}) {
  const router = useRouter(); 
  const needCompletedLaw = organisation?.laws?.find(l => l.law == law.config.needCompleted); 
  const needNotCompletedLaw = organisation?.laws?.find(l => l.law == law.config.needNotCompleted); 
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { checks?.authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

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
                  onClick = {() => {
                    setLaw(needCompletedLaw ? needCompletedLaw : law)
                    router.push('/laws/law')
                  }}
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
                  onClick = {() => {
                    setLaw(needNotCompletedLaw ? needNotCompletedLaw : law)
                    router.push('/laws/law')
                  }}
                  >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                    {needNotCompletedLaw?.name}
                  </div>
                </button>
              </div>
            </div>
            : null
            }

    </section>
  )
}