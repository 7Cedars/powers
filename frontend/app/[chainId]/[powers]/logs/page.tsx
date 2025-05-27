"use client";

import React, { useEffect, useState } from "react";
import { LogsList } from "./LogsList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { useBlockNumber } from "wagmi";
import { Button } from "@/components/Button";
import { Powers } from "@/context/types";

export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, fetchExecutedActions, status } = usePowers()
  const { data:blockNumber } = useBlockNumber()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center py-20 px-2">
      <LogsList powers={powers} status={status} />
      
      <div className="py-2 pt-6 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic text-center"> 
        {powers && powers.executedActionsBlocksFetched && Number(powers?.executedActionsBlocksFetched?.to) < Number(blockNumber) ?  
          <>
            <p>
              {Number(blockNumber) - Number(powers?.executedActionsBlocksFetched.to)} blocks have not been fetched yet.
            </p>
          </>
         : 
          <div className="py-2 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
            <p>
              Actions are up to date.
            </p>
          </div>
        }
      </div>

      <div className="py-2 w-full max-w-xl h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
        {
          !powers?.executedActionsBlocksFetched?.to || Number(powers?.executedActionsBlocksFetched?.to) < Number(blockNumber) ? 
          <Button
            size={1}
            showBorder={true}
            filled={true}
            onClick={() => {
              fetchExecutedActions(powers as Powers, 10n, 9000n)
            }}
            statusButton={status == "success" ? "idle" : status}
          >
            Fetch Actions
          </Button>
        :
        null 
      }
      </div>
    </main>
  )
} 