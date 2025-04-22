import { Button } from "@/components/Button";

import {useActionStore} from "@/context/store";
import { Law, Powers } from "@/context/types";
import { useRouter } from "next/navigation";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

export function Children({law, powers}: {law: Law | undefined, powers: Powers | undefined}) {
  const router = useRouter();

  const childLaws: Law[] | undefined = powers?.laws?.filter(law => 
    law.conditions.needCompleted == law.index || law.conditions.needNotCompleted == law.index
  ) 

  return (
    childLaws?.length != 0 ? 
    <div className="w-full flex grow flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-80"> 
    <section className="w-full flex flex-col text-sm text-slate-600" > 
      <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 border-b border-slate-300">
        <div className="text-left w-52">
          Dependent laws
        </div>
      </div>
      <div className = "flex flex-col items-center justify-center"> 
        {    
          childLaws?.map(law =>
              <div key={law.index} className = "w-full flex flex-row p-2 px-3">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[Number(law.conditions.allowedRole) % roleColour.length]} disabled:opacity-50`}
                  onClick = {() => {router.push(`${law.powers}/laws/${law.index}`)}}
                >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                      {law.description}
                  </div>
                </button>
              </div>
          )
      }
      </div>
  </section>
  </div>
  : null
  )
}