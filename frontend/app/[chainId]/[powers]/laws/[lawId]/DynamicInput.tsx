"use client";

import { ChangeEvent, useEffect, useState } from "react";
import { parseInput } from "@/utils/parsers";
import { DataType, InputType } from "@/context/types";
import { 
 MinusIcon,
 PlusIcon
} from '@heroicons/react/24/outline';
import { setAction, useActionStore } from "@/context/store";
import { setError, useErrorStore } from "@/context/store";

type InputProps = {
  dataType: DataType;
  varName: string;
  values: InputType | InputType[]
  onChange: (input: InputType | InputType[]) => void;
}

export function DynamicInput({dataType, varName, values, onChange}: InputProps) {
  const [inputArray, setInputArray] = useState<InputType[]>(values instanceof Array ? values : [values])
  const [itemsArray, setItemsArray] = useState<number[]>([0])
  const action = useActionStore()
  const error = useErrorStore()

  console.log("@dynamicInput: ", {error, inputArray, dataType, varName, values})

  const inputType = 
    dataType.indexOf('int') > -1 ? "number"
    : dataType.indexOf('bool') > -1 ? "boolean"
    : dataType.indexOf('string') > -1 ? "string"
    : dataType.indexOf('address') > -1 ? "string"
    : dataType.indexOf('bytes') > -1 ? "string"
    : dataType.indexOf('empty') > -1 ? "empty"
    : "unsupported"
  
  const array = 
    dataType.indexOf('[]') > -1 ? true : false

  const handleChange=({event, item}: {event:ChangeEvent<HTMLInputElement>, item: number}) => {
    // console.log("handleChange triggered", event.target.value, item)
    // try {
    const currentInput = parseInput(event, dataType)
    if (currentInput == 'Incorrect input data') {
      setError({error: currentInput}) 
    } else if(typeof onChange === 'function'){
      let currentArray = inputArray
      if (array) {  
        currentArray[item] = currentInput
        setInputArray(currentArray)
        onChange(inputArray)
      } else {
        currentArray[0] =  currentInput
        setInputArray(currentArray)
        onChange(inputArray[0])
        }
        setAction({...action, upToDate: false})   
      }    
      // } catch(error) {
      //   setError({error: error as Error})
      // }
  }

  const handleResizeArray = (event: React.MouseEvent<HTMLButtonElement>, expand: boolean, index?: number) => {
    event.preventDefault() 

    if (expand) {
      const newItemsArray = [...Array(itemsArray.length + 1).keys()]
      let newInputArray = new Array<InputType>(newItemsArray.length) 
      // currentInput = [...inputArray] 
      // currentInput.push() // lets see if this works.. 
      setItemsArray(newItemsArray) 
      setInputArray(newInputArray)
    } else {
      const newItemsArray = [...Array(itemsArray.length - 1).keys()]
      const newInputArray = inputArray.slice(0, index)
      setItemsArray(newItemsArray) 
      setInputArray(newInputArray)
    }
  }

  useEffect(() => {
    if (values && values instanceof Array ) {
      setInputArray(values)
    } else {
      setInputArray([values])
    } 
  }, [values])

  return (
    <div className="w-full flex flex-col justify-center items-center">
      {itemsArray.map((item, i) =>  
          <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6" key = {i}>
            <div className="text-sm block min-w-20 font-medium text-slate-600">
              {varName}
            </div>

            {
            inputType  == "string" ? 
                <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
                  <input 
                    type= "text" 
                    name={`input${item}`} 
                    id={`input${item}`}
                    value = {typeof inputArray[item] != "boolean" && inputArray[item] ? inputArray[item] : ""}
                    className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                    placeholder={`Enter ${dataType.replace(/[\[\]']+/g, '')} here.`}
                    onChange={(event) => handleChange({event, item})}
                    />
                </div>
            : 
            inputType == "number" ? 
              <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
                <input 
                  type="number" 
                  name={`input${item}`} 
                  id={`input${item}`}
                  value = {String(inputArray[item])}
                  className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                  placeholder={`Enter ${dataType.replace(/[\[\]']+/g, '')} value here.`}
                  onChange={(event) => handleChange({event, item})}
                  />
              </div>  
            :
            inputType == "boolean" ? 
                <div className = {"w-full h-8 ps-4 flex flex-row gap-4  items-center rounded-md bg-white outline outline-1 outline-gray-300" }>
                {/* radio button true  */}
                  <div className = {"flex flex-row gap-1 "}>
                    <label 
                      htmlFor={`input${item}true`} 
                      className="block text-sm/6 font-medium text-slate-600 pe-2">
                        {`true`}
                    </label>
                      <input 
                        type="radio" 
                        name={`input${item}`} 
                        id={`input${item}true`} 
                        value={'true'} 
                        checked = {inputArray[item] == true}
                        className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                        onChange={(event) => handleChange({event, item})}
                      />
                  </div>
                  {/* radio button false  */}
                  <div className = {"flex flex-row gap-1"}>
                    <label 
                      htmlFor={`input${item}false`} 
                      className="block text-sm/6 font-medium text-slate-600 pe-2">
                        {`false`}
                    </label>
                      <input 
                        type="radio" 
                        name={`input${item}`} 
                        id={`input${item}false`} 
                        value={'false'} 
                        checked = {inputArray[item] == false}
                        className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                        onChange={(event) => handleChange({event, item})}
                      />
                  </div>
                </div>
            :
            <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300 text-sm text-red-400 py-1">  
              error: data not recognised.
            </div>  
            }
            {
              array && item == itemsArray.length - 1 ?
                <div className = "flex flex-row gap-2">
                  <button 
                    className = "h-8 w-8 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
                    onClick = {(event) => handleResizeArray(event, true)}
                    > 
                    <PlusIcon className = "h-4 w-4"/> 
                  </button>
                  {
                  item > 0 ? 
                    <button className = "h-8 w-8 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
                    onClick = {(event) => handleResizeArray(event, false, item)}
                    > 
                      <MinusIcon className = "h-4 w-4"/> 
                    </button>
                  : null 
                  }
                </div>
              :
              null
            } 

          </section>

      )
      }
    </div>
  )
}
