"use client";

import {
  useActionStore,
  useStatusStore,
  usePowersStore,
  useErrorStore,
  setError,
  setStatus,
} from "@/context/store";
import { useChecks } from "@/hooks/useChecks";
import { useLaw } from "@/hooks/useLaw";
import { useWallets } from "@privy-io/react-auth";
import { useParams } from "next/navigation";
import React, { useEffect, useState } from "react";

import { Button } from "@/components/Button";
import { shorterDescription } from "@/utils/parsers";
import { Checks, InputType, Law, Powers } from "@/context/types";
import { encodeAbiParameters, parseAbiParameters } from "viem";

export function DynamicActionButton({checks}: {checks: Checks}) {
  const { wallets, ready } = useWallets();
  const action = useActionStore();
  const powers = usePowersStore();
  const status = useStatusStore();
  const error = useErrorStore(); 

  const { request, propose } = useLaw();
  const law = powers?.laws?.find((law) => BigInt(law.index) == BigInt(action.lawId));
  const savedAction = law?.actions?.find(
    (a) => BigInt(a.actionId) == BigInt(action.actionId)
  );
  const populatedAction = savedAction?.state == 0 || savedAction?.state == undefined ? action : savedAction;

  // console.log("DynamicActionButton:", {checks, law, populatedAction, action, status, error})

  const [logSupport, setLogSupport] = useState<bigint>();
  const { castVote } = useLaw();

  const handlePropose = async (
    paramValues: (InputType | InputType[])[],
    nonce: bigint,
    description: string
  ) => {
    console.log("@handlePropose: waypoint 0", {
      paramValues,
      nonce,
      description,
    });
    if (!law) return;

    setError({ error: null });
    // setStatus({ status: "idle" });
    let lawCalldata: `0x${string}` = "0x0";

    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(
          parseAbiParameters(
            law.params?.map((param) => param.dataType).toString() || ""
          ),
          paramValues
        );
      } catch (error) {
        setError({ error: error as Error });
      }
    } else {
      lawCalldata = "0x0";
    }

    if (lawCalldata && ready && wallets && powers?.contractAddress) {
      const success = await propose(
        law.index as bigint,
        lawCalldata,
        nonce,
        description,
        powers as Powers
      );
      // console.log("@handlePropose: waypoint 1", {paramValues, nonce, description})
    }
  };

  const handleExecute = async (
    law: Law,
    paramValues: (InputType | InputType[])[],
    nonce: bigint,
    description: string
  ) => {
    // console.log("Handle Execute called:", {paramValues, nonce})
    setError({ error: null });
    // setStatus({ status: "idle" });
    let lawCalldata: `0x${string}` | undefined;
    // console.log("Handle Simulate waypoint 1")
    if (paramValues.length > 0 && paramValues) {
      try {
        // console.log("Handle Simulate waypoint 2a")
        lawCalldata = encodeAbiParameters(
          parseAbiParameters(
            law.params?.map((param) => param.dataType).toString() || ""
          ),
          paramValues
        );
        // console.log("Handle Simulate waypoint 2b", {lawCalldata})
      } catch (error) {
        // console.log("Handle Simulate waypoint 2c")
        setError({ error: error as Error });
      }
    } else {
      // console.log("Handle Simulate waypoint 2d")
      lawCalldata = "0x0";
    }

    const success = await request(
      law,
      lawCalldata as `0x${string}`,
      nonce,
      description
    );
    console.log("@handleExecute: waypoint 1", {
      paramValues,
      nonce,
      description,
    }); 
  };

  return (
    <div className="w-full pt-4">
      {
        //NB: note that the 'Check' button is managed in the DynamicForm component
        
        // option 1: When action does not exist, and needs a vote, create proposal button
        Number(law?.conditions?.quorum) > 0 &&
        (populatedAction?.state == 0 || populatedAction?.state == undefined) &&
        action?.upToDate ? (
          <div className="w-full px-6 py-2" help-nav-item="propose-or-vote">
            <div className="w-full">
              <Button
                size={0}
                role={6}
                onClick={() => {
                  handlePropose(
                    action.paramValues ? action.paramValues : [],
                    BigInt(action.nonce as string),
                    action.description as string
                  );
                }}
                filled={false}
                selected={true}
                statusButton={checks?.authorised ? status.status : "disabled"}
              >
                {!checks?.authorised
                  ? "Not authorised to make proposal"
                  : `Create proposal for '${shorterDescription(
                      law?.nameDescription,
                      "short"
                    )}'`}
              </Button>
            </div>
          </div>
        ) : // option 2: When action does not exist and does not need a vote, execute button
        Number(law?.conditions?.quorum) == 0 &&
          populatedAction?.state == 0 &&
          action?.upToDate ? (
          <div
            className="w-full h-fit px-6 py-2 pb-6"
            help-nav-item="execute-action"
          >
            <Button
              size={0}
              role={6}
              onClick={() =>
                handleExecute(
                  law as Law,
                  action.paramValues ? action.paramValues : [],
                  BigInt(action.nonce as string),
                  action.description as string
                )
              }
              // (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string)
              filled={false}
              selected={true}
              statusButton={
                checks?.allPassed
                  ? status.status == "success"
                    ? "idle"
                    : status.status
                  : "disabled"
              }
            >
              Execute {checks?.allPassed ? "" : " (checks did not pass)"}
            </Button>
          </div>
        ) : // option 2: When action does exist and has a succeeded state, execute button
        Number(law?.conditions?.quorum) > 0 &&
          populatedAction?.state == 5 &&
          action?.upToDate ? (
          <div
            className="w-full h-fit px-6 py-2 pb-6"
            help-nav-item="execute-action"
          >
            <Button
              size={0}
              role={6}
              onClick={() =>
                handleExecute(
                  law as Law,
                  action.paramValues ? action.paramValues : [],
                  BigInt(action.nonce as string),
                  action.description as string
                )
              }
              filled={false}
              selected={true}
              statusButton={
                checks?.allPassed
                  ? status.status == "success"
                    ? "idle"
                    : status.status
                  : "disabled"
              }
            >
              Execute {checks?.allPassed ? "" : " (checks did not pass)"}
            </Button>
          </div>
        ) : populatedAction?.state == 4 && action?.upToDate ? (
          <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
            <div className="w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500">
              Action defeated
            </div>
          </div>
        ) : // option 3: When action exists, and is active, show vote button
        populatedAction?.state == 3 && action?.upToDate ? (
          <div className="w-full h-fit px-6 min-h-16 flex flex-col justify-center items-center">
            {checks && checks.hasVoted ? (
              <div className="w-full flex text-sm flex-row justify-center items-center gap-2 text-slate-500">
                Account has voted
              </div>
            ) : (
              <div className="w-full flex flex-row gap-2">
                <Button
                  size={0}
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(
                      BigInt(populatedAction.actionId),
                      1n,
                      powers as Powers
                    );
                    setLogSupport(1n);
                  }}
                  statusButton={
                    status.status == "pending" && logSupport == 1n
                      ? "pending"
                      : "idle"
                  }
                >
                  For
                </Button>
                <Button
                  size={0}
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(
                      BigInt(populatedAction.actionId),
                      0n,
                      powers as Powers
                    );
                    setLogSupport(0n);
                  }}
                  statusButton={
                    status.status == "pending" && logSupport == 0n
                      ? "pending"
                      : "idle"
                  }
                >
                  Against
                </Button>
                <Button
                  size={0}
                  selected={true}
                  filled={false}
                  onClick={() => {
                    castVote(
                      BigInt(populatedAction.actionId),
                      2n,
                      powers as Powers
                    );
                    setLogSupport(2n);
                  }}
                  statusButton={
                    status.status == "pending" && logSupport == 2n
                      ? "pending"
                      : "idle"
                  }
                >
                  Abstain
                </Button>
              </div>
            )}
          </div>
        ) : null
      }
    </div>
  );
}
