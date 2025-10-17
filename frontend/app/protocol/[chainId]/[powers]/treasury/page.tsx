"use client";

import React from "react";
import { AssetList } from "./AssetList";
import { AddAsset } from "./AddAsset";
import { TitleText } from "@/components/StandardFonts";
import { usePowersStore } from "@/context/store";

export default function Page() {
  const powers = usePowersStore(); 
   
  return (
    <main className="w-full h-fit flex flex-col gap-2 justify-center items-center pt-16 ps-4 pe-12">  
      <TitleText
        title="Treasury"
        subtitle="View and manage the assets held by your Powers."
        size={2}
      />
      <AssetList />
      <AddAsset /> 
    </main>
  )
}