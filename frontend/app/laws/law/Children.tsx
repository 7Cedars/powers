import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw, useActionStore} from "@/context/store";
import { Law } from "@/context/types";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

export function Children() {
  const organisation = useOrgStore();
  const currentLaw = useLawStore();
  const action = useActionStore();

  const childLaws: Law[] | undefined = organisation?.laws?.filter(law => 
    law.config.needCompleted == currentLaw.law || law.config.needNotCompleted == currentLaw.law
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
              <div key={law.law} className = "w-full flex flex-row p-2 px-3">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[Number(law.allowedRole) % roleColour.length]} disabled:opacity-50`}
                  onClick = {() => {setLaw(law)}}
                >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                      {law.name}
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