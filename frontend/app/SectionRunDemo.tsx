"use client";

import { Button } from "@/components/Button"; 
import { useOrganisations } from "@/hooks/useOrganisations";
import { useState } from "react";
import { TwoSeventyRingWithBg } from "react-svg-spinners";

export function SectionRunDemo() {
  const [newDemoAddress, setNewDemoAddress] = useState<`0x${string}`>()
  const {status, error, organisations, addOrg} = useOrganisations()

  return (
    <section className="min-h-screen h-0 flex flex-col justify-center items-center pb-8 px-4 snap-start snap-always opacity-0 md:opacity-100">
      <div className="w-full h-fit flex flex-col gap-12 justify-between items-center min-h-[30vh]">
       <section className = "h-fit flex flex-col justify-center items-center min-h-fit"> 
          <div className = "w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold px-4">
            Or do you have a demo of your own deployed?
          </div>
          <div className = "w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-2xl text-center text-pretty py-2 px-4">
              The protocol and examples are proof of concepts. These examples are for TESTING PURPOSES ONLY.
          </div>
          <div className = "w-full flex flex-row justify-center items-center text-md text-slate-400 max-w-2xl text-center text-pretty py-2 pb-16 px-4">
              Really. I'm serious. The protocol has not been audited in any way, shape or form. Don't even think about it using this for anything even remotely resembling an actual community. 
          </div>
      </section> 

      <section className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-200 rounded-md overflow-hidden max-w-5xl">
        <div className="w-full flex flex-row gap-4 min-w-6xl justify-between items-center py-4 px-5 overflow-x-scroll overflow-y-hidden">
          <div className="text-slate-900 text-center font-bold text-md min-w-24">
            Organisation
          </div>
   
          <div className="grow min-w-28 flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
            <input 
              type= "text" 
              name={`input`} 
              id={`input`}
              className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm" 
              placeholder={`Enter protocol address here.`}
              onChange={(event) => {setNewDemoAddress(event.target.value as `0x${string}`)}}
              />
          </div>

      
          <div className="h-8 flex flex-row w-20 min-w-24 text-center">
            {
              newDemoAddress && 
              <Button 
                size = {0} 
                role = {8} 
                onClick={() => {addOrg(newDemoAddress)}}
                > 
                <div className = "text-slate-600">{
                  status && status == 'pending' ? <TwoSeventyRingWithBg /> : "Start"  
                }
                </div>    
              </Button>
            }
          </div>
        </div>
      </section>
      
        <div className = "text-sm h-fit">
          { status && status == 'error' ? 
              <div className = "text-red-500 pb-4">
                {typeof error == "string" ?  error.slice(0, 30) : "Protocol not recognised"}
              </div> 
            :
            null 
          }
        </div>
      </div>
    </section>
  ) 
} 