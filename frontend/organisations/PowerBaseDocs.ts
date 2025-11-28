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
 * Power Base Organization
 *
 * Manages Powers protocol development funding via Safe Smart Accounts.
 * Governance based on GitHub contributions verified by commit signatures.
 *
 * Key Features:
 * - Three independent funding pools (Docs, Frontend, Protocol) using a bespoke Treasury contract. 
 * - Ability to create new funding pools via governance. 
 * - Contributor roles assigned via RoleByGitSignature.sol (Chainlink Functions)
 * - Funder participation through token purchases
 * - Constitutional amendment process
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const PowerBaseDocs: Organization = {
  metadata: {
    id: "powers-Docs",
    title: "Documentation Powers",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "This implementation has two laws: one to adopt laws and one to revoke. It allows to setup any type of organisation after initialisation.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ 
    { name: "SafeAddress", placeholder: "The address of the Safe treasury.", type: "address", required: true },
    { name: "PowersParent", placeholder: "The address of the parent Powers organization.", type: "address", required: true },
    { name: "AdoptChildLawId", placeholder: "The adopt child law Id at the parent organization.", type: "number", required: true },
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
    lawInitData.push({
      nameDescription: "Execute transaction from allowance: This is still a work in progress.",
      targetLaw: getLawAddress("SafeExecTransaction", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint256 roleId'),
        [formData["PowersParent"], 3n]  // Role ID 3 = Doc Contributor
      ),  
      conditions: createConditions({
        allowedRole: 3n,
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        delayExecution: minutesToBlocks(3, chainId)
      })
    });

        //     conditions.allowedRole = 4; // = protocol contributors.
        // conditions.needFulfilled = lawCount - 1; // = the proposal law. 
        // lawInitData[11] = PowersTypes.LawInitData({
        //     nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
        //     targetLaw: lawAddresses[1], // safeExecTransaction
        //     config: abi.encode(
        //         inputParams,
        //         bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
        //         safeAddress
        //     ),
        //     conditions: conditions // everythign zero == Only admin can call directly 
        // });
        // delete conditions;
        // executeAllowanceTransfer (0x4515641a)


    //////////////////////////////////////////////////////////////////
    //                      ELECTORAL LAWS                          //
    ////////////////////////////////////////////////////////////////// 
    //  Adopt Role
    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Doc Contrib Role: Anyone that has a documentation contributor role at the parent organization can adopt the same role here.",
      targetLaw: getLawAddress("AssignExternalRole", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('address powersAddress, uint256 roleId'),
        [formData["PowersParent"], 3n]  // Role ID 3 = Doc Contributor
      ),  
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
  
    //////////////////////////////////////////////////////////////////
    //                 CONSTITUTIONAL LAWS                          //
    //////////////////////////////////////////////////////////////////    
    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Laws: Anyone can adopt new laws ok-ed by the parent organization",
      targetLaw: getLawAddress("CheckExternalActionState", deployedLaws), // Ensure this name matches build
      config: encodeAbiParameters(
        parseAbiParameters('uint16 lawId, address powersAddress, string[] inputParams'),
        [formData["AdoptChildLawId"], formData["PowersParent"], ["uint256 PoolId", "address payableTo", "uint256 Amount"]]
      ), 
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE 
      })
    });
    
    // Law 27: Revoke Laws
    lawCount++;
    lawInitData.push({
      nameDescription: "Revoke Laws: Admin can revoke laws from the organization",
      targetLaw: getLawAddress("RevokeLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: 3n,
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 67n,
        quorum: 50n, // Note: high quorum
        delayExecution: minutesToBlocks(3, chainId)
      })
    });
 
    return lawInitData;
  }
};
