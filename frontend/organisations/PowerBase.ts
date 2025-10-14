import { Organization } from "./types";
import { LawInitData } from "./types";
import { powersAbi } from "@/context/abi";
import { encodeAbiParameters, encodeFunctionData } from "viem";
import { getLawAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions } from "./helpers";

/**
 * Power Base Organization
 * 
 * A decentralized organization for managing Powers protocol development through
 * three separate grant programs: Documentation, Frontend, and Protocol.
 * 
 * Key Features:
 * - Three independent Grant.sol instances for budget separation
 * - Contributor-based governance (GitHub commits = roles)
 * - Funder participation through token purchases
 * - Milestone-based grant disbursements
 * - Constitutional amendment process
 */
export const PowerBase: Organization = {
  metadata: {
    id: "power-base",
    title: "Power Base",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibjnkey6ldzghkbnp73pigh4lj6rmnmqalzplcwfz25vmhl3rst3q",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "Deploy the Power Base DAO - a decentralized organization that manages Powers protocol development through three independent grant programs (Documentation, Frontend, Protocol). Features contributor-based governance via GitHub commits, funder participation, and milestone-based grant disbursements.",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [],

  createLawInitData: (powersAddress: `0x${string}`, chainId: number): LawInitData[] => {
    const lawInitData: LawInitData[] = [];
    
    // Define roles
    const roles: { [key: string]: bigint } = {
      "Funders": 1n,
      "Documentation Contributors": 2n,
      "Frontend Contributors": 3n,
      "Protocol Contributors": 4n,
      "Members": 5n,
    };
    const rolesArray = Object.keys(roles);

    //////////////////////////////////////////////////////////////////
    //                 LAW 1: INITIAL SETUP                         //
    //////////////////////////////////////////////////////////////////

    const roleTargets = rolesArray.map(() => powersAddress);
    const roleValues = rolesArray.map(() => 0n);

    lawInitData.push({
      nameDescription: "RUN THIS LAW FIRST: Assigns role labels. Press refresh after execution.",
      targetLaw: getLawAddress("PresetAction", chainId),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [...roleTargets, powersAddress],
          [...roleValues, 0n],
          [
            ...rolesArray.map(roleName => 
              encodeFunctionData({
                abi: powersAbi,
                functionName: "labelRole",
                args: [roles[roleName], roleName]
              })
            ),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "revokeLaw",
              args: [1n]
            })
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE
      })
    });

    //////////////////////////////////////////////////////////////////
    //              BUDGET MANAGEMENT LAWS (2-11)                   //
    //////////////////////////////////////////////////////////////////

    const budgetConfig = encodeAbiParameters(
      [{ name: 'inputParams', type: 'string[]' }],
      [["address TokenAddress", "uint256 Budget"]]
    );

    // Law 2: Propose Documentation Budget
    lawInitData.push({
      nameDescription: "Propose Documentation Budget: Members vote on documentation grant budget.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: budgetConfig,
      conditions: createConditions({
        allowedRole: 5n,
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 33n
      })
    });

    // Law 3: Propose Frontend Budget
    lawInitData.push({
      nameDescription: "Propose Frontend Budget: Members vote on frontend grant budget.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: budgetConfig,
      conditions: createConditions({
        allowedRole: 5n,
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 33n
      })
    });

    // Law 4: Propose Protocol Budget
    lawInitData.push({
      nameDescription: "Propose Protocol Budget: Members vote on protocol grant budget.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: budgetConfig,
      conditions: createConditions({
        allowedRole: 5n,
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 33n
      })
    });

    // Law 5: Veto Budget Proposal
    lawInitData.push({
      nameDescription: "Veto Budget: Funders can veto any budget proposal (laws 2, 3, or 4).",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: budgetConfig,
      conditions: createConditions({
        allowedRole: 1n,
        votingPeriod: daysToBlocks(3, chainId),
        succeedAt: 66n,
        quorum: 50n
      })
    });

    // Laws 6-8: Set Budgets (Admin executes after proposal passes and veto doesn't)
    // const grantAddresses = [
    //   getMockAddress("DocsGrant", chainId),
    //   getMockAddress("FrontendGrant", chainId),
    //   getMockAddress("ProtocolGrant", chainId)
    // ];
    
    // const budgetLawNames = ["Documentation", "Frontend", "Protocol"];
    
    // grantAddresses.forEach((grantAddress, index) => {
    //   const needFulfilledLawId = BigInt(2 + index); // Laws 2, 3, 4
      
    //   lawInitData.push({
    //     nameDescription: `Set ${budgetLawNames[index]} Budget: Admin sets budget after proposal passes and isn't vetoed.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x8b5e3b4a" as `0x${string}`, // updateTokenBudget(address,uint256)
    //         ["address TokenAddress", "uint256 Budget"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: ADMIN_ROLE,
    //       needFulfilled: needFulfilledLawId,
    //       needNotFulfilled: 5n
    //     })
    //   });
    // });

    // // Laws 9-11: Whitelist Tokens (Admin only)
    // grantAddresses.forEach((grantAddress, index) => {
    //   lawInitData.push({
    //     nameDescription: `Whitelist Token (${budgetLawNames[index]}): Admin whitelists ERC20 tokens for grants.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x0a3b0a4f" as `0x${string}`, // whitelistToken(address)
    //         ["address Token"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: ADMIN_ROLE
    //     })
    //   });
    // });

    //////////////////////////////////////////////////////////////////
    //                    GRANT LAWS (12-26)                        //
    //////////////////////////////////////////////////////////////////

    // const proposalConfig = encodeAbiParameters(
    //   [{ name: 'inputParams', type: 'string[]' }],
    //   [["string uri", "uint256[] milestoneBlocks", "uint256[] milestoneAmounts", "address[] tokens"]]
    // );

    // const grantTypes = [
    //   { name: "Documentation", roleId: 2n, grantAddress: grantAddresses[0] },
    //   { name: "Frontend", roleId: 3n, grantAddress: grantAddresses[1] },
    //   { name: "Protocol", roleId: 4n, grantAddress: grantAddresses[2] }
    // ];

    // grantTypes.forEach(({ name, roleId, grantAddress }) => {
    //   const baseIndex = lawInitData.length;

    //   // Submit Proposal (Public)
    //   lawInitData.push({
    //     nameDescription: `Submit ${name} Grant Proposal: Anyone can submit a ${name.toLowerCase()} grant proposal.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x7c5e9b1a" as `0x${string}`, // submitProposal(string,uint256[],uint256[],address[])
    //         ["string uri", "uint256[] milestoneBlocks", "uint256[] milestoneAmounts", "address[] tokens"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: PUBLIC_ROLE
    //     })
    //   });

    //   // Veto Proposal (Members)
    //   lawInitData.push({
    //     nameDescription: `Veto ${name} Grant: Members vote to veto a ${name.toLowerCase()} grant proposal.`,
    //     targetLaw: getLawAddress("StatementOfIntent", chainId),
    //     config: encodeAbiParameters(
    //       [{ name: 'inputParams', type: 'string[]' }],
    //       [["uint256 proposalId"]]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: 5n,
    //       votingPeriod: daysToBlocks(3, chainId),
    //       succeedAt: 66n,
    //       quorum: 25n
    //     })
    //   });

    //   // Approve Grant (Contributors)
    //   lawInitData.push({
    //     nameDescription: `Approve ${name} Grant: ${name} contributors vote to approve a grant.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x6f0f6698" as `0x${string}`, // approveProposal(uint256)
    //         ["uint256 proposalId"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: roleId,
    //       votingPeriod: daysToBlocks(7, chainId),
    //       succeedAt: 51n,
    //       quorum: 50n,
    //       needNotFulfilled: BigInt(baseIndex + 2) // Veto law
    //     })
    //   });

    //   // Release Milestone (Contributors)
    //   lawInitData.push({
    //     nameDescription: `Release ${name} Milestone: ${name} contributors release milestone payments.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x4b8a4e9c" as `0x${string}`, // releaseMilestone(uint256,uint256)
    //         ["uint256 proposalId", "uint256 milestoneIndex"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: roleId
    //     })
    //   });

    //   // Reject Grant (Contributors)
    //   lawInitData.push({
    //     nameDescription: `Reject ${name} Grant: ${name} contributors vote to reject a grant.`,
    //     targetLaw: getLawAddress("BespokeActionSimple", chainId),
    //     config: encodeAbiParameters(
    //       [
    //         { name: 'target', type: 'address' },
    //         { name: 'functionSelector', type: 'bytes4' },
    //         { name: 'inputParams', type: 'string[]' }
    //       ],
    //       [
    //         grantAddress,
    //         "0x9d888e86" as `0x${string}`, // rejectProposal(uint256)
    //         ["uint256 proposalId"]
    //       ]
    //     ),
    //     conditions: createConditions({
    //       allowedRole: roleId,
    //       votingPeriod: daysToBlocks(7, chainId),
    //       succeedAt: 51n,
    //       quorum: 50n
    //     })
    //   });
    // });

    //////////////////////////////////////////////////////////////////
    //                  ELECTORAL LAWS (27-32)                      //
    //////////////////////////////////////////////////////////////////

    // Law 27: Github to EVM
    lawInitData.push({
      nameDescription: "Github to EVM: Map your GitHub username to your EVM address.",
      targetLaw: getLawAddress("StringToAddress", chainId),
      config: "0x",
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE
      })
    });

    // Law 28: Github to Role
    const roleByGitCommitConfig = encodeAbiParameters(
      [
        { name: 'repo', type: 'string' },
        { name: 'paths', type: 'string[]' },
        { name: 'roleIds', type: 'uint256[]' },
        { name: 'subscriptionId', type: 'uint64' },
        { name: 'gasLimit', type: 'uint32' },
        { name: 'donID', type: 'bytes32' }
      ],
      [
        "7Cedars/powers",
        ["/gitbook", "/frontend", "/solidity"],
        [2n, 3n, 4n],
        0n, // Will need to be configured
        300_000,
        "0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000"
      ]
    );

    lawInitData.push({
      nameDescription: "Github to Role: Assign contributor roles based on GitHub commits (2=docs, 3=frontend, 4=protocol).",
      targetLaw: getLawAddress("RoleByGitCommit", chainId),
      config: roleByGitCommitConfig,
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE
      })
    });

    // Law 29: Fund Development
    // lawInitData.push({
    //   nameDescription: `Fund Development: Fund the protocol and get Funder role. Token: ${getMockAddress("Erc20TaxedMock", chainId)}`,
    //   targetLaw: getLawAddress("BuyAccess", chainId),
    //   config: encodeAbiParameters(
    //     [
    //       { name: 'erc20Token', type: 'address' },
    //       { name: 'tokensPerBlock', type: 'uint256' },
    //       { name: 'roleId', type: 'uint16' }
    //     ],
    //     [getMockAddress("Erc20TaxedMock", chainId), BigInt(2 * 1000), 1]
    //   ),
    //   conditions: createConditions({
    //     allowedRole: PUBLIC_ROLE
    //   })
    // });

    // Law 30: Apply for Membership
    lawInitData.push({
      nameDescription: "Apply for Membership: Get Member role if you're a Funder or Contributor.",
      targetLaw: getLawAddress("RoleByRoles", chainId),
      config: encodeAbiParameters(
        [
          { name: 'newRoleId', type: 'uint256' },
          { name: 'roleIdsNeeded', type: 'uint256[]' }
        ],
        [5n, [1n, 2n, 3n, 4n]]
      ),
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE
      })
    });

    // Law 31: Veto Role Revocation
    lawInitData.push({
      nameDescription: "Veto Role Revocation: Admin can veto member votes to revoke roles.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: encodeAbiParameters(
        [{ name: 'inputParams', type: 'string[]' }],
        [["address[] Accounts"]]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

    // Law 32: Remove Roles
    rolesArray.forEach(roleName => {
      lawInitData.push({
        nameDescription: `Remove ${roleName}: Members vote to remove accounts from ${roleName} role.`,
        targetLaw: getLawAddress("DirectDeselect", chainId),
        config: encodeAbiParameters(
          [{ name: 'roleId', type: 'uint256' }],
          [roles[roleName]]
        ),
        conditions: createConditions({
          allowedRole: 5n,
          votingPeriod: daysToBlocks(5, chainId),
          succeedAt: 51n,
          quorum: 5n,
          needNotFulfilled: 31n,
          delayExecution: daysToBlocks(5, chainId)
        })
      });
    });

    //////////////////////////////////////////////////////////////////
    //                CONSTITUTIONAL LAWS (38-40)                   //
    //////////////////////////////////////////////////////////////////

    const adoptLawPackageConfig = encodeAbiParameters(
      [{ name: 'inputParams', type: 'string[]' }],
      [["address[] laws", "bytes[] lawInitDatas"]]
    );

    // Law 38: Propose Law Package
    lawInitData.push({
      nameDescription: "Propose Law Package: Members vote to propose new laws.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: adoptLawPackageConfig,
      conditions: createConditions({
        allowedRole: 5n,
        votingPeriod: daysToBlocks(7, chainId),
        succeedAt: 51n,
        quorum: 50n
      })
    });

    // Law 39: Veto Law Package
    lawInitData.push({
      nameDescription: "Veto Law Package: Funders can veto proposed law packages.",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: adoptLawPackageConfig,
      conditions: createConditions({
        allowedRole: 1n,
        votingPeriod: daysToBlocks(3, chainId),
        succeedAt: 33n,
        quorum: 50n,
        needFulfilled: BigInt(lawInitData.length)
      })
    });

    // Law 40: Adopt Law Package
    lawInitData.push({
      nameDescription: "Adopt Law Package: Admin adopts new laws after proposal passes and isn't vetoed.",
      targetLaw: getLawAddress("AdoptLawPackage", chainId),
      config: "0x",
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: BigInt(lawInitData.length - 1),
        needNotFulfilled: BigInt(lawInitData.length)
      })
    });

    return lawInitData;
  },

  getMockContracts: (formData: Record<string, any>) => {
    return [
      {
        name: "DocsGrant",
        contractName: "Grant"
      },
      {
        name: "FrontendGrant",
        contractName: "Grant"
      },
      {
        name: "ProtocolGrant",
        contractName: "Grant"
      }
    ];
  }
};

