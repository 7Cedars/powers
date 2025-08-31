"use client";

import React, { useEffect, useState } from "react";
import { LogsList } from "./LogsList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { Powers } from "@/context/types";
import { TitleText } from "@/components/StandardFonts";

export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, fetchExecutedActions, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <TitleText
        title="Logs"
        subtitle="View the logs of the actions executed by your Powers."
        size={2}
      />
      {powers && <LogsList powers={powers} status={status} onRefresh={() => {
        fetchExecutedActions(powers as Powers)
      }}/>}
    </main>
  )
} 