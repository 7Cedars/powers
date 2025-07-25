"use client";

import { useCases } from  "../public/useCases";
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";

export function SectionUsecases() { 
  const router = useRouter()

  return (
    <main className="w-full min-h-screen flex flex-col justify-center items-center bg-gradient-to-b from-blue-500 to-slate-100 snap-start snap-always py-12 px-2"
      id="usecases"
    >    
      <div className="w-full flex flex-col gap-12 justify-between items-center h-full">
        {/* title & subtitle */}
        <div className="w-full flex flex-col justify-center items-center pt-10">
            <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-4xl text-2xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                The Added Value of Powers
            </div>
            <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-2xl text-xl text-slate-100 max-w-4xl text-center text-pretty">
                Powers has several advantages in comparison to existing governance protocols. 
            </div>
        </div>

        {/* info blocks */}
        <section className="w-full flex flex-wrap gap-4 max-w-6xl justify-center items-start overflow-y-auto">  
              {useCases.map((useCase, index) => (
                    <div className="w-72 min-h-64 max-h-64 flex flex-col justify-between items-between border border-slate-300 rounded-md bg-slate-50 overflow-hidden" key={index}>  
                      <div className="w-full font-bold text-slate-700 p-3 ps-5 border-b border-slate-300 bg-slate-100">
                          {useCase.title}
                      </div> 
          
                      <ul className="w-full h-full flex flex-col justify-start items-start ps-5 pe-4 gap-2 p-3">
                        {
                          useCase.details.map((detail, i) => <li key={i}> {detail} </li> )
                        }
                      </ul>
                      <div className="w-full max-w-4xl flex flex-row justify-between items-center text-center ps-3 pe-2 p-3"> 
                          <button className="flex flex-row justify-between items-start border border-slate-300 hover:border-slate-600 rounded-md p-2 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:border-slate-300"
                            disabled={useCase.address === "0x0000000000000000000000000000000000000000" ? true : false}
                            onClick={() => {
                                router.push(`/${useCase.chainId}/${useCase.address}`)
                            }}> 
                            {useCase.demo}
                            <ArrowUpRightIcon
                              className="w-4 h-4 m-1 text-slate-700 text-center font-bold"
                            />
                          </button>
                      </div>
                    </div> 
                ))
              }
        </section>

        {/* arrow down */}
        <div className = "flex flex-col align-center justify-center pb-8"> 
          <ChevronDownIcon
            className = "w-16 h-16 text-slate-100" 
          /> 
        </div>
      </div>
    </main> 
  )
}