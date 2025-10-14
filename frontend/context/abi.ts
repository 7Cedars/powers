import { Abi } from "viem"

import powers from "../../solidity/out/Powers.sol/Powers.json"
import law from "../../solidity/out/Law.sol/Law.json"

export const powersAbi: Abi = JSON.parse(JSON.stringify(powers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 
