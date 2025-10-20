"use client";

import React from "react";
import { LawList } from "@/app/protocol/[chainId]/[powers]/laws/LawList";
import { TitleText } from "@/components/StandardFonts";
import { usePowersStore } from "@/context/store";
 
export default function Page() {    
  const powers = usePowersStore(); 
  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4">
      <TitleText
        title="Laws"
        subtitle="View the laws of the organization."
        size={2}
      />
      {powers && <LawList powers={powers} status={status} />}
    </main>
  )
}
