import { advantages } from "@/public/advantages";
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";


export function SectionAdvantages() {

  return (
    <main className="w-full min-h-screen flex flex-col justify-center items-center bg-gradient-to-b from-blue-600 to-blue-500 snap-start snap-always py-12 px-2"
      id="advantages"
    > 
    <div className="w-full flex flex-col gap-12 justify-between items-center h-full">
      {/* title & subtitle */}
      <section className="w-full flex flex-col justify-center items-center">
          <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
              Advantages
          </div>
      </section>

      {/* info blocks */}
      <section className="w-full flex flex-wrap gap-4 max-w-6xl justify-center items-start overflow-y-auto">  
          {   
            advantages.map((advantage, index) => (
                  <div className="w-72 min-h-60 flex flex-col justify-start items-center border border-slate-300 rounded-md bg-slate-50 overflow-hidden" key={index}>  
                    <div className="w-full font-bold text-slate-700 p-3 ps-5 border-b border-slate-300 bg-slate-100">
                        {advantage.advantage}
                    </div> 
                    <ul className="w-full flex flex-col justify-start items-start ps-5 pe-4 p-3 gap-3">
                      {
                        advantage.examples.map((example, i) => <li key={i}> {example} </li> )
                      }
                    </ul>
                  </div>
            ))
          }
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