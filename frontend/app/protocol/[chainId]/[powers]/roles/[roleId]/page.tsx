"use client";

import React, { useEffect } from "react";
import { MemberList } from "./MemberList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { TitleText } from "@/components/StandardFonts";
import { bigintToRole } from "@/utils/bigintTo";

export default function Page() {
  const { powers: addressPowers, roleId } = useParams<{ powers: string, roleId: string }>()  
  const { powers, fetchPowers, status } = usePowers()
  
  const roleIdBigInt = roleId ? BigInt(roleId) : 0n
  const roleName = powers ? bigintToRole(roleIdBigInt, powers) : "Loading..."

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <TitleText
        title={`Role: ${roleName}`}
        subtitle="View the members of this role."
        size={2}
      />
      
      {/* Role thumbnail and info */}
      
      {powers && roleId && <MemberList powers={powers} roleId={roleIdBigInt} status={status} />}
    </main>
  )
}

