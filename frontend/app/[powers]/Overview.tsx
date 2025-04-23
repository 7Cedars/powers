"use client"

import { Button } from "@/components/Button";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { bigintToRole } from "@/utils/bigintToRole";
import { Powers } from "@/context/types";
import { setRole, useRoleStore } from "@/context/store";
import { usePowers } from "@/hooks/usePowers";
import { ArrowPathIcon } from "@heroicons/react/24/outline";

interface OverviewProps {
  powers: Powers | undefined
}

export function Overview({powers}: OverviewProps) {
  const {deselectedRoles} = useRoleStore()
  const {status, updatePowers} = usePowers()

  console.log("@Overview: waypoint 1", {status})

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
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md">
    {/* table banner  */}
    <div className="w-full h-fit flex flex-row gap-3 justify-between items-center py-2 px-4 border-b slate-300 overflow-y-scroll">
      {powers?.roles.map((role: bigint, i: number) => 
          <div className="flex flex-row w-full min-w-fit h-8" key={i}>
          <Button
            size={0}
            showBorder={true}
            role={role == 4294967295n ? 6 : Number(role)}
            selected={!deselectedRoles?.includes(BigInt(role))}
            onClick={() => handleRoleSelection(BigInt(role))}
          >
            {bigintToRole(role, powers)} 
          </Button>
          </div>
      )}
      {powers && 
          <button 
            className="w-fit h-fit p-1 rounded-md border-slate-500"
            onClick = {() => updatePowers(powers?.contractAddress || "")}
            disabled={status == 'pending'}
            >
              <ArrowPathIcon
                className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
                aria-selected={status == 'pending'}
                />
          </button>
        }
    </div>

    {/* Overview here  */}
    <div className = "w-full h-full min-h-fit pt-2 pb-4"> 
      {powers && <GovernanceOverview powers = {powers} />}
    </div> 
  </div>
  )
}
