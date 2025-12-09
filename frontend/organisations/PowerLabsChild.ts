import { Organization, LawInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi, safeL2Abi, safeProxyFactoryAbi } from "@/context/abi";  
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getLawAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createLawInitData, minutesToBlocks } from "./helpers";
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
 * It is meant to be updated by adopting a reform law. 
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const PowerLabsChild: Organization = {
  metadata: {
    id: "powers-Child",
    title: "Child Powers",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "This is a base implementation of a Power Labs child organisation. It is meant to be configured through a reform law.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ 
    { name: "RoleId", placeholder: "The roleId that controls this child organisation.", type: "address", required: true },
    { name: "SafeProxyTreasury", placeholder: "The address of the central SafeProxy Treasury.", type: "address", required: true },
    { name: "PowersParent", placeholder: "The address of the parent Powers organization.", type: "address", required: true },
    { name: "AdoptChildLawId", placeholder: "Law id at the parent Powers that approves adoption of laws at a child organisation.", type: "number", required: true },
  ],
  dependencies:  [ ],
  allowedChains: [
    sepolia.id,
  ],
  allowedChainsLocally: [
    sepolia.id, 
    foundry.id
  ],
 
  createLawInitData: (
    powersAddress: `0x${string}`,
    formData: Record<string, any>,
    deployedLaws: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ): LawInitData[] => {
    const lawInitData: LawInitData[] = [];
    let lawCount = 0n;

    //////////////////////////////////////////////////////////////////
    //                      EXECUTIVE LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    // a simple vote to transfer funds from the safe
    lawCount++; 
    lawInitData.push({
      nameDescription: "Execute Allowance Transaction: Execute a transaction from the Safe Treasury within the allowance set.",
      targetLaw: getLawAddress("SafeAllowanceTransfer", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address allowanceModule, address safeProxy'),
        [
          getConstants(chainId).SAFE_ALLOWANCE_MODULE as `0x${string}`, 
          formData["SafeProxyTreasury"]
        ]   
      ),  
      conditions: createConditions({
        allowedRole: BigInt(formData["RoleId"]),
        votingPeriod: minutesToBlocks(10, chainId), 
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        delayExecution: minutesToBlocks(3, chainId)
      })
    });

    //////////////////////////////////////////////////////////////////
    //                      ELECTORAL LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    //  Adopt Role
    lawCount++;
    lawInitData.push({
      nameDescription: `Adopt Role ${formData["RoleId"]}: Anyone that has role ${formData["RoleId"]} at the parent organization can adopt the same role here.`,
      targetLaw: getLawAddress("AssignExternalRole", deployedLaws), // Ensure this name matches build
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
    // Adopt law flow.    
    lawCount++;
    lawInitData.push({
      nameDescription: "Check Parent: Check if adopt new laws has been passed at the parent organization",
      targetLaw: getLawAddress("CheckExternalActionState", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint16 lawId, string[] inputParams'),
        [formData["PowersParent"], formData["AdoptChildLawId"], ["address[] Laws", "uint256[] roleIds"]]
      ), 
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
    const checkParent = lawCount;

    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Laws: Anyone can adopt new laws ok-ed by the parent organization",
      targetLaw: getLawAddress("AdoptLaws", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint16 lawId, string[] inputParams'),
        [formData["PowersParent"], formData["AdoptChildLawId"], ["address[] Laws", "uint256[] roleIds"]]
      ), 
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE, 
        needFulfilled: checkParent
      })
    });
    
    
    // revoke law. 
    lawCount++;
    lawInitData.push({
      nameDescription: "Revoke Laws: Admin can revoke laws from the organization",
      targetLaw: getLawAddress("RevokeLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: BigInt(formData["RoleId"]),
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        delayExecution: minutesToBlocks(3, chainId)
      })
    });
 
    return lawInitData;
  }
};
