import { Execution, Law, Status, LawExecutions, Powers } from "@/context/types";
import { parseChainId, parseParamValues, parseRole } from "@/utils/parsers";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";
import { LoadingBox } from "@/components/LoadingBox";
import { setAction, setError, useActionStore } from "@/context/store";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { getPublicClient, readContract } from "wagmi/actions";
import { lawAbi, powersAbi } from "@/context/abi";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect } from "react";
import { useBlocks } from "@/hooks/useBlocks";
import { useAction } from "@/hooks/useAction";

type ExecutionsProps = {
  roleId: bigint;
  lawExecutions: LawExecutions | undefined
  powers: Powers | undefined;
  status: Status;
};

export const Executions = ({roleId, lawExecutions, powers, status}: ExecutionsProps) => {
  const { chainId } = useParams<{ chainId: string }>()
  const { timestamps, fetchTimestamps } = useBlocks()
  const { fetchActionData } = useAction()

  useEffect(() => {
    if (lawExecutions) {
      const blocks = lawExecutions.executions
      if (blocks && blocks.length > 0) {
        fetchTimestamps(blocks, chainId)
      }
    }
  }, [lawExecutions, chainId])

  return (
  <main className="w-full max-h-fit grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between bg-slate-100 text-slate-900">
          <div className="text-left w-full px-4 py-2">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {status == "pending" ?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <LoadingBox />
        </div>
        :
        lawExecutions?.executions && lawExecutions?.executions?.length != 0 ?  
        <div className = "w-full flex flex-col max-h-36 overflow-y-scroll divide-y divide-slate-300">
            {lawExecutions?.executions.map((execution, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2" key = {index}> 
                  <Button
                      showBorder={true}
                      role={Number(roleId)}
                      onClick={() => fetchActionData(lawExecutions.actionsIds[index], powers as Powers)}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center px-1">
                            <div className = "text-left"> {toFullDateFormat(Number(timestamps.get(`${chainId}:${execution}`)?.timestamp))}</div>
                            <div className = "text-right"> {toEurTimeFormat(Number(timestamps.get(`${chainId}:${execution}`)?.timestamp))}</div>
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
    </main>
  )
}