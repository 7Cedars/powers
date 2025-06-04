import { Execution, Law, Status, LawExecutions } from "@/context/types";
import { parseChainId, parseParamValues, parseRole } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";
import { LoadingBox } from "@/components/LoadingBox";
import { setAction, setError, useActionStore } from "@/context/store";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { getPublicClient, readContract } from "wagmi/actions";
import { lawAbi, powersAbi } from "@/context/abi";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useParams } from "next/navigation";
import { useCallback, useEffect } from "react";
import { useBlocks } from "@/hooks/useBlocks";

type ExecutionsProps = {
  lawExecutions: LawExecutions | undefined
  law: Law | undefined;
  status: Status;
};

export const Executions = ({lawExecutions, law, status}: ExecutionsProps) => {
  const { chainId } = useParams<{ chainId: string }>()
  const action = useActionStore()
  const { data: blocks, fetchBlocks, status: blocksStatus } = useBlocks()

  useEffect(() => {
    if (lawExecutions && lawExecutions.executions && lawExecutions.executions.length > 0 && blocksStatus == "idle") {
      fetchBlocks(lawExecutions.executions.map(execution => execution), chainId)
    }
  }, [lawExecutions, chainId, blocksStatus])

  // console.log("@Executions: ", {executions, law, status})
  const handleExecutionSelection = useCallback(
    async (index: number, law: Law | undefined, lawExecutions: LawExecutions | undefined) => {
    // console.log("@Executions: waypoint 1", {index, lawExecutions, law, status, action})
    
    if (lawExecutions && index != undefined && law) {
      // console.log("@Executions: waypoint 2", {index, law, status, action, executionAtIndex: lawExecutions.actionsIds[Number(index)]})
      try {
        const lawCalldata = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: law?.powers as `0x${string}`,
          functionName: 'getActionCalldata',
          args: [BigInt(lawExecutions.actionsIds[Number(index)])]
        })  

        const actionUri = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: law?.powers as `0x${string}`,
          functionName: 'getActionUri',
          args: [BigInt(lawExecutions.actionsIds[Number(index)])]
        })
        
        const actionNonce = await readContract(wagmiConfig, {
          abi: powersAbi,
          address: law?.powers as `0x${string}`,
          functionName: 'getActionNonce',
          args: [BigInt(lawExecutions.actionsIds[Number(index)])]
        })

        // console.log("@Executions: waypoint 2", {lawCalldata, actionUri, actionNonce})

        if (lawCalldata && actionUri && actionNonce) {
          // console.log("@Executions: waypoint 3")

          let dataTypes = law?.params?.map(param => param.dataType)
          let valuesParsed = undefined
          if (dataTypes != undefined && dataTypes.length > 0) {
            const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), lawCalldata as `0x${string}`);
            valuesParsed = parseParamValues(values) 
          }

          // console.log("@Executions: waypoint 4")

          setAction({
            actionId: String(lawExecutions.actionsIds[Number(index)]),
            lawId: law?.index,
            caller: undefined,
            dataTypes: dataTypes,
            paramValues: valuesParsed,
            nonce: actionNonce.toString(),
            uri: actionUri as string,
            callData: lawCalldata as `0x${string}`,
            upToDate: false
          })

          // console.log("@Executions: waypoint 5")
        }
      } catch (error) {
        console.log("@Executions: ", error)
      }
    }
  }, [ ])

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 bg-slate-100">
          <div className="text-left w-full">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {status == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        lawExecutions?.executions && lawExecutions.executions?.length != 0 ?  
        <div className = "w-full flex flex-col max-h-36 overflow-y-scroll divide-y divide-slate-300">
            {lawExecutions.executions.map((execution, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2" key = {index}> 
                  <Button
                      showBorder={true}
                      role={law?.conditions?.allowedRole != undefined ? parseRole(law.conditions?.allowedRole) : 0}
                      onClick={() => handleExecutionSelection(index, law, lawExecutions)}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center px-1">
                            <div> {toFullDateFormat(Number(blocks?.[index]?.timestamp || 0))}</div>
                            <div> {toEurTimeFormat(Number(blocks?.[index]?.timestamp || 0))}</div>
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