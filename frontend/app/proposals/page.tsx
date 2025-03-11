"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";

export default function Page() {  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pt-20 px-2">
      <ProposalList />
    </main>
  )
}

