import { Powers } from "@/context/types";

export const bigintToRole = (roleId: bigint, powers: Powers): string  => {
  if (powers &&  powers.roleLabels != undefined && powers.roleLabels.length > 0) { 
    const roleIds = powers.roleLabels.map(roleLabel => roleLabel.roleId) 
    const roleLabel = 
      roleId == 4294967295n ? "Public" 
      :
      roleId == 0n ? "Admin" 
      :
      roleIds.includes(roleId) ? powers.roleLabels.find(roleLabel => roleLabel.roleId == roleId)?.label : `Role ${Number(roleId)}`
    
      return roleLabel ? String(roleLabel).charAt(0).toUpperCase() + String(roleLabel).slice(1) : "Error" 
  } else {
    return `Role ${Number(roleId)}`
  }
}