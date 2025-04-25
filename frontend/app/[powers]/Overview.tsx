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
  onUpdatePowers: () => void
  status: string
}

export function Overview({powers, onUpdatePowers, status}: OverviewProps) {
  const {deselectedRoles} = useRoleStore()

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
    {/* table banner  */}
    <div className="w-full min-h-fit flex flex-row gap-3 justify-between items-center py-2 px-4 border-b border-slate-300 overflow-y-scroll">
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
            className="w-fit min-h-fit p-1 rounded-md border-slate-500"
            onClick = {() => {
              onUpdatePowers()
            }}
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
    <div className = "min-h-fit w-full pt-2 pb-4"> 
      <GovernanceOverview powers = {powers} />
    </div> 
  </div>
  )
}
