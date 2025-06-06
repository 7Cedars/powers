`use client`

import { LoadingBox } from "@/components/LoadingBox";
import { Powers, Status } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";

export function Assets({status, powers}: {status: Status, powers: Powers | undefined}) {
  const router = useRouter();
  const { chainId } = useParams<{ chainId: string }>()
  
  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-64">
    {
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
      <button
        onClick={() => 
          { 
             // here have to set deselectedRoles
            router.push(`/${chainId}/${powers?.contractAddress}/treasury`)
          }
        } 
        className="w-full border-b border-slate-300 p-2"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
        <div className="text-left text-sm text-slate-600 w-44">
          Total Assets
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {/* below should be a button */}
      <div className = "w-full h-fit max-h-full lg:max-h-48 flex flex-col gap-2 justify-start items-center p-4">
        {/* {status == "pending" || status == "idle" ? <LoadingBox /> :  */}
        <>
        <div className="w-full text-slate-800 text-left text-pretty">
          0 ETH 
        </div>
        <div className="w-full text-left text-sm text-slate-500">
          0 USD
        </div>
        </>
        {/* } */}
      </div>
    </div>
  }
  </div>
  )
}
