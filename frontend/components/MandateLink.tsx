import { Powers } from "@/context/types";
import { shorterDescription } from "@/utils/parsers";
import { Button } from "@/components/Button";
import { useParams, useRouter } from "next/navigation";

export const MandateLink = ({mandateId, powers}: {mandateId: bigint, powers: Powers}) => {
  const router = useRouter()
  const { chainId } = useParams()

  // console.log("@MandateLink: waypoint 0", {mandateId, powers})

  return (
  <main className="w-full min-h-fit flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between bg-slate-100 text-slate-900">
          <div className="text-left w-full px-4 py-2">
            Return to Mandate
          </div>
        </div>

        {/* Mandate link block */}
        <div className = "w-full flex flex-col max-h-fit">
              <div className = "w-full flex flex-col justify-center items-center p-2"> 
                  <Button
                      showBorder={true}
                      role={6}
                      onClick={() => router.push(`/protocol/${chainId}/${powers.contractAddress}/mandates/${mandateId}`)}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center px-1">
                            <div className = "text-left"> {`Mandate ${mandateId}: ${shorterDescription(powers?.mandates?.find(mandate => mandate.index == mandateId)?.nameDescription, "short")}`}</div>
                        </div>
                      </div>
                    </Button>
                </div>
        </div>
      </section>
    </main>
  )
}