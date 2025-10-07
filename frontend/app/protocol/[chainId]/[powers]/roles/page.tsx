"use client";

import React, { useEffect, useState } from "react";
import { RoleList } from "./RoleList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { TitleText } from "@/components/StandardFonts";

export default function Page() {
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])
  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <TitleText
        title="Roles"
        subtitle="View roles and their holders in the organization."
        size={2}
      />
      {powers && <RoleList powers={powers} status={status} />}
    </main>
  )
}

