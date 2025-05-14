import { Execution, Law, Status, LawExecutions } from "@/context/types";
import { parseParamValues, parseRole } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";
import { LoadingBox } from "@/components/LoadingBox";
import { setAction, useActionStore } from "@/context/store";
import { decodeAbiParameters, parseAbiParameters } from "viem";

type ExecutionsProps = {
  executions: LawExecutions | undefined
  law: Law | undefined;
  status: Status;
};

export const Executions = ({executions, law, status}: ExecutionsProps) => {

  // console.log("@Executions: ", {executions, law, status})
// THIS HAS TO BE REFACTORED. Use read contract, _actions . This needs a getter function! 
  const handleExecutionSelection = (execution: Execution) => {
    // console.log("@Executions: handleExecutionSelection: ", {execution, law})
    let dataTypes = law?.params?.map(param => param.dataType)
    let valuesParsed = undefined
    if (dataTypes != undefined && dataTypes.length > 0) {
      const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), execution.log.args.lawCalldata);
      valuesParsed = parseParamValues(values) 
    }
    setAction({
      actionId: undefined,
      lawId: law?.index,
      caller: execution.log.args.caller,
      dataTypes: dataTypes,
      paramValues: valuesParsed ? valuesParsed : undefined,
      nonce: execution.log.args.nonce,
      description: execution.log.args.description,
      callData: execution.log.args.lawCalldata,
      upToDate: false
    })
  }
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {status == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        executions?.executions && executions.executions?.length != 0 ?  
        <div className = "w-full flex flex-col max-h-36 lg:max-h-56 overflow-y-scroll divide-y divide-slate-300">
            {executions.executions.map((execution, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2" key = {index}> 
                  <Button
                      showBorder={true}
                      role={law?.conditions?.allowedRole != undefined ? parseRole(law.conditions?.allowedRole) : 0}
                      onClick={() => handleExecutionSelection(execution)}
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