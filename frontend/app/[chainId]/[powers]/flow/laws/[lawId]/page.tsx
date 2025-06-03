"use client";

import React, { useEffect } from "react";
import { LawBox } from "@/app/[chainId]/[powers]/flow/laws/[lawId]/LawBox";
import { setAction, setError, useActionStore, useErrorStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useChecks } from "@/hooks/useChecks";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import { InputType, Law, Powers } from "@/context/types";
import { useWallets } from "@privy-io/react-auth";
import { usePowers } from "@/hooks/usePowers";
import { useParams } from "next/navigation";
import { LoadingBox } from "@/components/LoadingBox";

const Page = () => {
  const { wallets } = useWallets()
  const action = useActionStore()

  const { lawId } = useParams<{ 
    lawId: string 
  }>()  
  
  const { powers } = usePowers()
  const { status: statusLaw, error: errorUseLaw, executions, simulation, fetchExecutions, resetStatus, simulate, execute } = useLaw()
  const { checks, fetchChecks } = useChecks(powers as Powers)
  
  const law = powers?.laws?.find(law => law.index == BigInt(lawId))

  const handleSimulate = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues)
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }

    if (lawCalldata && wallets && powers?.contractAddress) { 
      setAction({
        lawId: law.index,
        caller: wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
        dataTypes: law.params?.map(param => param.dataType),
        paramValues: paramValues,
        nonce: nonce.toString(),
        uri: description,
        callData: lawCalldata,
        upToDate: true
      })

      fetchChecks(law, action.callData as `0x${string}`, BigInt(action.nonce), wallets, powers as Powers) 
      
      try {
        simulate(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0',
          action.callData as `0x${string}`,
          BigInt(action.nonce),
          law
        )
      } catch (error) {
        setError({error: error as Error})
      }
    }
  }

  const handleExecute = async (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => {
    setError({error: null})
    let lawCalldata: `0x${string}` | undefined
    
    if (paramValues.length > 0 && paramValues) {
      try {
        lawCalldata = encodeAbiParameters(parseAbiParameters(law.params?.map(param => param.dataType).toString() || ""), paramValues)
      } catch (error) {
        setError({error: error as Error})
      }
    } else {
      lawCalldata = '0x0'
    }

    execute(law, lawCalldata as `0x${string}`, nonce, description)
  }

  // Reset lawBox and fetch executions when switching laws
  useEffect(() => {
    if (law) {
      const dissimilarTypes = action.dataTypes ? action.dataTypes.map((type, index) => type != law.params?.[index]?.dataType) : [true] 
      
      if (dissimilarTypes.find(type => type == true)) {
        setAction({
          lawId: law.index,
          dataTypes: law.params?.map(param => param.dataType),
          paramValues: [],
          nonce: '0',
          callData: '0x0',
          upToDate: false
        })
      } else {
        setAction({
          ...action,  
          lawId: law.index,
          upToDate: false
        })
      }
      fetchExecutions(law)
      resetStatus()
    }
  }, [law])

  useEffect(() => {
    if (errorUseLaw) {
      setError({error: errorUseLaw})
    }
  }, [errorUseLaw])

  if (!powers || !law || !checks) {
    return (
      <div className="p-6">
        <LoadingBox />
      </div>
    )
  }

  return (
    <div className="h-full p-6">
      <LawBox 
        law={law}
        checks={checks}
        params={law.params || []}
        status={statusLaw || 'idle'}
        simulation={simulation}
        selectedExecution={undefined}
        onChange={() => {
          // Handle change if needed
        }}
        onSimulate={(paramValues, nonce, description) => 
          handleSimulate(law, paramValues, nonce, description)
        }
        onExecute={(paramValues, nonce, description) => 
          handleExecute(law, paramValues, nonce, description)
        }
      />
    </div>
  )
}

export default Page

