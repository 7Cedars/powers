import { Execution, Law, Status, LawExecutions, Powers } from "@/context/types";
import { parseChainId, parseParamValues, parseRole, shorterDescription } from "@/utils/parsers";
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

export const LawLink = ({lawId, powers}: {lawId: bigint, powers: Powers}) => {
  const router = useRouter()
  const { chainId } = useParams()

  // console.log("@LawLink: waypoint 0", {lawId, powers})

  return (
  <main className="w-full min-h-fit flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between bg-slate-100 text-slate-900">
          <div className="text-left w-full px-4 py-2">
            Return to Law
          </div>
        </div>

        {/* Law link block */}
        <div className = "w-full flex flex-col max-h-fit">
              <div className = "w-full flex flex-col justify-center items-center p-2"> 
                  <Button
                      showBorder={true}
                      role={6}
                      onClick={() => router.push(`/${chainId}/${powers.contractAddress}/laws/${lawId}`)}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center px-1">
                            <div className = "text-left"> {`Law ${lawId}: ${shorterDescription(powers?.laws?.find(law => law.index == lawId)?.nameDescription, "short")}`}</div>
                        </div>
                      </div>
                    </Button>
                </div>
        </div>
      </section>
    </main>
  )
}