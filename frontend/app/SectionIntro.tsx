"use client";

import { useEffect, useRef } from "react";
import Image from 'next/image'
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
  

export function SectionIntro() { 

  return (    
    <section id="intro" className="w-full min-h-screen flex flex-col justify-between items-center bg-gradient-to-b from-indigo-700 to-blue-500 snap-start snap-always p-4">
        {/* title  */}
          <section className="w-full flex flex-col justify-center items-center pt-12">
              <div className = "w-full flex flex-col justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                The next generation of on-chain governance
              </div>
              <div className = "w-full flex justify-center items-center md:text-2xl text-lg text-slate-300 max-w-4xl text-center pt-1">
               Powers allows a single decision to travel along multiple stakeholders through a modular, asynchronous and trustless governance path before it is executed.
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

          {/* documentation link */}
          <section className="w-full max-w-4xl flex flex-row justify-center items-center border border-slate-300 hover:border-slate-600 rounded-md bg-slate-100 text-center p-4"> 
              <div className="flex flex-row"> 
                <a
                  href={`https://7cedars.gitbook.io/powers-protocol`} target="_blank" rel="noopener noreferrer"
                  className="text-2xl text-slate-700 font-bold"
                >
                  Read the documentation
                </a>
                <ArrowUpRightIcon
                  className="w-6 h-6 m-1 text-slate-700 text-center font-bold"
                />
              </div>
          </section>

          {/* Bottom text */}
          {/* <section className="w-full flex flex-col gap-2 justify-center items-center md:text-xl text-lg text-slate-100 max-w-4xl text-center">
              <p>
                Powers provides the infrastructure to guide decisions across multiple stakeholders and voting mechanisms. Completely modular, async, transparant and trustless. 
                It can be integrated into any on-chain organisation, and can be used to govern any type of decision. 
              </p> */}
              {/* <p>
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
              </p> */}
          {/* </section> */}

      {/* arrow down */}
      <div className = "flex flex-col align-center justify-end pb-8"> 
        <ChevronDownIcon
            className = "w-16 h-16 text-slate-100" 
        /> 
      </div>

    </section>
  )
}