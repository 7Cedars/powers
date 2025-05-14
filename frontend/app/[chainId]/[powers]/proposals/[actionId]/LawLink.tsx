"use client";

import { Law, Status, Powers } from "@/context/types";
import { LoadingBox } from '@/components/LoadingBox';
import { shorterDescription } from '@/utils/parsers';
import { useActionStore } from "@/context/store";
import { useRouter, useParams } from "next/navigation";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

export const LawLink: React.FC<{law: Law, powers: Powers | undefined, status: Status}> = ({law, powers, status}) => {
  const action = useActionStore()
  // console.log("@LawLink, action:", {action})
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Law
          </div> 
        </div>

        {status == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        <>
        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[Number(law?.conditions?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => router.push(`/${chainId}/${powers?.contractAddress}/laws/${law.index}`)} >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                    {shorterDescription(law?.nameDescription, "short")}
                </div>
            </button>
        </div>
        </>
        }
    </section>
  )
}