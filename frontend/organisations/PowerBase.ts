import { Organization, LawInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi } from "@/context/abi"; // Assuming allo ABI is also available if needed for encoding calls
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getLawAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions } from "./helpers";
import donations from "@/context/builds/Donations.json";
import erc20Taxed from "@/context/builds/Erc20Taxed.json";
import easyRPGFStrategyBuild from "@/context/builds/EasyRPGFStrategy.json";
import registry from "@/context/builds/Registry.json";
import { getConstants } from "@/context/constants";

/**
 * Helper function to extract contract address from receipt
 */
function getContractAddressFromReceipt(receipt: any): `0x${string}` | undefined {
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
 * Power Base Organization (Allo v2 Revision)
 *
 * Manages Powers protocol development funding via Allo v2 pools.
 * Governance based on GitHub contributions verified by commit signatures.
 *
 * Key Features:
 * - Three independent Allo v2 pools (Docs, Frontend, Protocol) using DirectGrantsLiteStrategy
 * - Contributor roles assigned via RoleByGitSignature.sol (Chainlink Functions)
 * - Funder participation through token purchases
 * - Allo v2 manages recipient registration and fund allocation
 * - Constitutional amendment process
 */
export const PowerBase: Organization = {
  metadata: {
    id: "power-base-allo",
    title: "Power Base",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreihseorlowhkh3tbtrp2y6pd3s6zdiampreq7uotscppmiee3yjfki",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "Power Base uses Allo v2 for decentralized grant management. It is governed by contributors that are verified via EVM signatures posted in github commits.",
    disabled: false,
    onlyLocalhost: false
  },
  fields: [
    // Fields needed for RoleByGitSignature
    { name: "chainlinkSubscriptionId", placeholder: "Chainlink Functions Subscription ID", type: "number", required: true },
  ],
  dependencies:  [
    {
      name: "Donations", 
      abi: JSON.parse(JSON.stringify(donations.abi)) as Abi,
      args: [],
      bytecode: JSON.parse(JSON.stringify(donations.bytecode.object)) as `0x${string}`,
      ownable: true
    }
    // {
    //   name: "EasyRPGFStrategy (Allo V2)",
    //   abi: JSON.parse(JSON.stringify(easyRPGFStrategyBuild.abi)) as Abi,
    //   args: [getConstants(11155111).ALLO_V2_ADDRESS as `0x${string}`, "EasyRPGFStrategy v1.0"], // Needs Allo address, Name
    //   bytecode: JSON.parse(JSON.stringify(easyRPGFStrategyBuild.bytecode.object)) as `0x${string}`,
    //   ownable: false // This strategy doesn't need to be owned by Powers
    // } as DeployableContract
  ],   
 
  createLawInitData: (
    powersAddress: `0x${string}`,
    formData: Record<string, any>,
    deployedLaws: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ): LawInitData[] => {
    const lawInitData: LawInitData[] = [];
    const registryAbi: Abi = JSON.parse(JSON.stringify(registry.abi)) 
    let lawCount = 0n; 
    // Extract contract addresses from receipts
    const donationsAddress = getContractAddressFromReceipt(dependencyReceipts["Donations"]);  

    console.log("chainId @ createLawInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    lawCount++;
    const protocolMetadata = {
      protocol: 1n,
      pointer: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibjnkey6ldzghkbnp73pigh4lj6rmnmqalzplcwfz25vmhl3rst3q"
    } as const;

    lawInitData.push({ // law 1 : Initial setup
      nameDescription: "INITIAL SETUP: Label roles, registers Powers to Allo v2 registry & revokes itself after execution",
      targetLaw: getLawAddress("PresetSingleAction", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [
            getConstants(chainId).ALLO_V2_REGISTRY_ADDRESS as `0x${string}`, 
            powersAddress, powersAddress, powersAddress, powersAddress, powersAddress, powersAddress],
          [
            0n, 
            0n, 0n, 0n, 0n, 0n, 0n],
          [
            encodeFunctionData({ abi: registryAbi, functionName: "createProfile", args: [
              12345n, 
              "Powers", 
              protocolMetadata,
              powersAddress as `0x${string}`, 
              [powersAddress as `0x${string}`]] 
            }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [1n, "Funders"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [2n, "Doc Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [3n, "Frontend Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [4n, "Protocol Contributors"] }),
            encodeFunctionData({ abi: powersAbi, functionName: "labelRole", args: [5n, "Members"] }), 
            encodeFunctionData({ abi: powersAbi, functionName: "revokeLaw", args: [1n]}) // Revokes itself after execution
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

    //////////////////////////////////////////////////////////////////
    //        DYNAMIC POOL CREATION & GOVERNANCE ADOPTION           //
    //////////////////////////////////////////////////////////////////

    const inputParamsPoolCreation = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address TokenAddress", "uint256 Amount", "uint16 ManagerRoleId"]]
    );

    // const adoptLawPackageConfig = encodeAbiParameters(
    //   parseAbiParameters('string[] inputParams'),
    //   [["address[] laws", "bytes[] lawInitDatas"]]
    // );
    // --- Law A Instance: Create EasyRPGF Pool ---
    lawCount++; 
    lawInitData.push({ // Law 2: Propose Pool Creation (SoI)
      nameDescription: "Propose Pool Creation: Members vote to propose to create new Allo v2 pools.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 5n, // Members propose
        votingPeriod: daysToBlocks(7, chainId), succeedAt: 51n, quorum: 33n
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 3: Veto Pool Creation (SoI)
      nameDescription: "Veto Pool Creation: Funders can veto the proposal to create a new Allo v2 pool through a vote.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 1n, // Funders veto
        votingPeriod: daysToBlocks(3, chainId), succeedAt: 66n, quorum: 50n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 2: Propose Pool Creation (SoI)
      nameDescription: "OK Pool Creation: Doc Contributors vote to ok the proposal to create a new Allo v2 pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 2n, // First Doc Contributors ok the proposal
        votingPeriod: daysToBlocks(7, chainId), succeedAt: 51n, quorum: 33n,
        needNotFulfilled: lawCount - 1n, // Can only ok if vetoed
        needFulfilled: lawCount - 2n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 2: Propose Pool Creation (SoI)
      nameDescription: "OK Pool Creation: Frontend Contributors vote to ok the proposal to create a new Allo v2 pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 3n, // Second Frontend Contributors ok the proposal
        votingPeriod: daysToBlocks(7, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; // Law ID 3 
    const alloProfilIdPowers = keccak256(encodePacked(
      ["uint256", "address"], 
      [1n, powersAddress]
    ));
    lawInitData.push({ // Law 4: Execute Pool Creation (Law A Instance)
      nameDescription: "Execute Pool Creation: Frontend Contributors vote to ok the proposal and execute to create the new Allo v2 pool.",
      targetLaw: getLawAddress("AlloCreateRPGFPool", deployedLaws), // Base implementation of Law A
      config: encodeAbiParameters(
        parseAbiParameters('address allo, bytes32 profileId, address easyRPGFStrategy'),
        [
          getConstants(chainId).ALLO_V2_ADDRESS as `0x${string}`, 
          alloProfilIdPowers, 
          getConstants(chainId).ALLO_V2_EASY_RPGF_STRATEGY_ADDRESS as `0x${string}`]
      ),
      // inputParams: encodeAbiParameters(parseAbiParameters('string[] params'), [['address token', 'uint256 amount', 'uint16 managerRoleId']]), // Define expected input for this instance
      conditions: createConditions({
        allowedRole: 4n, // Third Protocol Contributors executes the proposal
        votingPeriod: daysToBlocks(7, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 7: Execute Governance Adoption (Law B Instance)
      nameDescription: "Adopt Governance Pools: After pool is created, anyone can implement the governance flow for the pool.",
      targetLaw: getLawAddress("AlloRPFGGovernance", deployedLaws), // Base implementation of Law B
      config: encodeAbiParameters(
        parseAbiParameters('address allo, address soi, address alloDistribute, uint16 createPoolLawId'),
        [
          getConstants(chainId).ALLO_V2_ADDRESS as `0x${string}`, 
          getLawAddress("StatementOfIntent", deployedLaws), 
          getConstants(chainId).ALLO_V2_ADDRESS as `0x${string}`, 
          Number(lawCount - 4n) // Pass base law addresses & the ID of Law A instance (Law 4)
        ]
      ),
      // inputParams: encodeAbiParameters(parseAbiParameters('string[] params'), [['uint256 createPoolActionId']]), // Define expected input for this instance
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE, // Anybody can execute this law. It has already been approved by the contributors. Everyone had their say. 
        needFulfilled: lawCount - 1n
      })
    });

    // White list token flow.
    lawCount++;
    lawInitData.push({
      nameDescription: "Veto listing token: Funders can veto white listing or dewhitelisting a token.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws), // Veto is just an intent
      config: encodeAbiParameters(
        [ { name: 'params', type: 'string[]' }, ],
        [ ["address token", "bool whitelisted"] ]
      ), // Matches proposal input partially
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: daysToBlocks(3, chainId),
        succeedAt: 33n,
        quorum: 50n
      })
    });

    lawCount++;
    lawInitData.push({
      nameDescription: "List token: Members can list a token for donation.",
      targetLaw: getLawAddress("BespokeActionSimple", deployedLaws),
      config: encodeAbiParameters(
        [ { name: 'targetContract', type: 'address' },
          { name: 'targetFunction', type: 'bytes4' },
          { name: 'inputParams', type: 'string[]' }
        ],
        [ 
          donationsAddress as `0x${string}`, 
          toFunctionSelector("setWhitelistedToken(address,bool)"), // function selector for setWhitelistedToken
          ["address token", "bool whitelisted"] // inputs needed for the function
        ]  
      ),
      conditions: createConditions({ 
        allowedRole: 5n, // Members
        votingPeriod: daysToBlocks(5, chainId),
        succeedAt: 51n,
        quorum: 50n,
        delayExecution: daysToBlocks(5, chainId),
        needNotFulfilled: lawCount - 1n, // Can only list if not vetoed
      })
    });
    
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    /////////////////////////////////////////////////////////////////
    // Law 20: Assign Contributor Role via Git Signature
    lawCount++;
    lawInitData.push({
      nameDescription: "Claim Contributor Role: Anyone can claim contributor roles based on their GitHub contributions to the 7cedars/powers repository.",
      targetLaw: getLawAddress("RoleByGitSignature", deployedLaws),
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
          ["gitbook", "frontend", "solidity"],
          [2n, 3n, 4n],
          "signed",
          formData["chainlinkSubscriptionId"] as bigint,
          getConstants(chainId).CHAINLINK_GAS_LIMIT as number,
          getConstants(chainId).CHAINLINK_DON_ID as `0x${string}`
        ]
      ),
      conditions: createConditions({ allowedRole: PUBLIC_ROLE })
    });
    
    lawCount++;
    lawInitData.push({
      nameDescription: `Assign or revoke funder role: Funder roles are assigned or revoked based on donations to contract ${donationsAddress} with token ${getConstants(chainId).ERC20_TAXED_ADDRESS}.`,
      targetLaw: getLawAddress("BuyAccess", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'DonationsContract', type: 'address' },
          { name: 'Tokens', type: 'address[]' },
          { name: 'TokensPerBlock', type: 'uint256[]' },
          { name: 'RoleId', type: 'uint256' }
        ],
        [donationsAddress as `0x${string}`, [getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`], [1000000000000000000n], 1n]
      ),
      conditions: createConditions({ allowedRole: PUBLIC_ROLE })
    });

    lawCount++;
    lawInitData.push({
      nameDescription: "Apply for Member role: Receive Member role if holding funder or one of the contributer roles.",
      targetLaw: getLawAddress("RoleByRoles", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'newRoleId', type: 'uint256' },
          { name: 'roleIdsNeeded', type: 'uint256[]' }
        ],
        [5n, [1n, 2n, 3n, 4n]]
      ),
      conditions: createConditions({ allowedRole: PUBLIC_ROLE })
    });
     
    // Law 24: Veto Role Revocation
    lawCount++;
    lawInitData.push({
      nameDescription: "Veto Role Revocation: Admin can veto role removal.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws), // Veto is just an intent
      config: encodeAbiParameters(parseAbiParameters('string[] inputParams'), [["uint256 roleId", "address account"]]), // Matches proposal input partially
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

    lawCount++;
    lawInitData.push({
      nameDescription: "Remove Role: Members vote to remove a role from accounts.",
      targetLaw: getLawAddress("BespokeActionSimple", deployedLaws), // Use BespokeActionSimple for direct Powers call
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
        votingPeriod: daysToBlocks(5, chainId),
        succeedAt: 51n,
        quorum: 5n, // Note: low quorum
        delayExecution: daysToBlocks(5, chainId),
        needNotFulfilled: lawCount - 1n // Link dependency to veto law
      })
    });


    //////////////////////////////////////////////////////////////////
    //                 CONSTITUTIONAL LAWS                          //
    // //////////////////////////////////////////////////////////////////
    const adoptLawsConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address[] laws", "bytes[] lawInitDatas"]]
    );

    // Adopt Laws flow. 
    // Law 25: Propose Law Package - Unchanged (but renumbered)
    lawCount++;
    lawInitData.push({
      nameDescription: "Propose Law Package: Members vote to propose new laws.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: adoptLawsConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });

    // Law 26: Veto Law Package - Unchanged (but renumbered & dependency adjusted)
    lawCount++;
    lawInitData.push({
      nameDescription: "Veto Law Package: Funders can veto proposed law packages.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: adoptLawsConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: daysToBlocks(3, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: lawCount - 1n
      })
    }); 

    // Law 27: Adopt Law Package - Unchanged (but renumbered & dependencies adjusted)
    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Law Package: Admin adopts new laws.",
      targetLaw: getLawAddress("AdoptLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: lawCount - 2n,
        needNotFulfilled: lawCount - 1n
      })
    });


    // Revoke laws flow. 
    const revokeLawsConfig = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["uint16[] lawIds"]]
    );

    // Law 25: Propose revoking Laws 
    lawCount++;
    lawInitData.push({
      nameDescription: "Propose Revoking Law: Members vote to propose revoking laws.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: revokeLawsConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });

    // Law 26: Veto Revoking Laws
    lawCount++;
    lawInitData.push({
      nameDescription: "Veto Revoking Laws: Funders can veto proposed revoking laws.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: revokeLawsConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: daysToBlocks(3, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: lawCount - 1n
      })
    }); 

    // Law 27: Revoke Laws
    lawCount++;
    lawInitData.push({
      nameDescription: "Revoke Laws: Admin revokes laws.",
      targetLaw: getLawAddress("RevokeLaws", deployedLaws), // Ensure this name matches build
      config: "0x00" as `0x${string}`,  
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: lawCount - 2n,
        needNotFulfilled: lawCount - 1n
      })
    });

    return lawInitData;
  }
};