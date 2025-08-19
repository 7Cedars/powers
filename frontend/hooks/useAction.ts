import { useCallback, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { Status, Action, Powers, ActionTruncated, LawExecutions } from "../context/types"
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { parseActionData, parseParamValues } from "@/utils/parsers";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import { setAction } from "@/context/store";

export const useAction = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [data, setData ] = useState<Action | undefined>()

  const fetchActionData = useCallback( 
    async (actionId: bigint, powers: Powers) => {
      setError(null)
      setStatus("pending")

      // console.log("@useAction: waypoint 0", {actionId, powers})
      
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
            // console.log("@useAction: waypoint 1", {actionData})
            const parsedActionData: ActionTruncated = parseActionData(actionData as unknown[])
            // console.log("@useAction: waypoint 2", {lawCalldata, actionUri, parsedActionData})

            if (lawCalldata && actionUri != undefined && actionData != undefined) {
              // console.log("@Executions: waypoint 3:" , {lawCalldata, actionUri, actionData})
              const law = powers.laws?.find(law => law.index == parsedActionData.lawId)
              // console.log("@useAction: waypoint 2.0", {law})
              const executions = await readContract(wagmiConfig, {
                abi: lawAbi,
                address: law?.lawAddress as `0x${string}`,
                functionName: 'getExecutions',
                args: [powers.contractAddress as `0x${string}`, parsedActionData.lawId]
              })
              // console.log("@useAction: waypoint 2.1", {executions})
              const executionsParsed = executions as unknown as LawExecutions
              // console.log("@useAction: waypoint 3", {executionsParsed})
              const index = executionsParsed.actionsIds.findIndex(a => a == actionId)
              // console.log("@useAction: waypoint 4", {executionsParsed, index})
              const executedAt = executionsParsed.executions[index]
              // console.log("@useAction: waypoint 5", {executedAt})

              let dataTypes = law?.params?.map(param => param.dataType)
              let valuesParsed = undefined
              if (dataTypes != undefined && dataTypes.length > 0) {
                const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), lawCalldata as `0x${string}`);
                valuesParsed = parseParamValues(values) 
              }

              // console.log("@useAction: waypoint 4", {dataTypes, valuesParsed, law})

              const returnActionData: Action = {
                  actionId: String(actionId),
                  lawId: parsedActionData.lawId,
                  caller: parsedActionData.caller,
                  dataTypes: dataTypes,
                  paramValues: valuesParsed,
                  nonce: String(parsedActionData.nonce),
                  description: actionUri as string,
                  callData: lawCalldata as `0x${string}`,
                  upToDate: true,
                  state: parsedActionData.state,
                  voteStart: parsedActionData.voteStart,
                  voteDuration: parsedActionData.voteDuration,
                  voteEnd: parsedActionData.voteEnd,
                  againstVotes: parsedActionData.againstVotes,
                  executedAt: executedAt,
                  forVotes: parsedActionData.forVotes,
                  abstainVotes: parsedActionData.abstainVotes,
                  cancelled: parsedActionData.cancelled,
                  requested: parsedActionData.requested,
                  fulfilled: parsedActionData.fulfilled
              }
              // setAction(returnActionData)
              // console.log("@useAction: waypoint 6", {returnActionData})
              setData(returnActionData)
              setStatus("success")
              return returnActionData
            }
        } catch (error) {
          setError(error) 
        }
            
    }, [ ]
)

  return {status, error, data, fetchActionData}
}