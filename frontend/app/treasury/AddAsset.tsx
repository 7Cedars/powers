// £todo 
// needs to take in: address + type of token (simple drop down menu).

import { Button } from "@/components/Button"; 
import { useAssets } from "@/hooks/useAssets";
import { useState } from "react";
import { TwoSeventyRingWithBg } from "react-svg-spinners";

export function AddAsset() {
  const [newToken, setNewToken] = useState<`0x${string}`>()
  const {status, error, tokens, native, initialise, update, fetchTokens} = useAssets()


  return (
    <div className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-200 rounded-md overflow-hidden opacity-0 md:opacity-100 md:disabled">
      <div className="w-full flex flex-row gap-3 min-w-6xl justify-between items-center py-4 px-5 overflow-x-scroll overflow-y-hidden">
        <div className="text-slate-900 text-center font-bold text-md min-w-24">
          Add Token
        </div>
        {/* address input */}
        <div className="grow min-w-28 flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
          <input 
            type= "text" 
            name={`input`} 
            id={`input`}
            className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm" 
            placeholder={`Enter token address here.`}
            onChange={(event) => {setNewToken(event.target.value as `0x${string}`)}}
            />
        </div>

        {/* button: add */}
        <div className="h-8 flex flex-row w-40 min-w-24 text-center">
          <Button 
            size = {0} 
            role = {6}
            selected = {true}
            filled = {false} 
            onClick={() => {update(newToken ? newToken : `0x0`)}}
            > 
            <div className = "text-slate-600">{
              status && status == 'pending' ? <TwoSeventyRingWithBg /> : "Add ERC-20 Token"  
            }
            </div>    
          </Button>
        </div>
      </div>
      <div className = "text-sm">
        { status && status == 'error' ? 
            <div className = "text-red-500 pb-4">
              {typeof error == "string" ?  error.slice(0, 30) : "Token not recognised"}
            </div> 
          :
          status && status == 'success' ? 
            <div className = "text-green-500  pb-4"> 
              Token added. Please refresh. 
            </div> 
          :
          null 
        }
      </div>
    </div>
  ) 

} 