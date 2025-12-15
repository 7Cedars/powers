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
export const PowerLabs: Organization = {
  metadata: {
    id: "power-labs",
    title: "Power Labs",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "This is an alpha implementation of the Power Labs organisation. It manages protocol development funding via Safe Smart Accounts and governance based on GitHub contributions verified by commit signatures. Also it is possible to buy Funder roles through ETH donations.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [
    { name: "chainlinkSubscriptionId", placeholder: "Chainlink Functions Subscription ID", type: "number", required: true },
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
    // console.log("deployedMandates @ PowerLabs", deployedMandates);
    // console.log("chainId @ createMandateInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Setup Safe: Create a SafeProxy and register it as treasury.",
      targetMandate: getMandateAddress("SafeSetup", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'safeProxyFactory', type: 'address' },
          { name: 'safeL2Singleton', type: 'address' }
        ], 
        [
          getConstants(chainId).SAFE_PROXY_FACTORY as `0x${string}`,
          getConstants(chainId).SAFE_L2_CANONICAL as `0x${string}`,
        ]
      ), 
      conditions: createConditions({ 
        allowedRole: PUBLIC_ROLE
      })
    });

    mandateCounter++;
    mandateInitData.push({ // mandate 1 : Initial setup
      nameDescription: "Configure Organisation: Adopt allowance module to SafeProxy, assign role labels and create governance flows.",
      targetMandate: getConstants(chainId).POWER_LABS_CONFIG as `0x${string}`, // Here have to use getConstants to get the config mandate. 
      config: "0x" as `0x${string}`,
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
     
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    /////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Apply for Contributor Role: Anyone can claim contributor roles based on their GitHub contributions to the 7cedars/powers repository",
      targetMandate: getMandateAddress("ClaimRoleWithGitSig", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'branch', type: 'string' },
          { name: 'paths', type: 'string[]' },
          { name: 'roleIds', type: 'uint256[]' },
          { name: 'signatureString', type: 'string' },
          { name: 'subscriptionId', type: 'uint64' },
          { name: 'gasLimit', type: 'uint32' },
          { name: 'donID', type: 'bytes32' }
        ],
        [ 
          "develop",
          ["documentation", "frontend", "solidity"],
          [2n, 3n, 4n],
          "signed",
          formData["chainlinkSubscriptionId"] as bigint,
          getConstants(chainId).CHAINLINK_GAS_LIMIT as number,
          getConstants(chainId).CHAINLINK_DON_ID as `0x${string}`
        ]
      ),
      conditions: createConditions({ 
        allowedRole: PUBLIC_ROLE,
        throttleExecution: minutesToBlocks(3, chainId) // Prevents spamming the mandate with multiple claims in a short time
      })
    });
    const claimMandate = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Claim Contributor Role: Following a successful initial claim, contributors can get contributor role assigned to their account.",
      targetMandate: getMandateAddress("AssignRoleWithGitSig", deployedMandates),
      config: `0x`, // No config needed as all data is in the commit signatures  
      conditions: createConditions({ 
        allowedRole: PUBLIC_ROLE,
        needFulfilled: claimMandate // Must have claimed a contributor role first
      })
    });

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Apply for Member Role: Receive Member role when holding Funder or any Contributor role",
      targetMandate: getMandateAddress("RoleByRoles", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'newRoleId', type: 'uint256' },
          { name: 'roleIdsNeeded', type: 'uint256[]' }
        ],
        [5n, [1n, 2n, 3n, 4n]]
      ),
      conditions: createConditions({ allowedRole: PUBLIC_ROLE })
    });
    
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Veto Role Revocation: Admin can veto proposals to remove roles from accounts",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates), // Veto is just an intent
      config: encodeAbiParameters(parseAbiParameters('string[] inputParams'), [["uint256 roleId", "address account"]]), // Matches proposal input partially
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
    const vetoRoleMandate = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Revoke Role: Members vote to remove a role from an account",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates), // Use BespokeActionSimple for direct Powers call
      config: encodeAbiParameters(
        [
          { name: 'targetContract', type: 'address' },
          { name: 'functionSelector', type: 'bytes4' },
          { name: 'inputParams', type: 'string[]' }
        ],
        [ 
          powersAddress, 
          toFunctionSelector("revokeRole(uint256,address)"), // function selector for revokeRole
          ["uint256 roleId", "address account"] // inputs needed for the function
        ] 
      ),
      conditions: createConditions({
        allowedRole: 5n, // Members propose/vote
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 51n,
        quorum: 5n, // Note: low quorum
        delayExecution: minutesToBlocks(3, chainId),
        needNotFulfilled: vetoRoleMandate // Link dependency to veto mandate
      })
    });
    
    
    //////////////////////////////////////////////////////////////////
    //                 CONSTITUTIONAL LAWS                          //
    //////////////////////////////////////////////////////////////////
    const adoptMandatesConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address[] mandates", "uint256[] roleIds"]]
    );

    // Adopt Mandates flow. 
    // Propose Mandate Package - Unchanged (but renumbered)
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Propose Adopting Mandates: Members propose adopting new mandates",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: adoptMandatesConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });
    const proposeAdoptMandate = BigInt(mandateCounter);

    // Mandate 26: Veto Mandate Package - Unchanged (but renumbered & dependency adjusted)
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Veto Adopting Mandates: Funders can veto proposals to adopt new mandates",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: adoptMandatesConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: proposeAdoptMandate
      })
    }); 
    const vetoAdoptMandate = BigInt(mandateCounter);

    // Mandate 27: Adopt Mandate Package - Unchanged (but renumbered & dependencies adjusted)
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Adopt Mandates: Admin adopts new mandates into the organization",
      targetMandate: getMandateAddress("AdoptMandates", deployedMandates), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: vetoAdoptMandate, // For testing, we allow direct adoption without veto
        needNotFulfilled: proposeAdoptMandate // For testing, we allow direct adoption without veto
      })
    });

    // Revoke mandates flow. 
    const revokeMandatesConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["uint16[] mandateIds"]]
    );

    // Revoke Mandates flow. 
    // Mandate 25: Propose revoking Mandates 
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Propose Revoking Mandates: Members propose revoking existing mandates",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: revokeMandatesConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });
    const proposeRevokeMandate = BigInt(mandateCounter);

    // Mandate 26: Veto Revoking Mandates
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Veto Revoking Mandates: Funders can veto proposals to revoke existing mandates",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: revokeMandatesConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: proposeRevokeMandate
      })
    }); 
    const vetoRevokeMandate = BigInt(mandateCounter);

    // Mandate 27: Revoke Mandates 
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Revoke Mandates: Admin revokes mandates from the organization",
      targetMandate: getMandateAddress("RevokeMandates", deployedMandates), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: vetoRevokeMandate, // For testing, we allow direct revocation without veto
        needNotFulfilled: proposeRevokeMandate // For testing, we allow direct revocation without veto
      })
    });

    // Adopt Children Mandates flow.
    // Propose Mandate Package - Unchanged (but renumbered)
    const adoptChildrensMandatesConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address[] mandates", "uint256[] roleIds"]]
    );

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Propose adopting a Child Mandate: Members propose adopting new mandates for a Powers' child",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: adoptChildrensMandatesConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });
    const proposeMandate = BigInt(mandateCounter); 

    // Veto Mandate Package - Unchanged (but renumbered & dependency adjusted)
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Veto Adopting A child Mandate: Funders can veto proposals to adopt new mandates for a Powers' child",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: adoptChildrensMandatesConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: minutesToBlocks(10, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: proposeMandate
      })
    }); 
    const vetoMandate = BigInt(mandateCounter);

    // Adopt Mandate Package - Unchanged (but renumbered & dependencies adjusted)
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Adopt a Child Mandate: Admin adopts the new mandate for a Powers' child",
      targetMandate: getMandateAddress("StatementOfIntent", deployedMandates),
      config: adoptChildrensMandatesConfig,
      conditions: createConditions({
        allowedRole: 0n, // Admin
        needFulfilled: proposeMandate,
        needNotFulfilled: vetoMandate
      })
    }); 

    return mandateInitData;
  }
};
