import { useCallback } from "react"
import { encodeAbiParameters, keccak256 } from "viem"

// * Hashes an action using the same algorithm as in the Solidity contract
//    * Replicates: uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)));
//    * Create by AI - let's see if it works.. 
//    */
export const hashAction = (lawId: bigint, lawCalldata: `0x${string}`, nonce: bigint): bigint => {
    // Encode the parameters in the same order as abi.encode in Solidity
    const encoded = encodeAbiParameters(
      [
        { name: 'lawId', type: 'uint16' },
        { name: 'lawCalldata', type: 'bytes' },
        { name: 'nonce', type: 'uint256' }
      ],
      [Number(lawId), lawCalldata, nonce]
    );
    
    // Hash the encoded data
    const hash = keccak256(encoded);
    
    // Convert the hash to a bigint (equivalent to uint256 in Solidity)
    return BigInt(hash);
  }