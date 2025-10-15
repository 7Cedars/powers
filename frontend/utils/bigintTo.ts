import { Powers } from "@/context/types";

export const bigintToRole = (roleId: bigint, powers: Powers): string  => {
  // console.log("@bigintToRole: waypoint 0", {roleId, powers})

  let roleIds: bigint[] = [] 
  
  if (powers?.roles != undefined && powers.roles.length > 0) { 
    roleIds = powers.roles.map(role => role.roleId)
  }
  // console.log("@bigintToRole: waypoint 1", {roleIds})

  const roleLabel = 
    roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n ? "Public" 
    :
    roleId == 0n ? "Admin" 
    :
    roleIds.includes(roleId) ? powers.roles?.find(role => role.roleId == roleId)?.label : `Role ${Number(roleId)}`
  // console.log("@bigintToRole: waypoint 2", {roleLabel})
  return roleLabel ? String(roleLabel).charAt(0).toUpperCase() + String(roleLabel).slice(1) : `Role ${Number(roleId)}`
}

export const bigintToRoleHolders = (roleId: bigint, powers: Powers): string | "∞" => {
  // console.log("@bigintToRoleHolders: waypoint 0", {roleId, powers})

  if (roleId == 115792089237316195423570985008687907853269984665640564039457584007913129639935n) {
    return "∞"
  }

  return powers.roles?.find(role => Number(role.roleId) == Number(roleId))?.amountHolders ? 
    String(powers.roles?.find(role => Number(role.roleId) == Number(roleId))?.amountHolders) 
    : 
    "0"
}