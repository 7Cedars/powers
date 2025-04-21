"use client";

import { ArrowPathIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
import React, { useState, useEffect } from "react";
import { assignOrg } from "@/context/store";
import { Button } from "../components/Button";
import { useOrganisations } from "@/hooks/useOrganisations";
import { colourScheme } from "@/context/Theme"
import { Organisation } from "@/context/types";
import { useRouter } from "next/navigation";

export function SectionDemos() {
  const { organisations, status, fetchOrgs, initialise } = useOrganisations()
  const router = useRouter() 

  useEffect(() => {
      initialise() 
  }, [ ])

  // console.log("@landing page:", {status, organisations})
 
  return (
    // min-w-[60vw]
    <>
    
    <section className = "w-full  min-h-fit flex flex-col justify-between items-center snap-start px-4 pb-10 overflow-x-auto overflow-x-hidden"
      id="demos"
    > 
      <div className = "h-fit flex flex-col justify-center items-center min-h-60"> 
        <div className = "w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold pt-24 px-4">
            Want to play around with a live demo?
        </div>
        <div className = "w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-2xl text-center text-pretty py-2 px-4">
            The protocol and examples are proof of concepts. These examples are for TESTING PURPOSES ONLY.
        </div>
        <div className = "w-full flex flex-row justify-center items-center text-md text-slate-400 max-w-2xl text-center text-pretty py-2 pb-16 px-4">
            Really. I'm serious. The protocol has not been audited in any way, shape or form. Don't even think about it using this for anything even remotely resembling an actual community. 
        </div>
      </div> 
      {/* table with example orgs  */}
      { status &&    
      <section className="w-full max-w-5xl h-fit flex flex-col justify-center items-center border border-slate-200 rounded-md overflow-hidden bg-slate-50" >
          <div className="w-full flex flex-col justify-start items-center overflow-scroll">
              <div className="w-full flex flex-col overflow-scroll">
              { organisations ? 
                <table className="w-full table-auto ">
                <thead className="w-full border-b border-slate-200">
                      <tr className="w-96 text-xs font-light text-left text-slate-500">
                      <th className=""></th>
                      <th className="ps-3 py-2 font-light">Name</th>
                      <th className="font-light text-center ">Laws</th>
                      <th className="font-light text-center ">Proposals</th>
                      <th className="font-light text-center ">Roles</th> 
                      <th className="flex flex-row gap-1 justify-between items-between font-light text-left">
                          <div className="py-2 w-full h-full flex gap-1 justify-start items-center text-center">
                              Chain
                          </div> 
                          <button 
                              className="py-2 w-12 h-full flex justify-center items-center text-center aria-selected:animate-spin"
                              onClick = {() => fetchOrgs()}
                              >
                                  <ArrowPathIcon
                                  className="w-4 h-4 text-slate-500 aria-selected:animate-spin"
                                  aria-selected={status == 'pending'}
                                  />
                          </button>
                      </th>
                      </tr>
                  </thead>
                  <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                      {
                      organisations.map((org, index) => {
                        return (
                          <tr
                            key={index}
                            className={`h-16 text-sm text-left min-w-fit text-slate-800 overflow-x-scroll`}
                          >
                              <td className="flex flex-col px-2 h-16 items-center justify-center">
                                  <div className={`h-8 w-8 bg-gradient-to-bl ${colourScheme[index % colourScheme.length]} rounded-full`}/>
                              </td>
                              <td className="pe-4 text-slate-500 min-w-40 max-w-fit">
                                  <Button 
                                      size={1} align={0} showBorder={true} selected = {true} filled = {false} onClick={() => {
                                        assignOrg({...org, colourScheme: index % colourScheme.length})
                                        router.push('/home')
                                        }}>
                                      {org.name}
                                  </Button>
                              </td>
                              <td className="pe-4 text-slate-500 text-center min-w-12">{org.laws?.length}</td>
                              <td className="pe-4 text-slate-500 text-center min-w-12">{org.proposals?.length}</td>
                              <td className="pe-4 text-slate-500 text-center min-w-12">{org.roles?.length}</td>
                              <td className="ps-1 text-slate-500 text-left max-w-12"> Arbitrum Sepolia </td>
                          </tr>
                        )
                      })
                    }
                  </tbody>
                </table>
                :
                <div className = "w-full flex flex-row gap-4 align-center items-center text-center font-md min-w-fit text-slate-800 h-16 animate-pulse px-4">
                  <div className = "ps-6 p-2 size-8 rounded-full bg-slate-300" />
                  <div className = "flex-1 space-y-3 py-1">
                    <div className="h-2 rounded bg-slate-300"/>
                    <div className = "grid grid-cols-3 gap-4"  >   
                      <div className="col-span-2 h-2 rounded bg-slate-300"/>
                      <div className="col-span-1 h-2 rounded bg-slate-300"/>
                    </div> 
                  </div> 
                </div> 
              }
              </div>
          </div> 
      </section>
      }
    </section>
    </>
  )
}