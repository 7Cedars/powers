import { supportedChains } from "@/context/chains";
import { ChainProps, Law, Organisation } from "@/context/types";
import { useChainId } from "wagmi";

const nameMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

export const toShortDateFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  const shortYear = date.getFullYear().toString() // .slice(2,4) 

  return `${nameMonths[date.getMonth()]} ${shortYear}`
}; 

export const toFullDateFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  return `${date.getDate()} ${nameMonths[date.getMonth()]} ${date.getFullYear()}`
}; 

export const toEurTimeFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  let minutes = date.getMinutes().toString()
  minutes.length == 1 ? minutes = `0${minutes}` : minutes
  return `${date.getHours()}:${minutes}`
}; 

export const toTimestamp = (dateFormat: string): string => { 
  return String(Date.parse(dateFormat))
};

export const blocksToHoursAndMinutes = (blocks: number, supportedChain: ChainProps | undefined): string | undefined => { 
  const blockTime = supportedChain?.blockTimeInSeconds ? supportedChain?.blockTimeInSeconds : 0
  const minutes = (blocks * blockTime) / 60 

  const response = minutes < 60 ? ` ${Math.floor(minutes % 60)} minutes.` 
  : 
  ` ${Math.floor(minutes / 60)} hours and ${Math.floor(minutes % 60)} minutes.`

  return response 
};
