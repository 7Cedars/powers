"use client";

import React, { useEffect } from "react";
import {LawList} from "@/app/[chainId]/[powers]/laws/LawList";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";

export default function Page() {    
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, updatePowers, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])
   
  return (
    <main className="w-full min-h-fit flex flex-col justify-start items-center pt-20 px-2 overflow-x-scroll">
      <LawList powers = {powers} onUpdatePowers={() => updatePowers(addressPowers as `0x${string}`)} status={status} />
    </main>
  )
}
