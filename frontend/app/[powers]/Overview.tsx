"use client"

import { usePrivy } from "@privy-io/react-auth";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Button } from "@/components/Button";
import { usePowers } from "@/hooks/usePowers";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useEffect } from "react";
import { bigintToRole } from "@/utils/bigintToRole";
import { Powers } from "@/context/types";

interface OverviewProps {
  powers: Powers | undefined
}

export function Overview({powers}: OverviewProps) {
  const { status, updatePowers } = usePowers() 

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = [] 

    if (powers?.deselectedRoles?.includes(role)) {
      newDeselection = powers?.deselectedRoles?.filter((oldRole: bigint) => oldRole != role)
    } else if (powers?.deselectedRoles != undefined) {
      newDeselection = [...powers?.deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
  };
  
  return (
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md">
    {/* table banner  */}
    <div className="w-full h-fit flex flex-row gap-3 justify-between items-center py-2 px-4 border-b slate-300 overflow-y-scroll">
      {powers?.roles.map((role: bigint, i: number) => 
          <div className="flex flex-row w-full min-w-fit h-8" key={i}>
          <Button
            size={0}
            showBorder={true}
            role={role == 4294967295n ? 6 : Number(role)}
            selected={!powers?.deselectedRoles?.includes(BigInt(role))}
            onClick={() => handleRoleSelection(BigInt(role))}
          >
            {bigintToRole(role, powers)} 
          </Button>
          </div>
      )}
    </div>

    {/* Overview here  */}
    <div className = "w-full h-full min-h-fit pt-2 pb-4"> 
      {powers && <GovernanceOverview powers = {powers} />}
    </div> 
  </div>
  )
}
