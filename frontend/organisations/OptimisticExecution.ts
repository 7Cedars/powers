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
export const OptimisticExecution: Organization = {
  metadata: {
    id: "optimistic-execution",
    title: "Optimistic Execution",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "This is an example implementation of Optimisitic Execution using Powers. It is intentionally simple to highlight bicameral decision-making processes.",
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
    // console.log("deployedMandates @ PowerLabs", deployedMandates);
    // console.log("chainId @ createMandateInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Members, Executives) and revokes itself after execution",
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
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [2n, "Executives"]
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
    //        EXECUTIVE  LAWS: OPTIMISTIC EXECUTION                 //
    //////////////////////////////////////////////////////////////////
    const executeActionConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address[] targets", "uint256[] values", "bytes[] calldatas"]]
    );

    // Veto Action
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Veto Actions: Funders can veto actions",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: executeActionConfig,
      conditions: createConditions({
        allowedRole: 1n, // Members
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 66n, // note the high threshold to veto
        quorum: 66n // note the high quorum to veto
      })
    }); 
    const vetoAction = BigInt(mandateCounter);

    // Execute action 
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Execute an action: Members propose adopting new mandates",
      targetMandate: getMandateAddress("OpenAction", deployedMandates),
      config: `0x`,
      conditions: createConditions({
        allowedRole: 2n, // Executives
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 51n,
        needNotFulfilled: vetoAction,
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
