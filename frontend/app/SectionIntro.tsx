"use client";

import { useEffect, useRef } from "react";
import Image from 'next/image'
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
  

export function SectionIntro() { 

  return (    
    <section id="intro" className="w-full min-h-screen h-fit flex flex-col gap-6 justify-between items-center bg-gradient-to-b from-indigo-700 to-blue-600 snap-start snap-always py-12 px-6">
        {/* title  */}
          <section className="w-full h-screen min-h-fit flex flex-col justify-center items-center pt-12">
              <div className = "w-full flex flex-col justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                  The next generation of on-chain governance
              </div>
              <div className = "w-full flex justify-center items-center md:text-2xl text-lg text-slate-300 max-w-2xl text-center pt-1">
                Powers + Laws = Governance
              </div>
          </section>

          {/* sm:h-full sm:w-full sm:max-h-full sm:max-w-full max-h-0 max-w-0 */}
          {/* Image  */}
          <section className = "grow h-full w-full max-w-6xl flex flex-col justify-center items-center" style = {{position: 'relative', width: '100%', height: '100%'}}> 
            <Image 
                src={"/home2.png"} 
                className = "p-2 rounded-md" 
                style={{objectFit: "contain", objectPosition: "center"}}
                fill={true}
                alt="Screenshot Powers App"
                >
            </Image>
          </section>

          {/* Bottom text */}
          <section className="w-full min-h-fit flex flex-col gap-2 justify-center items-center md:text-xl text-lg text-slate-100 max-w-4xl text-center">
              <p>
                Powers is a Proof of Concept of a role restricted governance protocol. 
              </p>
              <p>
                It combines a governance engine with role restricted and modular contracts, called laws. 
                Together they create a governance protocol that is more flexible, upgradable and safe than existing alternatives.
              </p>
  

          </section>


      {/* arrow down */}
      <div className = "flex flex-col align-center justify-end pb-20"> 
        <ChevronDownIcon
            className = "w-16 h-16 text-slate-100" 
        /> 
      </div>

    </section>
  )

}