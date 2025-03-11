"use client";

import React, { useEffect, useState } from "react";
import { assignOrg, setAction, setLaw, useOrgStore } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter } from "next/navigation";
import { Proposal } from "@/context/types";
import { parseProposalStatus, parseRole } from "@/utils/parsers";
import { useProposal } from "@/hooks/useProposal";
import { setProposal } from "@/context/store"
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useOrganisations } from "@/hooks/useOrganisations";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { bigintToRole } from "@/utils/bigintToRole";


// NB: need to delete action from store? Just in case? 
export function ProposalList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const [ deselectedStatus, setDeselectedStatus] = useState<string[]>(['1', '2', '3', '4'])
  const { status: statusFetch, fetchProposals } = useProposal()
  
  const possibleStatus: string[] = ['0', '1', '2', '3', '4']; 

  // console.log({organisation})

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (organisation?.deselectedRoles?.includes(role)) {
      newDeselection = organisation?.deselectedRoles?.filter(oldRole => oldRole != role)
    } else if (organisation?.deselectedRoles != undefined) {
      newDeselection = [...organisation?.deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    assignOrg({...organisation, deselectedRoles: newDeselection})
  };

  const handleStatusSelection = (proposalStatus: string) => {
    let newDeselection: string[] = []
    if (deselectedStatus.includes(proposalStatus)) {
      newDeselection = deselectedStatus.filter(option => option !== proposalStatus)
    } else {
      newDeselection = [...deselectedStatus, proposalStatus]
    }
    setDeselectedStatus(newDeselection)
  };

  return (
    <div className="w-full min-w-96 flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-hidden">
      {/* table banner:roles  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center pt-3 px-6 overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Proposals
        </div>
        {organisation?.roles.map((role, i) => 
            <div className="flex flex-row w-full min-w-fit h-8" key={i}>
            <Button
              size={0}
              showBorder={true}
              role={role == 4294967295n ? 6 : Number(role)}
              selected={!organisation?.deselectedRoles?.includes(BigInt(role))}
              onClick={() => handleRoleSelection(BigInt(role))}
            >
              {bigintToRole(role, organisation)} 
            </Button>
            </div>
        )}
        <button 
          className="w-fit h-fit p-1"
          onClick = {() => fetchProposals(organisation)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={statusFetch == 'pending'}
              />
        </button>
      </div>

      {/* table banner:status  */}
      <div className="w-full flex flex-row gap-3 justify-between items-between py-2 overflow-y-scroll border-b border-slate-200 px-6">
      {
        possibleStatus.map((option, i) => {
          return (
            <button 
            key = {i}
            onClick={() => handleStatusSelection(option)}
            className="w-fit h-full hover:text-slate-400 text-sm aria-selected:text-slate-800 text-slate-300"
            aria-selected = {!deselectedStatus?.includes(option)}
            >  
              <p className="text-sm text-left"> {parseProposalStatus(option)} </p>
          </button>
          )
        })
      }
      </div>

      {/* table laws  */}
      <div className="w-full overflow-scroll">
      <table className="w-full table-auto">
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Date & time </th>
                <th className="font-light"> Law name </th>
                <th className="font-light"> Reason </th>
                <th className="font-light"> Status </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {
            organisation.proposals?.map((proposal: Proposal, i) => {
              const law = organisation?.laws?.find(law => law.law == proposal.targetLaw)
              // console.log("timeStamp: ", proposal.voteStartBlockData?.timestamp)
              return (
                law && 
                law.allowedRole != undefined && 
                !organisation?.deselectedRoles?.includes(BigInt(`${law.allowedRole}`)) && 
                !deselectedStatus.includes(String(proposal.state) ? String(proposal.state) : '9') 
                ? 
                <tr
                  key={i}
                  className={`text-sm text-left text-slate-800 h-full p-2 overflow-x-scroll`}
                >
                  <td className="h-full w-full flex flex-col text-center justify-center items-center text-left py-3 px-4">
                      <Button
                        showBorder={true}
                        role={parseRole(law.allowedRole)}
                        onClick={() => {
                          setLaw(law);
                          setProposal(proposal)
                          setAction({
                            description: proposal.description,
                            callData: proposal.executeCalldata,
                            upToDate: true
                          })
                          router.push("/proposals/proposal");
                        }}
                        align={0}
                        selected={true}
                      > <div className = "flex flex-row gap-3 w-full min-w-48">
                        {`${toFullDateFormat(Number(proposal.voteStartBlockData?.timestamp))}: ${toEurTimeFormat(Number(proposal.voteStartBlockData?.timestamp))}`}
                        </div>
                      </Button>
                  </td>
                  <td className="pe-4 text-slate-500 min-w-56">{law.name}</td>
                  <td className="pe-4 text-slate-500 min-w-48">{proposal.description}</td>
                  <td className="pe-4 text-slate-500">{parseProposalStatus(String(proposal.state))}</td>
                  <td className="pe-4 min-w-20 text-slate-500"> {bigintToRole(law.allowedRole, organisation)}
                  </td>
                </tr>
                : 
                null
              )
            }
          )}
        </tbody>
      </table>
      </div>
    </div>
  );
}
