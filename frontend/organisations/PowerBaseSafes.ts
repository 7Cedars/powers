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
export const PowerBaseSafes: Organization = {
  metadata: {
    id: "power-base-safes",
    title: "Power Base Safes",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieiaf44y7krxtej64npspwjskcv2fns4fjndjxlqqy4q4hx7ol25m",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaexs22jpd7xiq2bl2snyerw2bi4m4drxsq73cqxcxxptokbbm4cm",
    description: "TEMP: This is a temporary placeholder org, meant to create PowerBase using Safes.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [
    { name: "chainlinkSubscriptionId", placeholder: "Chainlink Functions Subscription ID", type: "number", required: true },
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
    // console.log("deployedLaws @ PowerBase", deployedLaws);
    // console.log("chainId @ createLawInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    lawInitData.push({ // law 1 : Initial setup
      nameDescription: "Initial Setup: Assign roles labels.",
      targetLaw: getLawAddress("PresetSingleAction", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ], 
        [
          [ 
            powersAddress, powersAddress, powersAddress, powersAddress, powersAddress, 
            powersAddress
          ],
          [
            0n, 0n, 0n, 0n, 0n, 
            0n
          ],
          [
            // setting role labels
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [1n, "Funders"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [2n, "Doc Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [3n, "Frontend Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [4n, "Protocol Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [5n, "Members"] }), 
            // revoking itself
            encodeFunctionData({ abi: powersAbi, functionName: "revokeLaw", args: [1n]}) // Revokes itself after execution
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
 
    lawInitData.push({
      nameDescription: "Setup Safe: Setup the safe, governance paths and central treasury.",
      targetLaw: "0xb4Ad76571DB0121d8A5572AC77F65627fD7cae08" as `0x${string}`, // will be saved in constants later on. 
      config: `0x`, // No config needed as all data is in the commit signatures  
      conditions: createConditions({ 
        allowedRole: PUBLIC_ROLE
      })
    });

    
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    /////////////////////////////////////////////////////////////////
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Apply for Contributor Role: Anyone can claim contributor roles based on their GitHub contributions to the 7cedars/powers repository",
    //   targetLaw: getLawAddress("ClaimRoleWithGitSig", deployedLaws),
    //   config: encodeAbiParameters(
    //     [
    //       { name: 'branch', type: 'string' },
    //       { name: 'paths', type: 'string[]' },
    //       { name: 'roleIds', type: 'uint256[]' },
    //       { name: 'signatureString', type: 'string' },
    //       { name: 'subscriptionId', type: 'uint64' },
    //       { name: 'gasLimit', type: 'uint32' },
    //       { name: 'donID', type: 'bytes32' }
    //     ],
    //     [ 
    //       "develop",
    //       ["documentation", "frontend", "solidity"],
    //       [2n, 3n, 4n],
    //       "signed",
    //       formData["chainlinkSubscriptionId"] as bigint,
    //       getConstants(chainId).CHAINLINK_GAS_LIMIT as number,
    //       getConstants(chainId).CHAINLINK_DON_ID as `0x${string}`
    //     ]
    //   ),
    //   conditions: createConditions({ 
    //     allowedRole: PUBLIC_ROLE,
    //     throttleExecution: minutesToBlocks(3, chainId) // Prevents spamming the law with multiple claims in a short time
    //   })
    // });


    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Claim Contributor Role: Following a successful initial claim, contributors can get contributor role assigned to their account.",
    //   targetLaw: getLawAddress("AssignRoleWithGitSig", deployedLaws),
    //   config: `0x`, // No config needed as all data is in the commit signatures  
    //   conditions: createConditions({ 
    //     allowedRole: PUBLIC_ROLE,
    //     needFulfilled: lawCount - 1n // Must have claimed a contributor role first
    //   })
    // });
    
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: `Apply for Funder Role: Claim a Funder role with the receiptId received following a deposit in native ETH or ERC20 Taxed token (${getConstants(chainId).ERC20_TAXED_ADDRESS}) to the Treasury.`,
    //   targetLaw: getLawAddress("TreasuryRoleWithTransfer", deployedLaws),
    //   config: encodeAbiParameters(
    //     [
    //       { name: 'TreasuryContract', type: 'address' },
    //       { name: 'Tokens', type: 'address[]' },
    //       { name: 'TokensPerBlock', type: 'uint256[]' },
    //       { name: 'RoleId', type: 'uint256' }
    //     ],
    //     [
    //       treasuryAddress as `0x${string}`, 
    //       [ `0x0000000000000000000000000000000000000000`, getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`], // native Eth, token address
    //       [ 100n, 100000000000000n ], 
    //       1n
    //     ]
    //   ),
    //   conditions: createConditions({ 
    //     allowedRole: PUBLIC_ROLE,
    //     throttleExecution: minutesToBlocks(3, chainId) // Prevents spamming the law with multiple claims in a short time
    //   })
    // });

    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Apply for Member Role: Receive Member role when holding Funder or any Contributor role",
    //   targetLaw: getLawAddress("RoleByRoles", deployedLaws),
    //   config: encodeAbiParameters(
    //     [
    //       { name: 'newRoleId', type: 'uint256' },
    //       { name: 'roleIdsNeeded', type: 'uint256[]' }
    //     ],
    //     [5n, [1n, 2n, 3n, 4n]]
    //   ),
    //   conditions: createConditions({ allowedRole: PUBLIC_ROLE })
    // });
     
    // // Law 24: Veto Role Revocation
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Veto Role Revocation: Admin can veto proposals to remove roles from accounts",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws), // Veto is just an intent
    //   config: encodeAbiParameters(parseAbiParameters('string[] inputParams'), [["uint256 roleId", "address account"]]), // Matches proposal input partially
    //   conditions: createConditions({
    //     allowedRole: ADMIN_ROLE
    //   })
    // });

    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Revoke Role: Members vote to remove a role from an account",
    //   targetLaw: getLawAddress("BespokeActionSimple", deployedLaws), // Use BespokeActionSimple for direct Powers call
    //   config: encodeAbiParameters(
    //     [
    //       { name: 'targetContract', type: 'address' },
    //       { name: 'functionSelector', type: 'bytes4' },
    //       { name: 'inputParams', type: 'string[]' }
    //     ],
    //     [ 
    //       powersAddress, 
    //       toFunctionSelector("revokeRole(uint256,address)"), // function selector for revokeRole
    //       ["uint256 roleId", "address account"] // inputs needed for the function
    //     ] 
    //   ),
    //   conditions: createConditions({
    //     allowedRole: 5n, // Members propose/vote
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 51n,
    //     quorum: 5n, // Note: low quorum
    //     delayExecution: minutesToBlocks(3, chainId),
    //     needNotFulfilled: lawCount - 1n // Link dependency to veto law
    //   })
    // });
    
    
    //////////////////////////////////////////////////////////////////
    //                 CONSTITUTIONAL LAWS                          //
    //////////////////////////////////////////////////////////////////
    // const adoptLawsConfig = encodeAbiParameters(
    //   parseAbiParameters('string[] inputParams'),
    //   [["address[] laws", "uint256[] roleIds"]]
    // );

    // // Adopt Laws flow. 
    // // Law 25: Propose Law Package - Unchanged (but renumbered)
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Propose Adopting Laws: Members propose adopting new laws",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: adoptLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 5n, // Members
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 51n,
    //     quorum: 50n
    //   })
    // });

    // // Law 26: Veto Law Package - Unchanged (but renumbered & dependency adjusted)
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Veto Adopting Laws: Funders can veto proposals to adopt new laws",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: adoptLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 1n, // Funders
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 33n,
    //     quorum: 50n,
    //     needFulfilled: lawCount - 1n
    //   })
    // }); 

    // // Law 27: Adopt Law Package - Unchanged (but renumbered & dependencies adjusted)
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Adopt Laws: Admin adopts new laws into the organization",
    //   targetLaw: getLawAddress("AdoptLaws", deployedLaws), // Ensure this name matches build
    //   config: "0x00" as `0x${string}`,  
    //   conditions: createConditions({
    //     allowedRole: ADMIN_ROLE,
    //     needFulfilled: lawCount - 2n, // For testing, we allow direct adoption without veto
    //     needNotFulfilled: lawCount - 1n // For testing, we allow direct adoption without veto
    //   })
    // });

    // // Revoke laws flow. 
    // const revokeLawsConfig = encodeAbiParameters(
    //   parseAbiParameters('string[] inputParams'),
    //   [["uint16[] lawIds"]]
    // );

    // // Revoke Laws flow. 
    // // Law 25: Propose revoking Laws 
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Propose Revoking Laws: Members propose revoking existing laws",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: revokeLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 5n, // Members
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 51n,
    //     quorum: 50n
    //   })
    // });

    // // Law 26: Veto Revoking Laws
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Veto Revoking Laws: Funders can veto proposals to revoke existing laws",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: revokeLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 1n, // Funders
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 33n,
    //     quorum: 50n,
    //     needFulfilled: lawCount - 1n
    //   })
    // }); 

    // // Law 27: Revoke Laws
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Revoke Laws: Admin revokes laws from the organization",
    //   targetLaw: getLawAddress("RevokeLaws", deployedLaws), // Ensure this name matches build
    //   config: "0x00" as `0x${string}`,  
    //   conditions: createConditions({
    //     allowedRole: ADMIN_ROLE,
    //     // needFulfilled: lawCount - 2n, // For testing, we allow direct revocation without veto
    //     needNotFulfilled: lawCount - 1n // For testing, we allow direct revocation without veto
    //   })
    // });

    // // Adopt Children Laws flow.
    // // Propose Law Package - Unchanged (but renumbered)
    // const adoptChildrensLawsConfig = encodeAbiParameters(
    //   parseAbiParameters('string[] inputParams'),
    //   [["address[] laws", "uint256[] roleIds"]]
    // );

    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Propose adopting a Child Law: Members propose adopting new laws for a Powers' child",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: adoptChildrensLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 5n, // Members
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 51n,
    //     quorum: 50n
    //   })
    // });

    // // Veto Law Package - Unchanged (but renumbered & dependency adjusted)
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Veto Adopting A child Law: Funders can veto proposals to adopt new laws for a Powers' child",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: adoptChildrensLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 1n, // Funders
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 33n,
    //     quorum: 50n,
    //     needFulfilled: lawCount - 1n
    //   })
    // }); 

    // // Adopt Law Package - Unchanged (but renumbered & dependencies adjusted)
    // lawCount++;
    // lawInitData.push({
    //   nameDescription: "Adopt a Child Law: Admin adopts the new law for a Powers' child",
    //   targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
    //   config: adoptChildrensLawsConfig,
    //   conditions: createConditions({
    //     allowedRole: 1n, // Funders
    //     votingPeriod: minutesToBlocks(10, chainId),
    //     succeedAt: 33n,
    //     quorum: 50n,
    //     needFulfilled: lawCount - 2n,
    //     needNotFulfilled: lawCount - 1n
    //   })
    // }); 

    return lawInitData;
  }
};
