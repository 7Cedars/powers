"use client";

import React, { useEffect, useState } from "react";
import { RoleList } from "./RoleList";
import { useParams, usePathname } from 'next/navigation'
import { usePowers } from "@/hooks/usePowers";

export default function Page() {
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])
  
    return (
      <main className="w-full h-fit flex flex-col justify-center items-center pt-20 ps-2 pe-12">
        <RoleList powers={powers} status={status} />
      </main>
    )
}

