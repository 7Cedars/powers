import { Organization, MandateInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi, safeL2Abi, safeProxyFactoryAbi } from "@/context/abi";  
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getMandateAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createMandateInitData, minutesToBlocks } from "./helpers";
import nominees from "@/context/builds/Nominees.json";
import openElection from "@/context/builds/OpenElection.json";
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
 * Open Elections
 *
 * Implements a simple open elections governance structure.
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const OffChainGovernance: Organization = {
  metadata: {
    id: "off-chain-governance",
    title: "Off-Chain Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiaaprfqxtgyxa5v2dnf7edfbc3mxewdh4axf4qtkurpz66jh2f2ve",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideyeixpz7bkqxpasrlhu7ia3plir6z5b2vh3d7w26e5is27nqyfu",
    description: "Off-Chain Governance demonstrates how to integrate off-chain oracles into a governance flow. In this examples roles are assigned based on commits to a github repository, verified through a Chainlink functions oracle.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ ],
  dependencies:  [ 
    // Governor contract - that is the only dependency for this organisation I think. 
  ],
//   exampleDeployment: {
//     chainId: sepolia.id,
//     address: `0x0000000000000000000000000000000000000000`
//   },
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
    // console.log("deployedMandates @ PowerLabs", deployedMandates);
    // console.log("chainId @ createMandateInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
 

    //////////////////////////////////////////////////////////////////
    //                       OPEN ELECTIONS LAWS                    //
    //////////////////////////////////////////////////////////////////
 

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
