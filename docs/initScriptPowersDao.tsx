/**
 * Creates law initialization data for Powers DAO - the DAO that governs development of the Powers protocol. 
 * It builds on many of the laws deployed in previous examples, in addition to adding several new laws. 
 */
export function createPowersDaoLawInitData(powersAddress: `0x${string}`, formData: PowersDaoFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];
  const constants = getConstants(chainId);
  const subscriptionId = formData.chainlinkSubscriptionId ?? 0;
  const roles: { [key: string]: bigint } = {
    "Funders": 1n,
    "Documentation Contributors": 2n,
    "Frontend Contributors": 3n,
    "Protocol Contributors": 4n,
    "Members": 5n,
    "Grantees": 6n,
  };
  const rolesArray = Object.keys(roles);

  //////////////////////////////////////////////////////////////////
  //                       Initiation Law                         // 
  //////////////////////////////////////////////////////////////////

  // Law 1: Initial setup - Assign labels and mint tokens
  // Dynamically create role labels using the roles mapping
  const roleTargets = rolesArray.map(() => powersAddress);
  const roleValues = rolesArray.map(() => 0n);

  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns labels and mint tokens.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [...roleTargets, powersAddress], // targets: role targets + revoke law target
        [...roleValues, 0n], // values: role values + revoke law value
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
            args: [1n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE // anyone can execute labelling. 
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  ///// SETTING BUDGET /////
  const budgetConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["uint16 lawId", "address TokenAddress", "uint256 Budget"]]
  ); // In the Solidity version: abi.encode(inputParams)
  
  // Law 2:StatementOfIntent => Intent to adapt budget Existing Grant Program  -- role 5 (Members), subject to vote but low thresholds.  
  lawInitData.push({
    nameDescription: "Propose budget: Create a Statement of Intent for adapting the grants budget (law 5 = doc, 8 = frontend, 10 = protocol grants).",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: budgetConfig,
    conditions: createConditions({
      allowedRole: 5n,
      votingPeriod: daysToBlocks(7, chainId),
      succeedAt: 51n,
      quorum: 33n
    })
  });  

  // Law 3:StatementOfIntent => Veto a budget proposal  -- role 1 (Funders), subject to vote 50% ? .  
  // needFulfilled => law 2. 
  lawInitData.push({
    nameDescription: "Veto budget: Veto the proposal to adapt the grants budget (law 5 = doc, 8 = frontend, 10 = protocol grants).",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: budgetConfig,
    conditions: createConditions({
      allowedRole: 1n,
      votingPeriod: daysToBlocks(3, chainId),
      succeedAt: 66n,
      quorum: 50n,
      needFulfilled: BigInt(lawInitData.length)
    })
  });  

  // Law 4: Erc20Budget => adapt budget Existing Grant Program  -- Admin. 
  // needFulfilled   => law 2.
  // need NotCompleted   => law 3. 
  lawInitData.push({
    nameDescription: "Set budget: Set the budget for the grants (law 5 = doc, 8 = frontend, 10 = protocol grants).",
    targetLaw: getLawAddress("Erc20Budget", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needFulfilled: BigInt(lawInitData.length - 1),
      needNotFulfilled: BigInt(lawInitData.length)
    })
  });

  ///// GRANT PROGRAMS /////
  // setup for lats laws 5, X, Y, Z: StatementOfIntent => Propose a grant: Propose a grant for a grantee. 
  const proposalConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["string UriProposal", "address Grantee", "address TokenAddress", "uint256[] MilestoneDisbursements"]]
  ); 

  // law 5: StatementOfIntent => Veto a grant proposal: Veto a any type of grant proposal. 
  lawInitData.push({
    nameDescription: "Veto a grant proposal: Veto a grant proposal.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      votingPeriod: daysToBlocks(3, chainId),
      succeedAt: 66n,
      quorum: 25n, // 25% quorum. 
      allowedRole: 5n  // community members can veto a grant proposal, subject to a vote. 
    })
  });

  // law 6: StatementOfIntent => Request payout: A grantee can request a milestone disbursement this law is used for all types of grants. 
  lawInitData.push({
    nameDescription: "Request payout: A grantee can request a milestone disbursement.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: encodeAbiParameters(
      [
        { name: 'inputParams', type: 'string[]' },
      ],
      [["uint256 MilestoneBlock", "string SupportUri"]]
    ),
    conditions: createConditions({
      allowedRole: 6n, // Grantees
    })
  });

  // Grant roles mapping for documentation, frontend, and protocol contributors
  const grantRoles = [
    { roleId: 2n, roleName: "Documentation Contributors", grantType: "documentation" },
    { roleId: 3n, roleName: "Frontend Contributors", grantType: "frontend" },
    { roleId: 4n, roleName: "Protocol Contributors", grantType: "protocol" }
  ];

  // Create grant laws for each grant role (propose, allocate, end)
  grantRoles.forEach(({ roleId, roleName, grantType }) => {
    // Propose grant law
    lawInitData.push({
      nameDescription: `Propose a ${grantType} grant: Propose a grant for a grantee.`,
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: proposalConfig,
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE  // anyone can propose a grant. 
      })
    });

    // Allocate grant law
    const grantConditions = createEncodedConditions({
      allowedRole: roleId,
      needFulfilled: 6n
    });
    const grantConfig = encodeAbiParameters(
      [
        { name: 'grantLaw', type: 'address' },
        { name: 'grantRoleId', type: 'uint256' },
        { name: 'grantConditions', type: 'bytes' },
      ],
      [getLawAddress("Grant", chainId), 6n, grantConditions] // 6n = request payout. 
    ); 
    
    lawInitData.push({
      nameDescription: `${roleName} Grants: Allocate a grant for ${grantType} related work.`,
      targetLaw: getLawAddress("GrantProgram", chainId),
      config: grantConfig,
      conditions: createConditions({
        allowedRole: roleId,
        readStateFrom: 4n,
        quorum: 50n,
        succeedAt: 51n,
        votingPeriod: daysToBlocks(7, chainId),
        needFulfilled: BigInt(lawInitData.length), // a grant proposals needs to have been made.  
        needNotFulfilled: 5n // a grant proposal should not have been vetoed.  
      })
    }); 

    // End grant law
    lawInitData.push({
      nameDescription: `End a grant: End a ${grantType} grant .`,
      targetLaw: getLawAddress("EndGrant", chainId),
      config: "0x",
      conditions: createConditions({
        allowedRole: roleId,
        needFulfilled: BigInt(lawInitData.length), // a grant needs to have been created. Note: it is only possible to end a grant after the last milestone has been released.  
      })
    }); 
  }); 

  /// ADOPTING NEW LAWS /// 
  // law 16: StatementOfIntent => Intent to adopt new package of Laws. Subject to vote, role 5 (Members) high thresholds. 
  const adoptLawPackageConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["address[] laws", "bytes[] lawInitDatas"]]
  ); 
  lawInitData.push({
    nameDescription: "Intent to adopt new package of Laws: Intent to adopt a new package of laws.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: adoptLawPackageConfig,
    conditions: createConditions({
      allowedRole: 5n,
      votingPeriod: daysToBlocks(7, chainId),
      succeedAt: 51n,
      quorum: 50n
    })
  });  

  // law 17: StatementOfIntent => veto a package of Laws. Subject to vote, role 1 (Funders) Normal thresholds?  
  lawInitData.push({
    nameDescription: "Veto adopt new package of Laws: Veto the adoption of a new package of laws.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: adoptLawPackageConfig,
    conditions: createConditions({
      needFulfilled: BigInt(lawInitData.length),  // 14n
      allowedRole: 1n,
      votingPeriod: daysToBlocks(3, chainId),
      succeedAt: 33n,
      quorum: 50n
    })
  });  

  // law 18: AdoptLawPackage => Adopt a new package of laws. 
  // needFulfilled => law 13.
  // needNotFulfilled => law 14. 
  lawInitData.push({
    nameDescription: "Adopt a new package of laws: Adopt a new package of laws.",
    targetLaw: getLawAddress("AdoptLawPackage", chainId),
    config: "0x",
    conditions: createConditions({
      allowedRole: ADMIN_ROLE, // the admin in the end has the power to accept new laws. 
      needFulfilled: BigInt(lawInitData.length - 1), // 14n,
      needNotFulfilled: BigInt(lawInitData.length), // 15n
    })
  });  

  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 19: StringToAddress => Assign a github profile name to an EVM address. -- Public.
  // assigns a github profile name to the caller address.  
  lawInitData.push({
    nameDescription: "Github to EVM: Assign a github profile name to your EVM address.",
    targetLaw: getLawAddress("StringToAddress", chainId),
    config: "0x",
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // law 20: RoleByGitCommit => Assign (or revoke!) a role to an EVM address based on their github commit history during last 90 days. -- Public. 
  // reads from Law 17. 
  let roleByGitCommitConfig = encodeAbiParameters(
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
      BigInt(subscriptionId),
      300_000, // this is max gaslimit that chainlink allows. 
      "0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000"
    ]
  ); 
  lawInitData.push({
    nameDescription: "Github to Role: Assign a role to an EVM address based on their github commit history. (2 = docs, 3 = frontend, 4 = protocol)",
    targetLaw: getLawAddress("RoleByGitCommit", chainId),
    config: roleByGitCommitConfig,
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE,
      readStateFrom: BigInt(lawInitData.length)
    })
  });

  // law 21: RoleByFunding => Assigns (or revokes!) a role to an EVM address based on their funding history during last 90 days. -- Public. 
  // TBI. 
  // Note: the governance flow will work, but funders just do not have veto power yet on how their funds are spent. 
  //("address Erc20Token", "uint256 TokensPerBlock", "uint16 RoleId");
  lawInitData.push({
    nameDescription: `Fund development: Fund development of the protocol and assign a funder role in return. You get 1 day access per 1 ERC20 tokens funded. You can get tokens at ${getMockAddress("Erc20TaxedMock", chainId)}`,
    targetLaw: getLawAddress("BuyAccess", chainId),
    config: encodeAbiParameters(
      [
        { name: 'erc20Token', type: 'address' },
        { name: 'tokensPerBlock', type: 'uint256' },
        { name: 'roleId', type: 'uint16' }
      ],
      [getMockAddress("Erc20TaxedMock", chainId), BigInt(2 * 1000), 1] // lets assume the ERC20 value is 1 dollar. 10 dollar per 1 day access. 1 = funder. 
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE  
    })
  });

  // law 22: RoleByRoles => Assigns (or revokes!) a role on the condition that they have other roles in the organization. 
  let roleByRolesConfig = encodeAbiParameters(
    [
      { name: 'newRoleId', type: 'uint256' },
      { name: 'roleIdsNeeded', type: 'uint256[]' },
    ],
    [5n, [1n, 2n, 3n, 4n]] // 5n = members, [1n, 2n, 3n, 4n] = funder, docs, frontend, protocol. 
  ); 
  lawInitData.push({
    nameDescription: "Apply for Membership: Assign a generic membership role to any account that is a funder or has a contributor role.",
    targetLaw: getLawAddress("RoleByRoles", chainId),
    config: roleByRolesConfig,
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // law 23: veto roles revokes 
  const revokeRolesConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["address[] Accounts"]]
  ); 
  lawInitData.push({
    nameDescription: "Veto roles revokes: Veto the revocation of roles.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: revokeRolesConfig,
    conditions: createConditions({
      allowedRole: 0n  // The admin can veto a revoking of roles, subject to a vote. 
    })
  });

  // laws 24-28: revoke roles for each role using dynamic mapping
  rolesArray.forEach(roleName => {
    lawInitData.push({
      nameDescription: `Remove ${roleName}: Remove one or more accounts from ${roleName} role.`,
      targetLaw: getLawAddress("DirectDeselect", chainId),
      config: encodeAbiParameters(
        [
          { name: 'roleId', type: 'uint256' },
        ],
        [roles[roleName]] // Use the role ID from the roles mapping
      ),
      conditions: createConditions({
        votingPeriod: daysToBlocks(5, chainId),
        succeedAt: 51n,
        quorum: 5n, // 5% quorum. 
        needNotFulfilled: 23n, // need not to have vetoed a revoking of roles. 
        delayExecution: daysToBlocks(5, chainId),
        allowedRole: 5n  // community members can revoke roles, subject to a vote. 
      })
    });
  });

  return lawInitData;
}
