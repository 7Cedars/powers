"use client";

import React, { useEffect } from "react";
import { RoleList } from "./RoleList";
import { useParams } from "next/navigation";
import { usePowers } from "@/hooks/usePowers";
import { TitleText } from "@/components/StandardFonts";
import { Powers } from "@/context/types";

export default function Page() {
  const { powers: addressPowers} = useParams<{ powers: string }>()  
  const { powers, fetchPowers, fetchRoles, status } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])
  
  return (
    <main className="w-full h-fit flex flex-col justify-start items-center pb-20 pt-16 ps-4 pe-12">
      <div className="w-full flex flex-row justify-between items-end gap-4 mb-2">
        <TitleText
          title="Roles"
          subtitle="View roles and their holders in the organization."
          size={2}
        />
        <button
          onClick={() => fetchRoles(powers as Powers)}
          disabled={status === 'pending'}
          className="flex items-center justify-center w-9 h-9 bg-slate-50 border border-slate-300 rounded-md hover:bg-slate-100 transition-colors disabled:opacity-50 flex-shrink-0"
          aria-label="Refetch roles"
        >
          <svg 
            className={`h-5 w-5 text-slate-600 ${status === 'pending' ? 'animate-spin' : ''}`} 
            xmlns="http://www.w3.org/2000/svg" 
            fill="none" 
            viewBox="0 0 24 24" 
            stroke="currentColor"
          >
            <path 
              strokeLinecap="round" 
              strokeLinejoin="round" 
              strokeWidth={2} 
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" 
            />
          </svg>
        </button>
      </div>
      {powers && <RoleList powers={powers} status={status} />}
    </main>
  )
}

