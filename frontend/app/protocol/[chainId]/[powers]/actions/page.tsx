"use client";

import React, { useEffect } from "react";
import { ActionsList } from "./ActionsList";
import { TitleText } from "@/components/StandardFonts";
import { usePowersStore } from "@/context/store";

export default function Page() { 
  const powers = usePowersStore(); 

  useEffect(() => {
    console.log("@Actions page: waypoint 0", {powers})
  }, [powers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <div className="w-full flex flex-row justify-between items-end gap-4 mb-2">
        <TitleText
          title="Actions"
          subtitle="View the actions executed by the organization."
          size={2}
        />
      </div>
      {powers && <ActionsList powers={powers} />}
    </main>
  )
} 