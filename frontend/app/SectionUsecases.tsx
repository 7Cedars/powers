"use client";

import { useEffect, useRef } from "react";
import { useCases } from  "../public/useCases";
import Image from 'next/image'
import { ArrowPathIcon, ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
import { Button } from "@/components/Button";
import { assignOrg } from "@/context/store";
import { useRouter } from "next/navigation";
import { useOrganisations } from "@/hooks/useOrganisations";

export function SectionUsecases() { 
  const router = useRouter()
  const { organisations, status, fetchOrgs, initialise } = useOrganisations()

  console.log("@usecases:", {organisations})
  console.log("@usecases, status:", {status})

  useEffect(() => {
    initialise()
  }, [ ])

  return (
    <main className="w-full min-h-screen flex flex-col gap-12 justify-center items-center bg-gradient-to-b from-blue-500 to-slate-100 snap-start snap-always py-12 px-2"
      id="usecases"
    >    
      <div className="w-full h-fit flex flex-col gap-12 justify-between items-center min-h-[60vh]">
        {/* title & subtitle */}
        <div className="w-full h-fit flex flex-col justify-center items-center pt-10 ">
            <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                Use cases
            </div>
        </div>

        {/* info blocks */}
        <section className="h-full flex flex-wrap gap-4 max-w-6xl justify-center items-start">  
            { organisations ?
              useCases.map((useCase, index) => (
                    <div className="w-72 min-h-64 h-fit flex flex-col justify-start items-start border border-slate-300 rounded-md bg-slate-50 overflow-hidden" key={index}>  
                      <div className="w-full h-fit font-bold text-slate-700 p-3 ps-5 border-b border-slate-300 bg-slate-100">
                          {useCase.title}
                      </div> 
                      <ul className="grow flex flex-col justify-start items-start ps-5 pe-4 gap-2 p-3">
                        {
                          useCase.details.map((detail, i) => <li key={i}> {detail} </li> )
                        }
                      </ul>
                      <div className="w-full max-w-4xl h-fit flex flex-row justify-between items-center text-center ps-3 pe-2 p-3"> 
                          <button className="h-full w-full flex flex-row justify-between items-start border border-slate-300 hover:border-slate-600 rounded-md p-2 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:border-slate-300"
                            disabled={organisations.find(org => org.name ===  useCase.demo) ? false : true}
                            onClick={() => {
                                assignOrg({...organisations.find(org => org.name ===  useCase.demo), colourScheme: useCase.colourScheme})
                                router.push('/home')
                            }}> 
                            {useCase.demo}
                            <ArrowUpRightIcon
                              className="w-4 h-4 m-1 text-slate-700 text-center font-bold"
                            />
                          </button>
                      </div>
                    </div>
              ))
              : 
              <div className="w-64 grow h-full flex flex-col justify-center items-center">
                 <button  className="h-fit w-full flex flex-row justify-between items-center border border-slate-300 bg-slate-50 hover:border-slate-600 rounded-md p-4 text-slate-700"
                          onClick = {() => fetchOrgs()}
                          >
                          Fetch use cases
                          <ArrowPathIcon
                            className="w-5 h-5 text-slate-700 aria-selected:animate-spin"
                            aria-selected={status == 'pending'}
                          />
                </button>
              </div>
            }
        </section>

        {/* arrow down */}
        <div className = "grow flex flex-col align-center justify-center"> 
          <ChevronDownIcon
            className = "w-16 h-16 text-slate-100" 
          /> 
        </div>
      </div>
    </main> 
  )
}