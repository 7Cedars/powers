import { Organisation } from "@/context/types";

export const bigintToRole = (roleId: bigint, organisation: Organisation): string  => {
  const roleIds = organisation.roleLabels.map(roleLabel => roleLabel.roleId) 
  const roleLabel = 
    roleId == 4294967295n ? "Public" 
    :
    roleId == 0n ? "Admin" 
    :
    roleIds.includes(roleId) ? organisation.roleLabels.find(roleLabel => roleLabel.roleId == roleId)?.label : `Role ${Number(roleId)}`

  return roleLabel ? String(roleLabel).charAt(0).toUpperCase() + String(roleLabel).slice(1) : "Error" 
}