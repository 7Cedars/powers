import { Organization, MandateInitData } from "./types";
import { powersAbi } from "@/context/abi";  
import { encodeAbiParameters, encodeFunctionData, parseAbiParameters, toFunctionSelector } from "viem";
import { getMandateAddress, ADMIN_ROLE, PUBLIC_ROLE, createConditions, minutesToBlocks } from "./helpers";
import { sepolia, arbitrumSepolia, optimismSepolia, foundry } from "@wagmi/core/chains";

/**
 * Helper function to extract contract address from receipt
 */
function getContractAddressFromReceipt(receipt: any, contractName: string): `0x${string}` {
  if (!receipt || !receipt.contractAddress) {
    throw new Error(`Failed to get contract address for ${contractName} from receipt.`);
  }
  return receipt.contractAddress;
}

/**
 * Helper function to extract return value from function call receipt
 */
function getReturnValueFromReceipt(receipt: any): any {
  // This would need to be implemented based on the specific function call 
  // For now, return the receipt itself - the organization can extract what it needs
  return receipt;
}

/**
 * Nested Governance Organization
 *
 * Implements a simple nested governance structure.
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const NestedGovernanceParent: Organization = {
  metadata: {
    id: "nested-governance-parent",
    title: "Nested Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreian4g4wbuollclyml5xyao3hvnbxxduuoyjdiucdmau3t62rj46am",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeihnlv5j7z5c2kx3afitiijlwg7u65snepooxtczt4biwr7t5gltoi",
    description: "Nested Governance demonstrates how the Powers protocol can be used to layer governance within each other to create complex decision-making hierarchies. This example is a single parent organisation that governs a child, but any type of complex structure can be created. The notion of sub-DAOs is similar to nested governance.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ ],
  dependencies:  [ ],
  exampleDeployment: {
    chainId: optimismSepolia.id,
    address: '0x3F8a05F88e7074253a270aA03a0D90155150514C' 
  },
  allowedChains: [
    sepolia.id,
    optimismSepolia.id, 
  ],
  allowedChainsLocally: [
    sepolia.id, 
    optimismSepolia.id, 
    foundry.id
  ],
 
  createMandateInitData: (
    powersAddress: `0x${string}`,
    formData: Record<string, any>,
    deployedMandates: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ): MandateInitData[] => {
    const mandateInitData: MandateInitData[] = [];
    let mandateCounter = 0; 
    
    //////////////////////////////////////////////////////////////////
    //                    SETUP & ROLE LABELS                       //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Members), set treasury address and revokes itself after execution",
      targetMandate: getMandateAddress("PresetSingleAction", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [ powersAddress, powersAddress,  powersAddress ],
          [0n, 0n, 0n],
          [
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",
              args: [1n, "Members"]
            }),
            // setting treasury to self for demo purposes
            encodeFunctionData({
              abi: powersAbi,
              functionName: "setTreasury",
              args: [powersAddress]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "revokeMandate",
              args: [1n]
            })
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

    // The Admin can update the URI.   
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Update URI: The admin can update the organization's URI.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: encodeAbiParameters(
        parseAbiParameters('address powers, bytes4 FunctionSelector, string[] Params'),
        [
          powersAddress,
          toFunctionSelector("setUri(string)"),
          ["string Uri"]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    }); 
        
    //////////////////////////////////////////////////////////////////
    //           EXECUTIVE LAWS: NESTED (PARENT)                    //
    //////////////////////////////////////////////////////////////////
    // Allow Child contract to mint tokens 
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Allow Child to mint vote tokens: The parent organisation allows the child organisation to mint vote tokens.",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: 
        encodeAbiParameters(
          parseAbiParameters('string[] Params'),
          [ ["uint256 Quantity"] ]
        ),
      conditions: createConditions({
        allowedRole: 1n, // Members
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 51n,
        quorum: 33n 
      })
    }); 
    
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    ///////////////////////////////////////////////////////////////// 
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Admin can assign any role: For this demo, the admin can assign any role to an account.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: encodeAbiParameters(
      parseAbiParameters('address powers, bytes4 FunctionSelector, string[] Params'),
        [
          powersAddress,
          toFunctionSelector("assignRole(uint256,address)"),
          ["uint256 roleId","address account"]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
    const assignAnyRole = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "A delegate can revoke a role: For this demo, any delegate can revoke previously assigned roles.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: encodeAbiParameters(
      parseAbiParameters('address powers, bytes4 FunctionSelector, string[] Params'),
        [
          powersAddress,
          toFunctionSelector("revokeRole(uint256,address)"),
          ["uint256 roleId","address account"]
        ]
      ),
      conditions: createConditions({
        allowedRole: 2n,
        needFulfilled: assignAnyRole
      })
    });  

    return mandateInitData;
  }
};
