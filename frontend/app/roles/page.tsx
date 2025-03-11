"use client";

import React, { useState } from "react";
import { RoleList } from "./RoleList";
import { usePathname } from 'next/navigation'

export default function Page() {
  
    return (
      <main className="w-full h-fit flex flex-col justify-center items-center pt-20 px-2">
        <RoleList />
      </main>
    )
}

