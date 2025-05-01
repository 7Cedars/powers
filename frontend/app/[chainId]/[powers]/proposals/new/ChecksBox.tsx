"use client";

import { CheckIcon, XMarkIcon } from "@heroicons/react/24/outline";

export function ChecksBox ({proposalExists, authorised}: {proposalExists: boolean, authorised: boolean}) {
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
            { authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

        {/* proposal exists block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { proposalExists ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { proposalExists ? "Proposal does not exist yet" : "Proposal already exists"  } 
            </div>
          </div>
        </div>

    </section>
  )
}