"use client";

import React from "react";
import { MandateList } from "@/app/protocol/[chainId]/[powers]/mandates/MandateList";
import { TitleText } from "@/components/StandardFonts";
import { usePowersStore } from "@/context/store";
 
export default function Page() {    
  const powers = usePowersStore(); 
  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4">
      <TitleText
        title="Mandates"
        subtitle="View the mandates of the organization."
        size={2}
      />
      {powers && <MandateList powers={powers} status={status} />}
    </main>
  )
}
