"use client";

import { Button } from "@/components/Button"; 
import { usePowers } from "@/hooks/usePowers";
import { useState } from "react";
import { TwoSeventyRingWithBg } from "react-svg-spinners";
import { useRouter } from "next/navigation";

export function SectionRunDemo() {
  const router = useRouter()
  const [newDemoAddress, setNewDemoAddress] = useState<`0x${string}`>()
  const {status, error} = usePowers()

  return (
    <section className="min-h-screen flex flex-col justify-center items-center pb-8 px-4 snap-start snap-always">
      <div className="w-full flex flex-col gap-12 justify-center items-center h-full">
       <section className = "flex flex-col justify-center items-center"> 
          <div className = "w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold px-4">
            Or do you have a demo of your own deployed?
          </div>
          <div className = "w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-2xl text-center text-pretty py-2 px-4">
              The protocol is proof of concept. Please deploy your own examples for TESTING PURPOSES ONLY.
          </div>
          <div className = "w-full flex flex-row justify-center items-center text-md text-slate-400 max-w-2xl text-center text-pretty py-2 pb-16 px-4">
              Really. I'm serious. The protocol has not been audited in any way, shape or form. Don't even think about it using this for anything even remotely resembling an actual community. 
          </div>
      </section> 

      <section className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-200 rounded-md overflow-hidden max-w-5xl">
        <div className="w-full flex flex-row gap-4 justify-between items-center py-4 px-5">
          <div className="min-w-28 grow flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
            <input 
              type= "text" 
              name={`input`} 
              id={`input`}
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm" 
              placeholder={`Enter protocol address here.`}
              onChange={(event) => {setNewDemoAddress(event.target.value as `0x${string}`)}}
              />
          </div>

          {
            newDemoAddress && 
            <div className="h-8 flex flex-row w-20 min-w-24 text-center">
              <Button 
                size = {0} 
                role = {6} 
                onClick={() => { 
                  router.push(`/421614/${newDemoAddress}`) // NB! This is hardcoded for now.  Have to add a option menu for chainId. 
                }}
              > 
                <div className = "text-slate-600">{
                  status && status == 'pending' ? <TwoSeventyRingWithBg /> : "Visit"  
                }
                </div>    
              </Button>
            </div>
          }
        </div>
      </section>
      
      { status && status == 'error' && 
        <div className = "text-sm">
          <div className = "text-red-500 pb-4">
            {typeof error == "string" ?  error.slice(0, 30) : "Protocol not recognised"}
          </div> 
        </div>
      }
    </div>
    </section>
  ) 
} 