"use client"

import { TwoSeventyRingWithBg } from "react-svg-spinners";

type ButtonProps = {
  statusButton?: 'pending' | 'success' | 'error' | 'disabled' | 'idle';
  showBorder?: boolean;
  selected?: boolean;
  size?: 0 | 1 | 2;   
  align?: 0 | 1 | 2;   
  role?: number; 
  filled?: boolean;
  children: any;
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
};

const fontSize = [
  "text-sm py-1",
  "text-md p-1 h-10", 
  "text-lg p-3 h-16", 
]

const fontAlign = [
  "justify-left text-left",
  "justify-center text-center", 
  "justify-right text-right", 
]

const roleBorderColour = [
  "bg-blue-200 border-blue-600",
  "bg-red-200 border-red-600",
  "bg-yellow-200 border-yellow-600",
  "bg-purple-200 border-purple-600",
  "bg-green-200 border-green-600",
  "bg-orange-200 border-orange-600",
  "bg-slate-200 border-slate-600"
]

export const Button = ({
  statusButton = 'idle', 
  showBorder = true,
  filled = true, 
  selected = false, 
  size = 1, 
  align = 1,
  role = 6,  
  onClick,
  children,
}: ButtonProps) => {

  return (
    <button 
      className={`w-full h-full aria-selected:bg-opacity-0 disabled:opacity-50 rounded-md border ${roleBorderColour[role % roleBorderColour.length]} ${fontSize[size]} ${showBorder ? "": "md:border-transparent"} ${filled ? "": "bg-opacity-0"}`}  
      onClick={onClick} 
      aria-selected={!selected}
      disabled = {statusButton == "disabled"}
      >
        <div className={`flex flex-row items-center ${fontAlign[align]} text-slate-700 gap-1 w-full h-full px-2 py-1`}>
        {
          statusButton == 'pending' ?  
          <>
          <div> 
            <TwoSeventyRingWithBg />
            </div>
            <div>
              Loading...
              </div>
            </>
          : 
          statusButton == 'success' ? 
            <>
            Success! 
            </>
          :
          statusButton == 'error' ? 
            <>
            Error 
            </>
          :
          <>
            {children}
          </>
        }
      </div>
    </button>
  );
};
