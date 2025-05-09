"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";

export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, updateProposals, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers() // addressPowers as `0x${string}`
    }
  }, [addressPowers, fetchPowers])


  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pt-20 px-2">
      <ProposalList powers={powers} onUpdateProposals={() => updateProposals(addressPowers as `0x${string}`)} status={status} />
    </main>
  )
}

