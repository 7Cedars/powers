// This should become landing page: 
// searchers for deployed Separated Powers Protocols.
// Has search bar.
// also has template DAOs to deploy.  
// Loads names,# laws, # proposals, # roles, # members, chain. 
// see example: https://www.tally.xyz/explore

"use client";

import React, { useState, useEffect } from "react";
import { SectionIntro } from "./SectionIntro";
import { SectionUsecases } from "./SectionUsecases";
import { SectionRunDemo } from "./SectionRunDemo";
import { SectionDeployCarousel } from "./SectionDeployCarousel";
import { Footer } from "./Footer";
import { SectionAdvantages } from "./SectionAdvantages";

import { 
    ChevronDownIcon
  } from '@heroicons/react/24/outline';

export default function Page() {          
    return (
        <main className="w-full h-screen flex flex-col overflow-y-auto snap-y snap-mandatory overflow-x-hidden bg-slate-50">
            <section className="w-full min-h-screen flex flex-col justify-center items-center bg-gradient-to-b from-indigo-900 to-indigo-700 snap-start snap-always"> 
            
                {/* Title and subtitle */}
                <section className="w-full flex flex-col justify-center items-center p-4 pt-20 pb-20">
                    <div className = "w-full flex flex-col gap-2 justify-center items-center text-3xl sm:text-6xl text-slate-100 max-w-2xl text-center text-pretty">
                        Communities thrive with 
                        <b>Powers</b>  
                    </div>
                    <div className = "w-full flex justify-center items-center text-xl sm:text-2xl py-4 text-slate-300 max-w-3xl text-center p-4">
                        Increase security, transparency and efficiency by separating and distributing powers in on-chain organisations.
                    </div>
                </section> 

                {/* arrow down */}
                <div className = "flex flex-col align-center justify-end pb-8"> 
                <ChevronDownIcon
                    className = "w-16 h-16 text-slate-100" 
                /> 
                </div>
            </section>

            < SectionIntro /> 
            {/* < SectionAdvantages />  */}
            < SectionUsecases /> 
            {/* < SectionRunDemo /> */}
            < SectionDeployCarousel />
            <div className = "min-h-48"/>  
            < Footer /> 
           
        </main>
    )
}
