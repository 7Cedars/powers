"use client";

import Image from 'next/image'
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
  

export function SectionIntro() { 

  return (    
    <section id="intro" className="w-full min-h-screen flex flex-col justify-between items-center bg-gradient-to-b from-indigo-700 to-blue-500 snap-start snap-always p-4">
        {/* title  */}
          <section className="w-full flex flex-col justify-center items-center pt-12">
              <div className = "w-full flex flex-col justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty pb-2">
                Composable Governance
              </div>
              <div className = "w-full flex justify-center items-center md:text-2xl text-lg text-slate-300 max-w-4xl text-center pt-1">
                Powers allows any community to compose complex resilient institutions by configuring relationships between role-restricted mandates.
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
          <section className="w-full max-w-4xl flex flex-row justify-center items-center p-4"> 
              <a className="w-full h-fit flex flex-row justify-center items-center text-center py-3 px-12 sm:text-2xl text-xl text-slate-200 hover:text-slate-50 border border-slate-200 hover:border-slate-50 rounded-md text-center"
                    href={`https://powers-docs.vercel.app/welcome`} target="_blank" rel="noopener noreferrer">
                        Read the documentation 
              </a>
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