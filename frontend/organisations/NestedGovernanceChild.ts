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
export const NestedGovernanceChild: Organization = {
  metadata: {
    id: "nested-governance-child",
    title: "Nested Governance Child",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreig4aaje57wiv3rfboadft5pp2kgwzfurwgbjwleugc3ddbnjlc6um",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeifn5tpugbezqlsjlueszegzs6tbe22of5mqb4qqio5lmnvklu7dsm",
    description: "Nested Governance demonstrates how the Powers protocol can be used to layer governance within each other to create complex decision-making hierarchies. This example is a single child organisation that is governed by a parent, but any type of complex structure can be created. The notion of sub-DAOs is similar to nested governance.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ 
    { name: "PowersParent", placeholder: "The address of the parent Powers organization.", type: "address", required: true },
    { name: "MintMandateId", placeholder: "Mandate id at the parent Powers that approves minting of tokens.", type: "number", required: true },
  ],
  dependencies:  [ ],
  allowedChains: [
    sepolia.id,
    arbitrumSepolia.id,
    optimismSepolia.id, 
  ],
  allowedChainsLocally: [
    sepolia.id, 
    arbitrumSepolia.id,
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
          [ powersAddress, powersAddress ],
          [0n, 0n],
          [
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",
              args: [1n, "Members"]
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
    // Allow Child contract to mint tokens. Step 1: Check Parent mandate
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Check Parent: Check if parent has passed action to mint tokens.",
      targetMandate: getMandateAddress("CheckExternalActionState", deployedMandates), // Ensure this name matches build
      config: "0x" as `0x${string}`,
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
    const checkParent = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Mint Tokens: The parent organisation allows the child organisation to mint tokens to its own address.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: "0x" as `0x${string}`,
      conditions: createConditions({
        allowedRole: 1n, // Members
        needFulfilled: checkParent, 
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 51n,
        quorum: 33n 
      })
    }); 
    
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    ///////////////////////////////////////////////////////////////// 
    //  Adopt Role
    mandateCounter++;
    mandateInitData.push({
      nameDescription: `Sync Member status: An account that has role Member at the parent organization can be assigned the same role here - and visa versa.`,
      targetMandate: getMandateAddress("AssignExternalRole", deployedMandates), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint256 roleId'),
        [formData["PowersParent"], 1n] // Members role
      ),  
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });

    return mandateInitData;
  }
};
