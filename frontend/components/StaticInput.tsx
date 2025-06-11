"use client";

import { DataType, InputType } from "@/context/types";

type InputProps = {
  dataType: DataType;
  varName: string;
  values: InputType | InputType[]  
}

export function StaticInput({dataType, varName, values}: InputProps) {
  const array = 
    dataType.indexOf('[]') > -1 ? true : false
  const itemsArray = array ? values as Array<InputType> : [values] as Array<InputType>

  // console.log("@itemsArray: ", {itemsArray} )

  return (
    <div className="w-full flex flex-col justify-center items-center">
      {itemsArray.map((item, i) =>  
          <section className="w-full mt-4 flex flex-row justify-center items-center ps-3 pe-6 gap-3" key={i}>
            <div className="text-xs text-slate-600 ps-3 min-w-20">
              {varName}
            </div>

            {
              <>
                <div className="w-full h-fit flex items-center text-md justify-center rounded-md bg-white ps-2 outline outline-1 outline-slate-300">  
                  <input 
                    type={"string"}
                    name={`input${item}`} 
                    id={`input${item}`}
                    className="w-full h-8 pe-2 text-xs font-mono text-slate-500 placeholder:text-gray-400 focus:outline focus:outline-0" 
                    value={item == false ? dataType == "bool" ? "false" : "0" : String(item)}
                    disabled={true}
                    />
                </div>
              </>
            }
          </section>
        )
      }
    </div>
  )
}
