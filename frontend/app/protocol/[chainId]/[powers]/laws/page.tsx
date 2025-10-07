"use client";

import React, { useEffect } from "react";
import { LawList } from "@/app/protocol/[chainId]/[powers]/laws/LawList";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { TitleText } from "@/components/StandardFonts";
 
export default function Page() {    
  const { powers: addressPowers } = useParams<{ powers: string }>()  
  const { powers, fetchPowers, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <TitleText
        title="Laws"
        subtitle="View the laws of the organization."
        size={2}
      />
      {powers && <LawList powers={powers} status={status} />}
    </main>
  )
}
