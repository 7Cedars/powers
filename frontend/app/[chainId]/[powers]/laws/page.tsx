"use client";

import React, { useEffect } from "react";
import {LawList} from "@/app/[chainId]/[powers]/laws/LawList";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
 
export default function Page() {    
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, status } = usePowers()

  // console.log("@laws, waypoint 0", {powers, status})

  useEffect(() => {
    if (!powers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [powers])

  return (
    <main className="w-full min-h-fit flex flex-col justify-start items-center pt-20 ps-2 pe-12 overflow-x-scroll">
      <LawList powers = {powers} status={status} />
    </main>
  )
}
