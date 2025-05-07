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
          <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6" key={i}>
            <div className="text-sm/6 block min-w-16 font-medium text-slate-600">
              {varName}
            </div>

            {
              <>
                <div className="w-full flex items-center rounded-md outline outline-1 outline-gray-300">  
                  <input 
                    type={"string"}
                    name={`input${item}`} 
                    id={`input${item}`}
                    className="w-full h-8 pe-2 pl-3 text-slate-600 placeholder:text-gray-400 bg-slate-100 focus:outline focus:outline-0 sm:text-sm" 
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
