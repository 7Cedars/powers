import { Button } from "@/components/Button";
import { LoadingBox } from "@/components/LoadingBox";

import {useActionStore} from "@/context/store";
import { Law, Powers, Status } from "@/context/types";
import { shorterDescription } from "@/utils/parsers";
import { useParams, useRouter } from "next/navigation";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

export function Children({law, powers, status}: {law: Law | undefined, powers: Powers | undefined, status: Status}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()

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
        {status == "pending" || status == "idle" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        childLaws?.map(law =>
              <div key={law.index} className = "w-full flex flex-row p-2 px-3">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[Number(law.conditions.allowedRole) % roleColour.length]} disabled:opacity-50`}
                  onClick = {() => {router.push(`/${chainId}/${law.powers}/laws/${law.index}`)}}
                >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                      {shorterDescription(law.description, "short")}
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