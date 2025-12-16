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
    title: "Nested Governance Parent",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "This is an example implementation of Bicameral Governance using Powers. It is intentionally simple to highlight bicameral decision-making processes.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ ],
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
      nameDescription: "Allow Child to use token faucet: The parent organisation allows the child organisation to mint tokens to its own address.",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: "0x" as `0x${string}`,
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
    const assignRevokeRoleConfig = encodeAbiParameters(
      parseAbiParameters('address powers, bytes4 FunctionSelector, string[] Params'),
      [
        powersAddress,
        toFunctionSelector("assignRoles(address[],uint256[])"),
        ["address account", "uint256 roleId"]
      ]
    );

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Admin can assign any role: For this demo, the admin can assign any role to an account.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: assignRevokeRoleConfig,
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
    const assignAnyRole = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "The admin can revoke roles: For this demo, the admin can revoke previously assigned roles.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config:assignRevokeRoleConfig,
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE,
        needFulfilled: assignAnyRole
      })
    });  

    return mandateInitData;
  }
};
