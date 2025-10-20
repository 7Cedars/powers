"use client";

import React from "react";
import { RoleList } from "./RoleList";
import { TitleText } from "@/components/StandardFonts";
import { Powers } from "@/context/types";
import { usePowersStore } from "@/context/store";

export default function Page() {
  const powers = usePowersStore(); 
  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4">
      <div className="w-full flex flex-row justify-between items-end gap-4 mb-2">
        <TitleText
          title="Roles"
          subtitle="View roles and their holders in the organization."
          size={2}
        />
      </div>
      {powers && <RoleList powers={powers} />}
    </main>
  )
}

