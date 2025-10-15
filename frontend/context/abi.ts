import { Abi } from "viem"

import powers from "../../solidity/out/Powers.sol/Powers.json"
import law from "../../solidity/out/Law.sol/Law.json"
import erc20 from "../../solidity/out/ERC20.sol/ERC20.json"
import erc721 from "../../solidity/out/ERC721.sol/ERC721.json"
import erc1155 from "../../solidity/out/ERC1155.sol/ERC1155.json"
import ownable from "../../solidity/out/Ownable.sol/Ownable.json"

export const powersAbi: Abi = JSON.parse(JSON.stringify(powers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 
export const erc20Abi: Abi = JSON.parse(JSON.stringify(erc20.abi)) 
export const erc721Abi: Abi = JSON.parse(JSON.stringify(erc721.abi)) 
export const erc1155Abi: Abi = JSON.parse(JSON.stringify(erc1155.abi)) 
export const ownableAbi: Abi = JSON.parse(JSON.stringify(ownable.abi)) 