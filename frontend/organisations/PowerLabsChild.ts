import { Organization, MandateInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi, safeL2Abi, safeProxyFactoryAbi } from "@/context/abi";  
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getMandateAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createMandateInitData, minutesToBlocks } from "./helpers";
import treasuryPools from "@/context/builds/TreasuryPools.json";
import { getConstants } from "@/context/constants";
import { sepolia, arbitrumSepolia, optimismSepolia, mantleSepoliaTestnet, foundry } from "@wagmi/core/chains";

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
 * Power Base Child Organization
 *
 * A basic child structure for an organisation. Configured to work with Power Labs as parent and to be controled by a specific role. 
 * 
 * It is meant to be updated by adopting a reform mandate. 
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const PowerLabsChild: Organization = {
  metadata: {
    id: "powers-Child",
    title: "Powers Labs Child",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "This is a base implementation of a Power Labs child organisation. It is meant to be configured through a reform mandate.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ 
    { name: "RoleId", placeholder: "The roleId that controls this child organisation.", type: "address", required: true },
    { name: "SafeProxyTreasury", placeholder: "The address of the central SafeProxy Treasury.", type: "address", required: true },
    { name: "PowersParent", placeholder: "The address of the parent Powers organization.", type: "address", required: true },
    { name: "AdoptChildMandateId", placeholder: "Mandate id at the parent Powers that approves adoption of mandates at a child organisation.", type: "number", required: true },
  ],
  dependencies:  [ ],
  allowedChains: [
    sepolia.id, 
  ],
  allowedChainsLocally: [
    sepolia.id,  
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
    let mandateCount = 0n;

    //////////////////////////////////////////////////////////////////
    //                          INIT LAW                            //
    ////////////////////////////////////////////////////////////////// 
    mandateCount++;
    mandateInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Members, Delegates) and revoke itself after execution",
      targetMandate: getMandateAddress("PresetSingleAction", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [
            powersAddress, 
            powersAddress,  
            powersAddress,
            powersAddress, 
            powersAddress,  
            powersAddress
          ],
          [0n, 0n, 0n, 0n, 0n, 0n],
          [
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",
              args: [1n, "Funders"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [2n, "Doc Contributors"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [3n, "Frontend Contributors"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [4n, "Protocol Contributors"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [5n, "Members"]
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

    //////////////////////////////////////////////////////////////////
    //                      EXECUTIVE LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    // a simple vote to transfer funds from the safe
    mandateCount++; 
    mandateInitData.push({
      nameDescription: "Execute Allowance Transaction: Execute a transaction from the Safe Treasury within the allowance set.",
      targetMandate: getMandateAddress("SafeAllowanceTransfer", deployedMandates), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address allowanceModule, address safeProxy'),
        [
          getConstants(chainId).SAFE_ALLOWANCE_MODULE as `0x${string}`, 
          formData["SafeProxyTreasury"]
        ]   
      ),  
      conditions: createConditions({
        allowedRole: BigInt(formData["RoleId"]),
        votingPeriod: minutesToBlocks(5, chainId), 
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        timelock: minutesToBlocks(3, chainId)
      })
    });

    // The Admin can update the URI.   
    mandateCount++;
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
    //                      ELECTORAL LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    //  Adopt Role
    mandateCount++;
    mandateInitData.push({
      nameDescription: `Adopt Role ${formData["RoleId"]}: Anyone that has role ${formData["RoleId"]} at the parent organization can adopt the same role here.`,
      targetMandate: getMandateAddress("AssignExternalRole", deployedMandates), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint256 roleId'),
        [formData["PowersParent"], BigInt(formData["RoleId"]),]   
      ),  
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
  
    //////////////////////////////////////////////////////////////////
    //                 CONSTITUTIONAL LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    // Adopt mandate flow.    
    mandateCount++;
    mandateInitData.push({
      nameDescription: "Check Parent: Check if adopt new mandates has been passed at the parent organization",
      targetMandate: getMandateAddress("CheckExternalActionState", deployedMandates), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint16 mandateId, string[] inputParams'),
        [formData["PowersParent"], formData["AdoptChildMandateId"], ["address[] Mandates", "uint256[] roleIds"]]
      ), 
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
    const checkParent = mandateCount;

    mandateCount++;
    mandateInitData.push({
      nameDescription: "Adopt Mandates: Anyone can adopt new mandates ok-ed by the parent organization",
      targetMandate: getMandateAddress("AdoptMandates", deployedMandates), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint16 mandateId, string[] inputParams'),
        [formData["PowersParent"], formData["AdoptChildMandateId"], ["address[] Mandates", "uint256[] roleIds"]]
      ), 
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE, 
        needFulfilled: checkParent
      })
    });
    
    
    // revoke mandate. 
    mandateCount++;
    mandateInitData.push({
      nameDescription: "Revoke Mandates: Admin can revoke mandates from the organization",
      targetMandate: getMandateAddress("RevokeMandates", deployedMandates), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: BigInt(formData["RoleId"]),
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        timelock: minutesToBlocks(3, chainId)
      })
    });
 
    return mandateInitData;
  }
};
