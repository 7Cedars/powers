import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, LawSimulation, Law, LawExecutions, Action, Powers, ActionTruncated, DataType } from "../context/types"
import { getConnectorClient, readContract, simulateContract, writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { usePrivy } from "@privy-io/react-auth";
import { usePowers } from "./usePowers";
import { parseActionData, parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { setAction, useActionStore } from "@/context/store";

export const useAction = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [actionData, setActionData ] = useState<Action | undefined>()

  const fetchActionData = useCallback( 
    async (actionId: bigint, powers: Powers) => {
      setError(null)
      setStatus("pending")

      console.log("@useAction: waypoint 0", {actionId, powers})
      
        try {
            const lawCalldata = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getActionCalldata',
            args: [actionId]
            })  

            const actionUri = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getActionUri',
            args: [actionId]
            })
            
            const actionData = await readContract(wagmiConfig, {
            abi: powersAbi,
            address: powers.contractAddress as `0x${string}`,
            functionName: 'getActionData',
            args: [actionId]
            })
            const parsedActionData: ActionTruncated = parseActionData(actionData as unknown as unknown[])
            console.log("@useAction: waypoint 1", {lawCalldata, actionUri, actionData})

            if (lawCalldata && actionUri != undefined && actionData != undefined) {
              console.log("@Executions: waypoint 3:" , {lawCalldata, actionUri, actionData})
              const law = powers.laws?.find(law => law.index == parsedActionData.lawId)

              let dataTypes = law?.params?.map(param => param.dataType)
              let valuesParsed = undefined
              if (dataTypes != undefined && dataTypes.length > 0) {
                const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), lawCalldata as `0x${string}`);
                valuesParsed = parseParamValues(values) 
              }

              console.log("@useAction: waypoint 4", {dataTypes, valuesParsed, law})

              const returnActionData: Action = {
                  actionId: String(actionId),
                  lawId: parsedActionData.lawId,
                  caller: parsedActionData.caller,
                  dataTypes: dataTypes,
                  paramValues: valuesParsed,
                  nonce: String(parsedActionData.nonce),
                  description: actionUri as string,
                  callData: lawCalldata as `0x${string}`,
                  upToDate: false,
                  state: parsedActionData.state,
                  voteStart: parsedActionData.voteStart,
                  voteDuration: parsedActionData.voteDuration,
                  voteEnd: parsedActionData.voteEnd,
                  againstVotes: parsedActionData.againstVotes,
                  forVotes: parsedActionData.forVotes,
                  abstainVotes: parsedActionData.abstainVotes,
                  cancelled: parsedActionData.cancelled,
                  requested: parsedActionData.requested,
                  fulfilled: parsedActionData.fulfilled
              }
              setAction(returnActionData)
              setActionData(returnActionData)

              console.log("@useAction: waypoint 5", {returnActionData})
            }
        } catch (error) {
            console.log("@Executions: ", error)
        }
            
    }, [ ]
)

  return {status, error, actionData, fetchActionData}
}