"use client";

import React from "react";
import { MemberList } from "./MemberList";
import { useParams } from "next/navigation";
import { TitleText } from "@/components/StandardFonts";
import { bigintToRole } from "@/utils/bigintTo";
import { usePowersStore } from "@/context/store";

export default function Page() {
  const { roleId } = useParams<{ roleId: string }>()  
  const powers = usePowersStore(); 
  const roleIdBigInt = roleId ? BigInt(roleId) : 0n
  const roleName = powers ? bigintToRole(roleIdBigInt, powers) : "Loading..."
 
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <TitleText
        title={`Role: ${roleName}`}
        subtitle="View the members of this role."
        size={2}
      />
      
      {/* Role thumbnail and info */}
      
      {powers && roleId && <MemberList powers={powers} roleId={roleIdBigInt} />}
    </main>
  )
}

