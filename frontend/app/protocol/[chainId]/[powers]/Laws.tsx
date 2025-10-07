"use client"

import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useParams, useRouter } from "next/navigation";
import { Powers, Status, Law } from "@/context/types";
import { LoadingBox } from "@/components/LoadingBox";
import HeaderLawSmall from "@/components/HeaderLawSmall";
import { bigintToRole } from "@/utils/bigintTo";
import { useChains } from "wagmi";

type LawsProps = {
  powers: Powers | undefined;
  status: Status;
}

export function Laws({powers, status}: LawsProps) {
  const router = useRouter();
  const chains = useChains();
  const { chainId } = useParams<{ chainId: string }>()

  const blockExplorerUrl = chains.find(chain => chain.id === parseInt(chainId))?.blockExplorers?.default.url;
  const activeLaws = powers?.ActiveLaws || [];

  return (
    <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 max-w-full lg:max-w-72 rounded-md overflow-hidden">
      <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
        <button
          onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws`) } 
          className="w-full border-b border-slate-300 p-2 bg-slate-100"
        >
          <div className="w-full flex flex-row gap-6 items-center justify-between">
            <div className="text-left text-sm text-slate-600 w-32">
              Laws
            </div> 
            <ArrowUpRightIcon
              className="w-4 h-4 text-slate-800"
            />
          </div>
        </button>
        
        {status === 'pending' ? 
          <div className="w-full flex flex-col justify-center items-center p-6">
            <LoadingBox /> 
          </div>
        : 
        activeLaws && activeLaws.length > 0 ? 
          <div className="w-full h-fit lg:max-h-56 max-h-48 flex flex-col justify-start items-center overflow-hidden">
            <div className="w-full h-full overflow-x-auto overflow-y-auto">
              <table className="w-full table-auto text-sm">
                <tbody className="w-full text-sm text-left text-slate-500 divide-y divide-slate-200">
                  {activeLaws.map((law: Law, i) => {
                    const roleName = law.conditions?.allowedRole != undefined ? bigintToRole(law.conditions?.allowedRole, powers as Powers) : "-";
                    const numHolders = "-";
                    const lawName = law.nameDescription || `Law #${law.index}`;
                    const truncatedName = lawName.length > 40 ? `${lawName.slice(0, 40)}...` : lawName;
                    
                    return (
                      <tr
                        key={i}
                        className="text-sm text-left text-slate-800 hover:bg-slate-100 cursor-pointer transition-colors"
                        onClick={() => router.push(`/protocol/${chainId}/${powers?.contractAddress}/laws/${law.index}`)}
                      >
                        <td className="ps-2 py-2 w-auto">
                          <HeaderLawSmall
                            powers={powers as Powers}
                            lawName={truncatedName}
                            roleName={roleName}
                            numHolders={numHolders}
                            description=""
                            contractAddress={law.lawAddress || ""}
                            blockExplorerUrl={blockExplorerUrl}
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        :
          <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
            No laws found
          </div>
        }
      </div>
    </div>
  )
}

