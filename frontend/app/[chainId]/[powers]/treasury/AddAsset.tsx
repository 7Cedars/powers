// £todo 
// needs to take in: address + type of token (simple drop down menu).

import { Button } from "@/components/Button"; 
import { Powers } from "@/context/types";
import { useAssets } from "@/hooks/useAssets";
import { useState } from "react";
import { TwoSeventyRingWithBg } from "react-svg-spinners";
import { ArrowPathIcon } from "@heroicons/react/24/outline";

export function AddAsset({powers, onRefresh}: {powers: Powers | undefined, onRefresh?: () => void}) {
  const [newToken, setNewToken] = useState<`0x${string}`>()
  const {status, error, tokens, native, addErc20, resetErc20s, fetchTokens} = useAssets(powers as Powers)

  const handleRefreshAssets = () => {
    if (powers) {
      fetchTokens(powers)
    }
  }

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border border-slate-300 rounded-md overflow-hidden">
      {/* Header - matching LogsList.tsx structure */}
      <div className="w-full flex flex-row gap-4 justify-between items-center pt-3 px-4 pb-3">
        <div className="text-slate-800 text-center text-lg">
          Add Token
        </div>
        {onRefresh && (
          <div className="w-8 h-8">
            <Button
              size={0}
              showBorder={true}
              onClick={onRefresh}
            >
              <ArrowPathIcon className="w-5 h-5" />
            </Button>
          </div>
        )}
      </div>

      {/* Content Section - Input Form */}
      <div className="w-full flex flex-col gap-4 px-4 pb-4">
        {/* Input and Button Row */}
        <div className="w-full flex flex-row gap-3 items-center">
          {/* Address input */}
          <div className="flex-1 min-w-0 flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
            <input 
              type="text" 
              name="input" 
              id="input"
              className="w-full h-8 pe-2 text-xs text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0" 
              placeholder="Enter token address here."
              onChange={(event) => {setNewToken(event.target.value as `0x${string}`)}}
            />
          </div>

          {/* Add Button */}
          <div className="w-32 h-8">
            <Button 
              size={0} 
              role={6}
              selected={true}
              filled={false} 
              showBorder={true}
              onClick={() => {addErc20(newToken ? newToken : `0x0`)}}
            > 
              <div className="text-xs px-1">
                {status && status == 'pending' ? (
                  <TwoSeventyRingWithBg className="w-4 h-4" />
                ) : (
                  "Add Token"
                )}
              </div>    
            </Button>
          </div>
        </div>

        {/* Status Messages */}
        {(status === 'error' || status === 'success') && (
          <div className="w-full flex justify-center">
            <div className="text-xs text-center">
              {status === 'error' ? (
                <div className="text-red-500">
                  {typeof error === "string" ? error.slice(0, 50) : "Token not recognised"}
                </div> 
              ) : status === 'success' ? (
                <div className="text-green-500"> 
                  Token added. Please refresh to see it in the list.
                </div> 
              ) : null}
            </div>
          </div>
        )}
      </div>
    </div>
  ) 
} 