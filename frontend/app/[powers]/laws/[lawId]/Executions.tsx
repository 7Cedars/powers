import { Execution, Law } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";

type ExecutionsProps = {
  executions: Execution[] | undefined
  onClick: (execution: Execution) => void;
  law: Law;
};

export const Executions = ({executions, onClick, law}: ExecutionsProps) => {
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {
          executions && executions?.length != 0 ?  
          <div className = "w-full flex flex-col max-h-36 lg:max-h-56 overflow-y-scroll divide-y divide-slate-300">
            {executions.map((execution: Execution, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2" key = {index}> 
                  <Button
                      showBorder={true}
                      role={parseRole(law.conditions.allowedRole)}
                      onClick={() => onClick(execution)}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center px-1">
                            <div> {toFullDateFormat(Number(execution.blocksData?.timestamp))}</div>
                            <div> {toEurTimeFormat(Number(execution.blocksData?.timestamp))}</div>
                        </div>
                      </div>
                    </Button>
                </div>
                )
            }
            </div>
            :
            <div className = "w-full flex flex-col justify-center items-center italic text-slate-400 p-2">
                No executions found. 
            </div> 
          }
    </section>
  )
}