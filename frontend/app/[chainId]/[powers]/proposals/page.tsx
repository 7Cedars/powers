"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { useBlockNumber } from "wagmi";
import { Button } from "@/components/Button";
import { Powers } from "@/context/types";
export default function Page() { 
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchProposals, status } = usePowers()

  console.log("@status: ", status)
  
  const { data:blockNumber } = useBlockNumber()
  // useEffect(() => {
  //   if (addressPowers) {
  //     fetchPowers() // addressPowers as `0x${string}`
  //   }
  // }, [addressPowers, fetchPowers])

  powers && powers.proposalsFetched && console.log("@proposals: waypoint 1", powers?.proposalsFetched[0].from, powers?.proposalsFetched[powers?.proposalsFetched.length - 1].to)

  return (
    <main className="w-full h-fit flex flex-col justify-start items-center py-20 px-2">
      <ProposalList powers={powers} onUpdateProposals={() => {}} status={status} />
      {/* block number */}
   
      
      <div className="py-2 pt-6 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic text-center"> 
        {powers && powers.proposalsFetched ?  
          <>
            <p>
              Blocks between {Number(powers?.proposalsFetched[0].from)} and {Number(powers?.proposalsFetched[powers?.proposalsFetched.length - 1].to)} have been fetched.
            </p>
            <p>
              The current block is {Number(blockNumber)}.
            </p>
          </>
         : 
          <div className="py-2 w-full h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
            <p>
              No proposals have been fetched yet.
            </p>
          </div>
        }
      </div>

      <div className="py-2 w-full max-w-xl h-fit flex flex-col gap-1 justify-start items-center text-slate-500 text-md italic"> 
        <Button
          size={1}
          showBorder={true}
          filled={true}
          onClick={() => {
            fetchProposals(powers as Powers, 10)
          }}
          statusButton={status}
        >
          Fetch Proposals
        </Button>
      </div>

    </main>
  )
}

