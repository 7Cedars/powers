import { Organization, MandateInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi, safeL2Abi, safeProxyFactoryAbi } from "@/context/abi";  
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getMandateAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createMandateInitData, minutesToBlocks } from "./helpers";
import nominees from "@/context/builds/Nominees.json";
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
 * Bicameral Governance Organization
 *
 * Implements a simple bicameral governance structure.
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const TokenDelegates: Organization = {
  metadata: {
    id: "token-delegates",
    title: "Token Delegates",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicpqpipzetgtcbqdeehcg33ibipvrb3pnikes6oqixa7ntzaniinm",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeidwk32aq52ap5fyrrojmtuhbehvwdv5emyld4nspznaepcxcqnbv4",
    description: "One-token-one-vote is the most popular approach to DAO governance today, despite its many shortcomings. This Token Delegate example demonstrates how the Powers protocol can be used to give power to accounts along the amount of  delegated tokens they hold. There is one key difference with traditional approaches: after delegates have been selected, they all hold the same amount of power (similar to democratic elections) while in classic DAO governance inequality in votes is reflected in delegates power.",
    disabled: false,
    onlyLocalhost: false
  },
  fields: [ ],
  dependencies:  [
    {
      name: "Nominees",
      abi: nominees.abi as Abi,
      bytecode: nominees.bytecode.object as `0x${string}`,
      args: [],
      ownable: true
    }
  ],
  exampleDeployment: {
    chainId: sepolia.id,
    address: `0x646Ec769f87D53B3251Ec00ae4f1C1AFF9E01137`
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
    // console.log("deployedMandates @ PowerLabs", deployedMandates);
    // console.log("chainId @ createMandateInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Delegates, Funders) and revokes itself after execution",
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
              args: [1n, "Voters"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [2n, "Delegates"]
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
    //                   TOKEN DELEGATE ELECTIONS                   //
    /////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Nominate for Delegates: Members can nominate themselves for the Token Delegate role.",
      targetMandate: getMandateAddress("Nominate", deployedMandates),
      config: encodeAbiParameters(
        parseAbiParameters("address Nominees"),
        [ getContractAddressFromReceipt(dependencyReceipts["Nominees"], "Nominees") ]
      ),
      conditions: createConditions({
        allowedRole: 1n, // Voters: only accounts with Voter role can nominate for delegate
      })
    });
    const nominateForDelegates = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: `Elect Delegates: Run the election for delegates. In this demo, the top 3 nominees by token delegation of token ${getConstants(chainId).VOTES_TOKEN} become Delegates.`,
      targetMandate: getMandateAddress("DelegateTokenSelect", deployedMandates),
      config: encodeAbiParameters(
        parseAbiParameters("address VotesToken, address Nominees, uint256 RoleId, uint256 MaxRoleHolders"),
        [ 
          getConstants(chainId).VOTES_TOKEN as `0x${string}`,
          getContractAddressFromReceipt(dependencyReceipts["Nominees"], "Nominees"), 
          2n,
          3n
        ]
      ),
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE,
        throttleExecution: minutesToBlocks(10, chainId), // Can be run once every 10 minutes (in reality every 10 days)
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
