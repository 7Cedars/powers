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
export const PowerBaseFrontend: Organization = {
  metadata: {
    id: "vanilla-powers",
    title: "Vanilla Powers",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "This implementation has two laws: one to adopt laws and one to revoke. It allows to setup any type of organisation after initialisation.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ ],
  dependencies:  [ ],
  allowedChains: [
    arbitrumSepolia.id,
    optimismSepolia.id,
  ],
  allowedChainsLocally: [
    arbitrumSepolia.id,
    optimismSepolia.id,
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
    //                 CONSTITUTIONAL LAWS                          //
    //////////////////////////////////////////////////////////////////
    //  Adopt Law
    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Laws: Admin adopts new laws into the organization",
      targetLaw: getLawAddress("AdoptLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE 
      })
    });
 
    // Law 27: Revoke Laws
    lawCount++;
    lawInitData.push({
      nameDescription: "Revoke Laws: Admin revokes laws from the organization",
      targetLaw: getLawAddress("RevokeLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
 
    return lawInitData;
  }
};
