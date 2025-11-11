import { Abi } from "viem"

import powers from "./builds/Powers.json"
import law from "./builds/Law.json"
import erc20 from "./builds/ERC20.json"
import ownable from "./builds/Ownable.json"

export const powersAbi: Abi = JSON.parse(JSON.stringify(powers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 
export const erc20Abi: Abi = JSON.parse(JSON.stringify(erc20.abi)) 
export const ownableAbi: Abi = JSON.parse(JSON.stringify(ownable.abi)) 