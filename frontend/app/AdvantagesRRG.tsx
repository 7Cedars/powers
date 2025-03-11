import { advantagesRRGs } from "@/public/advantagesRRGs";
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";


export function AdvantagesRRG() {

  return (
    <main className="w-full min-h-fit flex flex-col gap-0 justify-start items-center bg-gradient-to-b from-blue-400 to-slate-100 snap-start snap-always pt-12">    
      {/* title & subtitle */}
      <div className="w-full h-fit flex flex-col justify-center items-center pt-10 ">
          <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-4xl text-3xl font-bold text-slate-700 max-w-4xl text-center text-pretty">
              Advantages of Role Restricted Governance
          </div>
          <div className = "w-full flex justify-center items-center md:text-2xl text-xl py-4 text-slate-500 max-w-2xl text-center p-4 pb-20">
              The Powers protocol combines a governance engine with minimalistic modular contracts, or laws, to create a role restrict governance protocol.
          </div>
      </div>

      {/* info blocks */}
      <section className="h-fit flex flex-wrap gap-4 max-w-6xl justify-center items-start pb-6">  
          {   
            advantagesRRGs.map((advantage, index) => (
                  <div className="w-72 min-h-60 h-fit flex flex-col justify-center items-center border border-slate-300 rounded-md bg-slate-50 overflow-hidden" key={index}>  
                    <div className="w-full h-fit font-bold text-slate-700 p-3 ps-5 border-b border-slate-300 bg-slate-100">
                        {advantage.advantage}
                    </div> 
                    <ul className="grow flex flex-col justify-start items-start ps-5 pe-4 p-3 gap-3">
                      {
                        advantage.examples.map((example, i) => <li key={i}> {example} </li> )
                      }
                    </ul>
                  </div>
            ))
        }

        

      </section>
      <div className = "w-full  max-w-4xl h-fit flex flex-row justify-center items-center items-center border border-slate-300 hover:border-slate-600 rounded-md bg-slate-100 text-center p-4"> 
          <div className="h-full w-fit flex flex-row"> 
            <a
              href={`https://7cedars.gitbook.io/powers-protocol`} target="_blank" rel="noopener noreferrer"
              className="w-full text-2xl text-slate-700 font-bold"
            >
              Read the documentation
            </a>
            <ArrowUpRightIcon
              className="w-6 h-6 m-1 text-slate-700 text-center font-bold"
            />
          </div>
        </div>

      {/* arrow down */}
      <div className = "grow flex flex-col align-center justify-center"> 
        <ChevronDownIcon
          className = "w-16 h-16 text-slate-700" 
        /> 
      </div>
    </main> 
  )
}