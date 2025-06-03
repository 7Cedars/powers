"use client"

import { Button } from "@/components/Button";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { bigintToRole } from "@/utils/bigintToRole";
import { Powers } from "@/context/types";
import { setRole, useRoleStore } from "@/context/store";
import { ArrowPathIcon, MapIcon } from "@heroicons/react/24/outline";
import { LoadingBox } from "@/components/LoadingBox";
import { useParams } from "next/navigation";
import Link from "next/link";

interface OverviewProps {
  powers: Powers | undefined
  onUpdatePowers: () => void
  status: string
}

export function Overview({powers, status, onUpdatePowers}: OverviewProps) {
  const {deselectedRoles} = useRoleStore()
  const { chainId, powers: powersAddress } = useParams<{ chainId: string, powers: string }>()

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = [] 

    if (deselectedRoles?.includes(role)) {
      newDeselection = deselectedRoles?.filter((oldRole: bigint) => oldRole != role)
    } else if (deselectedRoles != undefined) {
      newDeselection = [...deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    setRole({deselectedRoles: newDeselection})
  };
  
  return (
    <div className="w-full min-h-fit flex flex-col gap-0 justify-start items-center bg-slate-50 border border-slate-300 rounded-md">
    {/* {
    status == "pending" || status == "idle" ? 
    <div className="w-full h-full flex flex-col justify-start text-sm text-slate-500 items-start p-3">
      <LoadingBox /> 
    </div>
    :  */}
    <>
    {/* table banner  */}
    <div className="w-full min-h-fit flex flex-row gap-3 justify-between items-center py-2 px-4 border-b border-slate-300 overflow-y-scroll">
      {powers?.roles?.map((role: bigint, i: number) => 
          <div className="flex flex-row w-full min-w-fit h-8" key={i}>
          <Button
            size={0}
            showBorder={true}
            role={role == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? 6 : Number(role)}
            selected={!deselectedRoles?.includes(BigInt(role))}
            onClick={() => handleRoleSelection(BigInt(role))}
          >
            {bigintToRole(role, powers)} 
          </Button>
          </div>
      )}
      <div className="flex flex-row gap-2">
        {/* Flow Visualization Link */}
        <Link href={`/${chainId}/${powersAddress}/flow`}>
          <button 
            className="w-fit h-fit p-1 rounded-md border border-slate-300 hover:bg-slate-100 transition-colors"
            title="View Law Dependency Graph"
          >
            <MapIcon className="w-5 h-5 text-slate-800" />
          </button>
        </Link>
        
        {/* Refresh Button */}
        {onUpdatePowers && 
          <button 
            className="w-fit h-fit p-1 rounded-md border-slate-500"
            onClick = {() => onUpdatePowers()}
            >
              <ArrowPathIcon
                className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
                aria-selected={status == 'pending'}
                />
          </button>
        }
      </div>
    </div>

    {/* Overview here  */}
    <div className = "min-h-fit w-full pt-2 pb-4"> 
      <GovernanceOverview powers = {powers} />
    </div> 
    </>
    {/* } */}
  </div>
  )
}
