"use client"

import { usePrivy } from "@privy-io/react-auth";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { assignOrg, useOrgStore } from "@/context/store";
import { Button } from "@/components/Button";
import { Organisation } from "@/context/types";
import { useOrganisations } from "@/hooks/useOrganisations";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useEffect } from "react";
import { bigintToRole } from "@/utils/bigintToRole";

export function Overview( ) {
  const organisation = useOrgStore(); 
  const { status, updateOrg } = useOrganisations() 

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (organisation?.deselectedRoles?.includes(role)) {
      newDeselection = organisation?.deselectedRoles?.filter(oldRole => oldRole != role)
    } else if (organisation?.deselectedRoles != undefined) {
      newDeselection = [...organisation?.deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    assignOrg({...organisation, deselectedRoles: newDeselection})
  };
  
  return (
    <div className="w-full h-fit flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md">
    {/* table banner  */}
    <div className="w-full h-fit flex flex-row gap-3 justify-between items-center py-2 px-4 border-b slate-300 overflow-y-scroll">
      {organisation?.roles.map((role, i) => 
          <div className="flex flex-row w-full min-w-fit h-8" key={i}>
          <Button
            size={0}
            showBorder={true}
            role={role == 4294967295n ? 6 : Number(role)}
            selected={!organisation?.deselectedRoles?.includes(BigInt(role))}
            onClick={() => handleRoleSelection(BigInt(role))}
          >
            {bigintToRole(role, organisation)} 
          </Button>
          </div>
      )}
      <button 
        className="w-fit h-fit p-1 rounded-md border-slate-500"
        onClick = {() => updateOrg(organisation)}
        >
          <ArrowPathIcon
            className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
            aria-selected={status == 'pending'}
            />
      </button>
    </div>

    {/* Overview here  */}
    <div className = "w-full h-fit pt-2 pb-4"> 
      <GovernanceOverview /> 
    </div> 
  </div>
  )
}
