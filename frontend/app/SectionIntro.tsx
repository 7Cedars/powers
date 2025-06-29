"use client";

import { useEffect, useRef } from "react";
import Image from 'next/image'
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
  

export function SectionIntro() { 

  return (    
    <section id="intro" className="w-full min-h-screen flex flex-col justify-between items-center bg-gradient-to-b from-indigo-700 to-blue-600 snap-start snap-always">
        {/* title  */}
          <section className="w-full flex flex-col justify-center items-center pt-12">
              <div className = "w-full flex flex-col justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                  The next generation of on-chain governance
              </div>
              <div className = "w-full flex justify-center items-center md:text-2xl text-lg text-slate-300 max-w-2xl text-center pt-1">
                Powers + Laws = Governance
              </div>
          </section>

          {/* Image  */}
          <section className = "w-full max-w-6xl flex flex-col justify-center items-center relative aspect-video my-8"> 
            <Image 
                src={"/powers101.png"} 
                className = "p-2 rounded-md" 
                style={{objectFit: "contain"}}
                fill={true}
                alt="Screenshot Powers App"
                priority
                >
            </Image>
          </section>

          {/* Bottom text */}
          <section className="w-full flex flex-col gap-2 justify-center items-center md:text-xl text-lg text-slate-100 max-w-4xl text-center">
              <p>
                Powers is a PoC of a role restricted governance protocol. 
              </p>
              <p>
                It combines a governance engine, <span className="font-bold">Powers</span>, with role restricted and modular contracts, called <span className="font-bold">laws</span>.
              </p>
              <div className="flex flex-col gap-0">
                <p>              
                  <span className="font-bold">Laws</span> define what actions can be taken by which roles under what conditions. 
                </p>
                <p>
                  <span className="font-bold">Powers</span> manages assigning roles to addresses and executing actions. 
                </p>
              </div>
              <p>
                Together they create a governance protocol that is modular, upgradable and asynchronous.
              </p>
          </section>

      {/* arrow down */}
      <div className = "flex flex-col align-center justify-end pb-8"> 
        <ChevronDownIcon
            className = "w-16 h-16 text-slate-100" 
        /> 
      </div>

    </section>
  )
}