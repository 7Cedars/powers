"use client";

import React, { useEffect, useState } from "react";
import { LogsList } from "./LogsList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { useBlockNumber } from "wagmi";
import { Button } from "@/components/Button";
import { Powers } from "@/context/types";

export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, fetchExecutedActions, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center py-20 ps-2 pe-12">
      {powers && <LogsList powers={powers} status={status} onRefresh={() => {
        fetchExecutedActions(powers as Powers)
      }}/>}
    </main>
  )
} 