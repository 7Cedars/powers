"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { useBlockNumber } from "wagmi";
import { Button } from "@/components/Button";
import { Powers } from "@/context/types";
import { TitleText } from "@/components/StandardFonts";

export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, fetchProposals, status } = usePowers()
  const { data: blockNumber } = useBlockNumber()

  // console.log("@Proposals page, waypoint 0", {powers, status, blockNumber})

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pt-16 ps-4 pe-12">
      <TitleText
        title="Proposals"
        subtitle="View and manage the proposals for your Powers."
        size={2}
      />
      <ProposalList powers={powers} status={status} />
      {/* block number */}
      
      <div className="py-2 pt-6 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic text-center"> 
        {powers && powers.proposalsBlocksFetched && Number(powers?.proposalsBlocksFetched?.to) < Number(blockNumber) ?  
          <>
            <p>
              {Number(blockNumber) - Number(powers?.proposalsBlocksFetched.to)} blocks have not been fetched yet.
            </p>
          </>
         : 
          <div className="py-2 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
            <p>
              Proposals are up to date.
            </p>
          </div>
        }
      </div>

      <div className="py-2 w-full max-w-xl h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
        {
          !powers?.proposalsBlocksFetched?.to || Number(powers?.proposalsBlocksFetched?.to) < Number(blockNumber) ? 
          <Button
            size={1}
            showBorder={true}
            filled={true}
            onClick={() => {
              fetchProposals(powers as Powers, 10n, 9000n)
            }}
          statusButton={status == "success" ? "idle" : status}
        >
          Fetch Proposals
        </Button>
        :
        null 
      }
      </div>

    </main>
  )
}

