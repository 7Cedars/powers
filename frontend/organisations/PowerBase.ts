import { Organization, LawInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi } from "@/context/abi"; // Assuming allo ABI is also available if needed for encoding calls
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getLawAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createLawInitData } from "./helpers";
import treasuryPools from "@/context/builds/TreasuryPools.json";
import { getConstants } from "@/context/constants";

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
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiamywxjb6kddwboempkqka37lkdmuljc2t7oju4bzfuxdlau575zu",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "Power Base is the on-chain organization that shepherds the development of the Powers protocol. It uses Allo v2 for decentralized grant management. It is governed by contributors that are verified via EVM signatures posted in github commits.",
    disabled: false,
    onlyLocalhost: false
  },
  fields: [
    // Fields needed for RoleByGitSignature
    { name: "chainlinkSubscriptionId", placeholder: "Chainlink Functions Subscription ID", type: "number", required: true },
  ],
  dependencies:  [
    {
      name: "Treasury", 
      abi: JSON.parse(JSON.stringify(treasuryPools.abi)) as Abi,
      args: [],
      bytecode: JSON.parse(JSON.stringify(treasuryPools.bytecode.object)) as `0x${string}`,
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
    let lawCount = 0n; 
    // Extract contract addresses from receipts
    const treasuryAddress = getContractAddressFromReceipt(dependencyReceipts["Treasury"], "Treasury");
    const treasuryAbi = JSON.parse(JSON.stringify(treasuryPools.abi)) as Abi;
    console.log("deployedLaws @ PowerBase", deployedLaws);

    console.log("chainId @ createLawInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    lawCount++;
    lawInitData.push({ // law 1 : Initial setup
      nameDescription: "INITIAL SETUP: Set treasury, label roles, registers Powers to Allo v2 registry & revokes itself after execution",
      targetLaw: getLawAddress("PresetSingleAction", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [
            powersAddress,
            treasuryAddress, 
            treasuryAddress, treasuryAddress, treasuryAddress,  
            powersAddress, powersAddress, powersAddress, powersAddress, powersAddress, 
            powersAddress],
            
          [
            0n, 
            0n, 
            0n, 0n, 0n,
            0n, 0n, 0n, 0n, 0n, 
            0n],
          [
            encodeFunctionData({ abi: powersAbi, functionName: "setTreasury", args: [treasuryAddress] }),
            // Note: one type of token is only being used for all pools here. Later this can be updated by adopting new laws. 
            encodeFunctionData({ abi: treasuryAbi, functionName: "setWhitelistToken", args: [getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`, true] }),
            encodeFunctionData({ abi: treasuryAbi, functionName: "createPool", args: [getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`, 0] }), // Doc Contributors Pool
            encodeFunctionData({ abi: treasuryAbi, functionName: "createPool", args: [getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`, 0] }), // Frontend Contributors Pool
            encodeFunctionData({ abi: treasuryAbi, functionName: "createPool", args: [getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`, 0] }), // Protocol Contributors Pool 
            // // setting role labels
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

    //////////////////////////////////////////////////////////////////
    ///                   Spend Budget flow                         // 
    //////////////////////////////////////////////////////////////////
    const inputParamsPoolBudgetIncrease = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["uint256 PoolId", "address payableTo", "uint256 Amount"]]
    );

    lawCount++; 
    lawInitData.push({  
      nameDescription: `Create Proposal for spending funds from a specific pool.`,
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolBudgetIncrease,
      conditions: createConditions({
        allowedRole: 5n, // Members propose
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n
      })
    });
    const proposalLawIndex = lawCount;

    lawCount++; 
    lawInitData.push({  
      nameDescription: "Veto Proposal: Funders can veto the proposal to spend a budget from pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolBudgetIncrease,
      conditions: createConditions({
        allowedRole: 1n, // Funders veto
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 66n, quorum: 50n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });
    const vetoLawIndex = lawCount;

    // Loop through contributor roles to create spending laws
    const contributorRoles = [
      { id: 2n, name: "Doc Contributors", poolId: 1n },
      { id: 3n, name: "Frontend Contributors", poolId: 2n },
      { id: 4n, name: "Protocol Contributors", poolId: 3n }
    ];

    contributorRoles.forEach(role => {
      lawCount++;
      lawInitData.push({
        nameDescription: `Pool ${Number(role.poolId)} Execute Spending: ${role.name} can execute a spending proposal from their pool.`,
        targetLaw: getLawAddress("TreasuryPoolTransfer", deployedLaws),
        config: encodeAbiParameters(
          parseAbiParameters("address TargetContract, uint256 PoolId"),
          [
            treasuryAddress as `0x${string}`,
            role.poolId
          ]
        ),
        conditions: createConditions({
          allowedRole: role.id,
          votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 25n,
          needNotFulfilled: vetoLawIndex, // Must not be vetoed
          needFulfilled: proposalLawIndex    // Must be proposed
        })
      });
    });

    //////////////////////////////////////////////////////////////////
    //             CREATE NEW POOLS + GOVERNANCE                    //
    //////////////////////////////////////////////////////////////////
    const inputParamsPoolCreation = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["address tokenAddress", "uint256 Budget", "uint256 ManagerRoleId"]]
    );

    // --- Law A Instance: Create EasyRPGF Pool ---
    lawCount++; 
    lawInitData.push({  
      nameDescription: "Propose Pool Creation: Members vote to propose to create a new Treasury pool",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 5n, // Members propose
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n
      })
    });

    lawCount++; 
    lawInitData.push({  
      nameDescription: "Veto Pool Creation: Funders can veto a proposal to create a new Treasury pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 1n, // Funders veto
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 66n, quorum: 50n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ 
      nameDescription: "OK Pool Creation: Doc Contributors vote to ok the creation of the Treasury pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 2n, // First Doc Contributors ok the proposal
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needNotFulfilled: lawCount - 1n, // Can only ok if vetoed
        needFulfilled: lawCount - 2n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({  
      nameDescription: "OK Pool Creation: Frontend Contributors vote to ok the creation of the Treasury pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolCreation,
      conditions: createConditions({
        allowedRole: 3n, // Second Frontend Contributors ok the proposal
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 4: Execute Pool Creation (Law A Instance)
      nameDescription: "Execute Pool Creation: Protocol Contributors vote to ok the proposal and execute to create the Treasury pool.",
      targetLaw: getLawAddress("BespokeActionSimple", deployedLaws), // Base implementation of Law B
      config: encodeAbiParameters(
        parseAbiParameters("address TargetContract, bytes4 TargetFunction, string[] Params"),
        [
          treasuryAddress as `0x${string}`, 
          `0x12d36171` as `0x${string}`, // function selector for createPool function
          ["address tokenAddress", "uint256 Budget", "uint256 ManagerRoleId"]
        ]
      ),
      // inputParams: encodeAbiParameters(parseAbiParameters('string[] params'), [['address token', 'uint256 amount', 'uint256 ManagerRoleId']]), // Define expected input for this instance
      conditions: createConditions({
        allowedRole: 4n, // 4n, // Third Protocol Contributors executes the proposal
        // NB! took out needFulfilled + voting for testing purposes. NEED TO REINSTATE AFTERWARDS! 
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n
      })
    });

    lawCount++; 
    lawInitData.push({  
      nameDescription: "Create Pool Governance: Anyone can add governance for newly added pool.",
      targetLaw: getLawAddress("TreasuryPoolGovernance", deployedLaws),
      config: encodeAbiParameters(
      parseAbiParameters('address selectedPoolTransfer, address treasuryPools, uint16 proposalLawId, uint16 vetoLawId, uint48 votingPeriod, uint8 succeedAt, uint8 quorum'),
        [
          getLawAddress("TreasuryPoolTransfer", deployedLaws),
          treasuryAddress as `0x${string}`,
          Number(proposalLawIndex),
          Number(vetoLawIndex),
          Number(daysToBlocks(1, chainId)), 
          51, 
          25
        ]
      ),
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE, // Second Frontend Contributors ok the proposal
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    //////////////////////////////////////////////////////////////////
    //                  UPDATE POOL BUDGETS                         //
    //////////////////////////////////////////////////////////////////

    const inputParamsPoolFunding = encodeAbiParameters(
      parseAbiParameters('string[] inputParams'),
      [["uint256 poolId", "uint256 Amount"]]
    );

    // --- Law A Instance: Create EasyRPGF Pool ---
    lawCount++; 
    lawInitData.push({  
      nameDescription: "Propose Pool Funding: Members vote to propose to fund a Treasury pools",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolFunding,
      conditions: createConditions({
        allowedRole: 5n, // Members propose
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n
      })
    });

    lawCount++; 
    lawInitData.push({  
      nameDescription: "Veto Pool Funding: Funders can veto a proposal to fund a pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolFunding,
      conditions: createConditions({
        allowedRole: 1n, // Funders veto
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 66n, quorum: 50n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ 
      nameDescription: "OK Pool Funding: Doc Contributors vote to ok the fund the Treasury pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolFunding,
      conditions: createConditions({
        allowedRole: 2n, // First Doc Contributors ok the proposal
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needNotFulfilled: lawCount - 1n, // Can only ok if vetoed
        needFulfilled: lawCount - 2n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({  
      nameDescription: "OK Pool Funding: Frontend Contributors vote to ok the fund the Treasury pool.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: inputParamsPoolFunding,
      conditions: createConditions({
        allowedRole: 3n, // Second Frontend Contributors ok the proposal
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n // Can only veto if proposed
      })
    });

    lawCount++; 
    lawInitData.push({ // Law 4: Execute Pool Creation (Law A Instance)
      nameDescription: "Execute Pool Funding: Protocol Contributors vote to ok the proposal and execute to fund the Treasury pool.",
      targetLaw: getLawAddress("BespokeActionSimple", deployedLaws), // Base implementation of Law B
      config: encodeAbiParameters(
        parseAbiParameters("address TargetContract, bytes4 TargetFunction, string[] Params"),
        [
          treasuryAddress as `0x${string}`, 
          `0xb26590f3` as `0x${string}`, // function selector for createPool function
          ["uint256 poolId", "uint256 Amount"]
        ]
      ),
      // inputParams: encodeAbiParameters(parseAbiParameters('string[] params'), [['address token', 'uint256 amount', 'uint256 ManagerRoleId']]), // Define expected input for this instance
      conditions: createConditions({
        allowedRole: 4n, // 4n, // Third Protocol Contributors executes the proposal
        // NB! took out needFulfilled + voting for testing purposes. NEED TO REINSTATE AFTERWARDS! 
        votingPeriod: daysToBlocks(1, chainId), succeedAt: 51n, quorum: 33n,
        needFulfilled: lawCount - 1n
      })
    });

    /// I should have a dedicated law for people to fund the protocol. 
    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    /////////////////////////////////////////////////////////////////
    lawCount++;
    lawInitData.push({
      nameDescription: "Apply for Contributor Role: Anyone can claim contributor roles based on their GitHub contributions to the 7cedars/powers repository.",
      targetLaw: getLawAddress("ClaimRoleWithGitSig", deployedLaws),
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
        throttleExecution: daysToBlocks(1, chainId) // Prevents spamming the law with multiple claims in a short time
      })
    });
    
    lawCount++;
    lawInitData.push({
      nameDescription: `Apply for funder role: Funder roles are assigned or revoked based on donations to t ${treasuryAddress}.`,
      targetLaw: getLawAddress("TreasuryRoleWithTransfer", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'TreasuryContract', type: 'address' },
          { name: 'Tokens', type: 'address[]' },
          { name: 'TokensPerBlock', type: 'uint256[]' },
          { name: 'RoleId', type: 'uint256' }
        ],
        [
          treasuryAddress as `0x${string}`, 
          [ `0x0000000000000000000000000000000000000000`, getConstants(chainId).ERC20_TAXED_ADDRESS as `0x${string}`], // native Eth, token address
          [ 100n, 1000000000000000000n ], 
          1n
        ]
      ),
      conditions: createConditions({ 
        allowedRole: PUBLIC_ROLE,
        throttleExecution: daysToBlocks(1, chainId) // Prevents spamming the law with multiple claims in a short time
      })
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
      nameDescription: "Revoke Role: Members vote to remove a role from accounts.",
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
        votingPeriod: daysToBlocks(1, chainId),
        succeedAt: 51n,
        quorum: 5n, // Note: low quorum
        delayExecution: daysToBlocks(1, chainId),
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
      nameDescription: "Propose Adopting Laws: Members vote to propose new laws.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: adoptLawsConfig,
      conditions: createConditions({
        allowedRole: 5n, // Members
        votingPeriod: daysToBlocks(1, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });

    // Law 26: Veto Law Package - Unchanged (but renumbered & dependency adjusted)
    lawCount++;
    lawInitData.push({
      nameDescription: "Veto Adopting Laws: Funders can veto proposed law packages.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: adoptLawsConfig,
      conditions: createConditions({
        allowedRole: 1n, // Funders
        votingPeriod: daysToBlocks(1, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: lawCount - 1n
      })
    }); 

    // Law 27: Adopt Law Package - Unchanged (but renumbered & dependencies adjusted)
    lawCount++;
    lawInitData.push({
      nameDescription: "Adopt Laws: Admin adopts new laws.",
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
        votingPeriod: daysToBlocks(1, chainId),
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
        votingPeriod: daysToBlocks(1, chainId),
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
