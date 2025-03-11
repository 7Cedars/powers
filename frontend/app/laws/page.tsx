"use client";

import React from "react";
import {LawList} from "@/app/laws/LawList";

export default function Page() {     
    return (
      <main className="w-full min-h-fit flex flex-col justify-start items-center pt-20 px-2 overflow-x-scroll">
        <LawList />
      </main>
    )
}
