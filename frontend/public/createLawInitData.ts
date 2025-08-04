import { powersAbi, erc20TaxedAbi, erc20VotesAbi } from "@/context/abi";
import { getConstants } from "@/context/constants";
import { OrganizationType } from "@/context/types";
import { encodeAbiParameters, encodeFunctionData } from "viem";

export interface LawConditions {
  allowedRole: bigint;
  needCompleted: bigint;
  delayExecution: bigint;
  throttleExecution: bigint;
  readStateFrom: bigint;
  votingPeriod: bigint;
  quorum: bigint;
  succeedAt: bigint;
  needNotCompleted: bigint;
}

export interface CreateConditionsParams {
  allowedRole?: bigint;
  needCompleted?: bigint;
  delayExecution?: bigint;
  throttleExecution?: bigint;
  readStateFrom?: bigint;
  votingPeriod?: bigint;
  quorum?: bigint;
  succeedAt?: bigint;
  needNotCompleted?: bigint;
}

export interface LawInitData {
  nameDescription: string;
  targetLaw: `0x${string}`;
  config: `0x${string}`;
  conditions: LawConditions;
}

export interface Powers101FormData { }

export interface CrossChainGovernanceFormData {
  snapshotSpace?: string;
  governorAddress?: `0x${string}`;
  chainlinkSubscriptionId: number;
}

export interface GrantsManagerFormData {
  parentDaoAddress?: `0x${string}`; 
}

export interface ManagedUpgradesFormData { }

export interface SingleUpgradeFormData { }

export interface SplitGovernanceFormData { }



// Type for deployment returns data
export interface DeploymentReturns {
  addresses: {
    internal_type: string;
    value: string; // JSON string array of addresses
  };
  names: {
    internal_type: string;
    value: string; // JSON string array of names
  };
}

/**
 * Fetches a law address by its name and chain ID
 * @param lawName - The name of the law to find
 * @param chainId - The chain ID to search in
 * @returns The address of the law (undefined if not found)
 */
const getLawAddress = (lawName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.LAW_ADDRESSES[constants.LAW_NAMES.indexOf(lawName)];
  if (!address) {
    throw new Error(`Law address not found for: ${lawName}`);
  }
  return address;
};

/**
 * Fetches a law address by its name and chain ID
 * @param lawName - The name of the law to find
 * @param chainId - The chain ID to search in
 * @returns The address of the law (undefined if not found)
 */
const getMockAddress = (mockName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.MOCK_ADDRESSES[constants.MOCK_NAMES.indexOf(mockName)];
  if (!address) {
    throw new Error(`Mock address not found for: ${mockName}`);
  }
  return address;
};

const createConditions = (params: CreateConditionsParams): LawConditions => ({
  allowedRole: params.allowedRole ?? 0n, 
  needCompleted: params.needCompleted ?? 0n, 
  delayExecution: params.delayExecution ?? 0n, 
  throttleExecution: params.throttleExecution ?? 0n, 
  readStateFrom: params.readStateFrom ?? 0n, 
  votingPeriod: params.votingPeriod ?? 0n, 
  quorum: params.quorum ?? 0n, 
  succeedAt: params.succeedAt ?? 0n, 
  needNotCompleted: params.needNotCompleted ?? 0n
});

const createEncodedConditions = (params: CreateConditionsParams): `0x${string}` => encodeAbiParameters(
  [ 
    { name: 'allowedRole', type: 'uint256' },
    { name: 'needCompleted', type: 'uint256' },
    { name: 'delayExecution', type: 'uint256' },
    { name: 'throttleExecution', type: 'uint256' },
    { name: 'readStateFrom', type: 'uint256' },
    { name: 'votingPeriod', type: 'uint256' },
    { name: 'quorum', type: 'uint256' },
    { name: 'succeedAt', type: 'uint256' },
    { name: 'needNotCompleted', type: 'uint256' }
  ],
  [
    params.allowedRole ?? 0n, 
    params.needCompleted ?? 0n,
    params.delayExecution ?? 0n,
    params.throttleExecution ?? 0n,
    params.readStateFrom ?? 0n,
    params.votingPeriod ?? 0n,
    params.quorum ?? 0n,
    params.succeedAt ?? 0n,
    params.needNotCompleted ?? 0n
  ]
);

const minutesToBlocks = (minutes: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(minutes *  constants.BLOCKS_PER_HOUR / 60));
};

const ADMIN_ROLE = 0n;
const PUBLIC_ROLE = 115792089237316195423570985008687907853269984665640564039457584007913129639935n;

/**
 * Creates law initialization data for Powers 101 DAO
 * Based on the createConstitution function from DeployPowers101.s.sol
 */
export function createPowers101LawInitData(powersAddress: `0x${string}`, formData: Powers101FormData, chainId: number): LawInitData[] {
  
  const lawInitData: LawInitData[] = [];
  
  // Law 1: Initial setup
  // This law sets up initial role assignments for the DAO & role labelling
  // Only the admin can use this law
  // In the Solidity version: abi.encode(targetsRoles, valuesRoles, calldatasRoles)
  // This would need the actual mock addresses and powers address, but for now using placeholders
  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns labels to laws and mints tokens. Press the refresh button to see the new labels.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress, powersAddress, getMockAddress("Erc20TaxedMock", chainId), getMockAddress("Erc20VotesMock", chainId), powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n], // values
        [
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Members"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",  
            args: [2n, "Delegates"]
          }),
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // faucet 
          }),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [2500000000000000000n] // mint 2.5 votes to the admin
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 2: Statement of Intent
  // This law allows proposing changes to core values of the DAO
  // Only community members can use this law. It is subject to a vote.
  const statementOfIntentConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["address[] Targets", "uint256[] Values", "bytes[] Calldatas"]]
  ); // In the Solidity version: abi.encode(inputParams)
  lawInitData.push({
    nameDescription: "Statement of Intent: Create an SoI for an action that can later be executed by Delegates.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: statementOfIntentConfig,
    conditions: createConditions({
      allowedRole: 1n,
      votingPeriod: minutesToBlocks(5, chainId),
      succeedAt: 51n,
      quorum: 20n
    })
  });

  // Law 3: Veto an action
  // This law allows a proposed action to be vetoed
  // Only the admin can use this law
  lawInitData.push({
    nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: statementOfIntentConfig,
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needCompleted: 2n // references the Statement of Intent law
    })
  });

  // Law 4: Execute an action
  // This law allows executing any action with voting requirements
  // Only role 2 can use this law
  lawInitData.push({
    nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
    targetLaw: getLawAddress("OpenAction", chainId),
    config: "0x", // empty config, an open action takes address[], uint256[], bytes[] as input
    conditions: createConditions({
      allowedRole: 2n,
      quorum: 50n,
      succeedAt: 77n,
      votingPeriod: minutesToBlocks(5, chainId),
      needCompleted: 2n,
      needNotCompleted: 3n,
      delayExecution: minutesToBlocks(3, chainId)
    })
  });


  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////
  // Law 5: Nominate me for delegate
  // This law allows accounts to self-nominate for any role
  // It can be used by community members
  lawInitData.push({
    nameDescription: "Nominate oneself for any role.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: 1n
    })
  });

  // law 6: Call election for delegate role. 
  lawInitData.push({
    nameDescription: "Call delegate election!: Please press the refresh button after the election has been deployed.",
    targetLaw: getLawAddress("ElectionStart", chainId),
    config: encodeAbiParameters(
      [
        { name: 'ElectionList', type: 'address' },
        { name: 'ElectionTally', type: 'address' },
        { name: 'roleId', type: 'uint16' },
        { name: 'maxToElect', type: 'uint32' }
      ],
      [ getLawAddress("ElectionList", chainId), 
        getLawAddress("ElectionTally", chainId),
        2, // roleId for delegates
        5 // maxToElect
      ]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      readStateFrom: 5n
    })
  });


  // Law 7: Self select as community member 
  // This law enables anyone to select themselves as a community member
  // Anyone can use this law
  lawInitData.push({
    nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
    targetLaw: getLawAddress("SelfSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint256' }
      ],
      [1n] // roleId to be elected
    ),
    conditions: createConditions({
      throttleExecution: 25n,
      allowedRole: PUBLIC_ROLE
    })
  });

  return lawInitData;
}

/**
 * Creates law initialization data for Cross Chain Governance
 * Based on the createConstitution function from DeployBeyondPowers.s.sol
 */
export function createCrossChainGovernanceLawInitData(powersAddress: `0x${string}`, formData: CrossChainGovernanceFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];
  const constants = getConstants(chainId);
  const subscriptionId = formData.chainlinkSubscriptionId ?? 0;

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 1: Check if proposal exists
  // This law checks if a proposal and choice exists at the Snapshot space
  // Only executioners (role 1) can use this law
  lawInitData.push({
    nameDescription: `Does proposal exist?: Check if a proposal and choice exists at the ${formData.snapshotSpace ?? "hvax.eth"} Snapshot space.`,
    targetLaw: getLawAddress("SnapToGov_CheckSnapExists", chainId),
    config: encodeAbiParameters(
      [
        { name: 'spaceId', type: 'string' },
        { name: 'subscriptionId', type: 'uint64' },
        { name: 'gasLimit', type: 'uint32' },
        { name: 'donID', type: 'bytes32' }
      ],
      [
        formData.snapshotSpace ?? "hvax.eth",
        BigInt(subscriptionId),
        constants.CHAINLINK_GAS_LIMIT,
        constants.CHAINLINK_DON_ID
      ]
    ),
    conditions: createConditions({
      allowedRole: 1n
    })
  });

  // Law 2: Check if choice passed
  // This law checks if a proposal and choice passed at the Snapshot space
  // Only executioners (role 1) can use this law, requires Law 1 to be completed
  lawInitData.push({
    nameDescription: `Did choice pass?: Check if a proposal and choice passed at the ${formData.snapshotSpace ?? "hvax.eth"} Snapshot space.`,
    targetLaw: getLawAddress("SnapToGov_CheckSnapPassed", chainId),
    config: encodeAbiParameters(
      [
        { name: 'spaceId', type: 'string' },
        { name: 'subscriptionId', type: 'uint64' },
        { name: 'gasLimit', type: 'uint32' },
        { name: 'donID', type: 'bytes32' }
      ],
      [
        formData.snapshotSpace ?? "hvax.eth",
        BigInt(subscriptionId),
        constants.CHAINLINK_GAS_LIMIT,
        constants.CHAINLINK_DON_ID
      ]
    ),  
    conditions: createConditions({
      allowedRole: 1n,
      needCompleted: 1n
    })
  });

  // Law 3: Create Governor.sol proposal
  // This law creates a new Governor.sol proposal using Erc20VotesMock as votes
  // Only executioners (role 1) can use this law, requires Law 2 to be completed
  lawInitData.push({
    nameDescription: `Create Governor.sol proposal: Create a new Governor.sol proposal using ${formData.governorAddress ? formData.governorAddress : getMockAddress("Erc20VotesMock", chainId)} as votes.`,
    targetLaw: getLawAddress("SnapToGov_CreateGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'governorAddress', type: 'address' }
      ],
      [formData.governorAddress && formData.governorAddress?.length > 0 ? formData.governorAddress : getMockAddress("GovernorMock", chainId)]
    ),
    conditions: createConditions({
      allowedRole: 1n,
      needCompleted: 2n
    })
  });

  // Law 4: Cancel Governor.sol proposal
  // This law allows canceling a Governor.sol proposal
  // Only Security Council members (role 2) can use this law, requires Law 3 to be completed
  lawInitData.push({
    nameDescription: `Cancel Governor.sol proposal: Cancel a Governor.sol proposal using ${formData.governorAddress ? formData.governorAddress : getMockAddress("GovernorMock", chainId)} as votes.`,
    targetLaw: getLawAddress("SnapToGov_CancelGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'governorAddress', type: 'address' }
      ],
      [ formData.governorAddress && formData.governorAddress?.length > 0 ? formData.governorAddress : getMockAddress("GovernorMock", chainId)]
    ),
    conditions: createConditions({
      allowedRole: 2n,
      needCompleted: 3n,
      quorum: 77n,
      votingPeriod: minutesToBlocks(5, chainId),
      succeedAt: 51n
    })
  });

  // Law 5: Execute Governor.sol proposal
  // This law allows executing a Governor.sol proposal
  // Only executioners (role 1) can use this law, requires Law 3 to be completed
  lawInitData.push({
    nameDescription: `Execute Governor.sol proposal: Execute a Governor.sol proposal using ${formData.governorAddress ? formData.governorAddress : getMockAddress("GovernorMock", chainId)} as governor contract.`,
    targetLaw: getLawAddress("SnapToGov_ExecuteGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'governorAddress', type: 'address' }
      ],
      [formData.governorAddress && formData.governorAddress?.length > 0 ? formData.governorAddress : getMockAddress("GovernorMock", chainId)]
    ),
    conditions: createConditions({
      allowedRole: 1n,
      needCompleted: 3n,
      needNotCompleted: 4n,
      quorum: 10n,
      votingPeriod: minutesToBlocks(5, chainId),
      succeedAt: 10n,
      delayExecution: minutesToBlocks(10, chainId)
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 6: Nominate oneself for Executioner role
  // This law allows anyone to nominate themselves for the Executives role
  // Anyone can use this law
  lawInitData.push({
    nameDescription: "Nominate oneself: Nominate oneself for the Executives role.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // Law 7: Elect executives using delegated tokens
  // This law enables electing executives using delegated tokens
  // Anyone can use this law, reads state from Law 6
  lawInitData.push({
    nameDescription: `Elect executives: Elect executives using ${formData.governorAddress ? formData.governorAddress : getMockAddress("Erc20VotesMock", chainId)} as delegated tokens.`,
    targetLaw: getLawAddress("DelegateSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' },
        { name: 'maxRoleHolders', type: 'uint256' },
        { name: 'roleId', type: 'uint256' }
      ],
      [getMockAddress("Erc20VotesMock", chainId), 50n, 1n]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE,
      readStateFrom: 6n
    })
  });

  // Law 8: Select Security Council members
  // This law allows the admin to select members for the Security Council
  // Only admin (role 0) can use this law
  lawInitData.push({
    nameDescription: "Select Security Council: Select members for the Security Council.",
    targetLaw: getLawAddress("DirectSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint256' }
      ],
      [2n] // roleId for Security Council
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Initiation Law                         // 
  //////////////////////////////////////////////////////////////////

  // Law 9: Initial setup - Assign role labels
  // This law assigns labels to roles and can only be executed once
  // Anyone can execute this law initially
  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns labels to laws. Press the refresh button to see the new labels.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress, 
          powersAddress, 
          getMockAddress("Erc20TaxedMock", chainId), 
          getMockAddress("Erc20VotesMock", chainId), 
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n], // values
        [
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Executives"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [2n, "Security Council"]
          }),
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // faucet 
          }),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [2500000000000000000n] // mint 2.5 votes to the admin
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [9n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  return lawInitData;
}

export function createSplitGovernanceLawInitData(powersAddress: `0x${string}`, formData: SplitGovernanceFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];

  //////////////////////////////////////////////////////////////////
  //                       Initiation Law                         // 
  //////////////////////////////////////////////////////////////////
  // Law 1: Initial setup - Assign role labels
  // This law assigns labels to roles and can only be executed once
  // Anyone can execute this law initially
  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns role labels. Do not forget to press the refresh button after executing this law.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress,
          powersAddress,
          powersAddress,
          getMockAddress("Erc20TaxedMock", chainId),
          getMockAddress("Erc20VotesMock", chainId),
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n, 0n], // values
        [
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Selectors"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [2n, "Security Council"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [3n, "Executives"]
          }),
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // faucet 
          }),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [2500000000000000000n] // mint 2.5 votes to the admin
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////
  // create the input layout for the proposals that can be created. 
  const proposalConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["address[] Targets", "uint256[] Values", "bytes[] Calldatas"]]
  ); 

  // Law 2: Create a proposal
  // This law allows creating a proposal
  // Anyone can use this law
  lawInitData.push({
    nameDescription: "Create proposal: Any proposal is possible, the law takes targets[], values[] and calldatas[] as input.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // SELECT PATH 1 OR 2 OR 3 
  // law 3: assign proposal to governance path 1: low risk, repetitive tasks
  lawInitData.push({
    nameDescription: "Assign to path A: Assign a proposal to path A.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 1n, // SELECTORS
      needCompleted: 2n, // need to have created a proposal
      votingPeriod: 100n, // 100 blocks
      quorum: 50n, // 50% quorum
      succeedAt: 50n // 50% success threshold
    })
  }); 

  // law 4: assign proposal to governance path 2: mid risk
  lawInitData.push({
    nameDescription: "Assign to path B: Assign a proposal to path B.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 1n, // SELECTORS
      needCompleted: 2n, // need 2 to have created a proposal
      votingPeriod: 100n, // 100 blocks
      quorum: 50n, // 50% quorum
      succeedAt: 50n // 50% success threshold
    })
  });

  // law 5: assign proposal to governance path 3: high risk, non-repetitive tasks
  lawInitData.push({
    nameDescription: "Assign to path C: Assign a proposal to path C.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 1n, // SELECTORS
      needCompleted: 2n, // need 2 to have created a proposal
      votingPeriod: 100n, // 100 blocks
      quorum: 50n, // 50% quorum
      succeedAt: 50n // 50% success threshold
    })
  });

  // PATH 1 
  // law 6: execute proposal: 1 member of the executive council sufficient. - no vote. 
  lawInitData.push({
    nameDescription: "Execute proposal: Execute a proposal assigned to path A.",
    targetLaw: getLawAddress("OpenAction", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 3n, // EXECUTIVES
      needCompleted: 3n // need to have created a proposal and assigned to path 1
      // NOTE: no vote. Each and every executive can execute the proposal. 
    })
  });

  // PATH 2
  // law 7: veto proposal: security council votes on veto. 
  lawInitData.push({
    nameDescription: "Veto proposal: Veto a proposal assigned to path B.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 2n, // SECURITY COUNCIL
      needCompleted: 4n, // need to have created a proposal and assigned to path 2
      votingPeriod: 100n, // 100 blocks
      quorum: 70n, // 70% quorum: high
      succeedAt: 70n // 70% success threshold: high
    })
  });
  
  // law 8: execute proposal: executive council votes on execution. 
  lawInitData.push({
    nameDescription: "Execute proposal: Execute a proposal assigned to path B.",
    targetLaw: getLawAddress("OpenAction", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 3n, // EXECUTIVES
      needCompleted: 4n, // need to have created a proposal and assigned to path 2
      needNotCompleted: 7n, // need to have vetoed the proposal
      delayExecution: minutesToBlocks(10, chainId), // delay execution by 10 minutes
      // NOTE: no vote. Each and every executive can execute the proposal. 
    })
  });

  // PATH 3 
  // law 9: executive council votes on passing proposal 
  lawInitData.push({
    nameDescription: "Pass proposal: Pass a proposal assigned to path C.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 3n, // EXECUTIVES
      needCompleted: 5n, // need to have created a proposal and assigned to path 3
      votingPeriod: 100n, // 100 blocks
      quorum: 30n, // 30% quorum: low
      succeedAt: 51n // 51% success threshold: low
    })
  }); 

  // law 10: security council votes on execution. 
  lawInitData.push({
    nameDescription: "Execute proposal: Execute a proposal assigned to path C.",
    targetLaw: getLawAddress("OpenAction", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 2n, // SECURITY COUNCIL
      needCompleted: 9n, 
      votingPeriod: 100n, // 100 blocks
      quorum: 30n, // 30% quorum: low
      succeedAt: 51n // 51% success threshold: low
    })
  });

  
  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////

  // law 11 nominateMe for selectors council.
  lawInitData.push({
    nameDescription: "Nominate oneself: Nominate oneself for the Selectors role.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // law 12: token voting to elect selectors council. -- no distinct elections. Vote can happen at any time. 
  lawInitData.push({
    nameDescription: `Elect selectors council: Use the ERC20Votes governance token at ${getMockAddress("Erc20VotesMock", chainId)} to elect selectors council.`,
    targetLaw: getLawAddress("DelegateSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' },
        { name: 'maxRoleHolders', type: 'uint256' },
        { name: 'roleId', type: 'uint256' }
      ],
      [getMockAddress("Erc20VotesMock", chainId), 5n, 1n]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE,
      readStateFrom: 11n
    })
  });

  // law 13 nominateMe for executive council. 
  lawInitData.push({
    nameDescription: "Nominate oneself: Nominate oneself for the Executives role.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // law 14: token voting to elect executive council. -- no distinct elections. Vote can happen at any time. 
  lawInitData.push({
    nameDescription: `Elect executives council: Use the ERC20Votes governance token at ${getMockAddress("Erc20VotesMock", chainId)} to elect executives council.`,
    targetLaw: getLawAddress("DelegateSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' },
        { name: 'maxRoleHolders', type: 'uint256' },
        { name: 'roleId', type: 'uint256' }
      ],
      [getMockAddress("Erc20VotesMock", chainId), 12n, 3n]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE,
      readStateFrom: 13n
    })
  });


  // // law 15: Admin (de)selects members of the security council. 
  lawInitData.push({
    nameDescription: "Admin (de)selects members of the security council: Admin (de)selects members of the security council.",
    targetLaw: getLawAddress("DirectSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint256' }
      ],
      [2n]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  return lawInitData;
}

/**
 * Creates law initialization data for Managed Grants
 * Includes grant distribution and management laws
 * The laws here are still copy-paste from the law split governance example. 
 * TODO: refactor this to use the new laws. 
 */
export function createGrantsManagerLawInitData(powersAddress: `0x${string}`, formData: GrantsManagerFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];

  

  //////////////////////////////////////////////////////////////////
  //                       Initiation Law                         // 
  //////////////////////////////////////////////////////////////////
  // Law 1: Initial setup - Assign role labels
  // This law assigns labels to roles and can only be executed once
  // Anyone can execute this law initially
  // TODO: add minting of tokens to the program. 
  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns role labels and mints tokens to the program. This law can only be executed once. Do not forget to press the refresh button after executing this law.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          getMockAddress("Erc20TaxedMock", chainId),
          powersAddress,
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n], // values
        [
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Scope Assessors"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [2n, "Technical Assessors"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [3n, "Financial Assessors"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [4n, "Grant Imburser"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [5n, "Judges"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [6n, "Grantees"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [7n, "Parent DAO"]
          }),
          /// TODO 
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // disburses 1 ETH in tokens. 
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "assignRole",
            args: [7n, formData.parentDaoAddress || getMockAddress("GovernorMock", chainId)] // assign parent DAO role as admin
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////
  // create the input layout for the proposals that can be created. 
  const proposalConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["string uriProposal", "address Grantee", "address Token", "uint256[] milestoneDisbursements", "uint256 PrevActionId"]]
  ); 

  const complaintConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' },
    ],
    [["uint256 ActionId", "bool Flag"]]
  ); 

  const nStrikesConfig = encodeAbiParameters(
    [
      { name: 'numberStrikes', type: 'uint256' },
      { name: 'roleIds', type: 'uint256[]' }
    ],
    [3n, [1n, 2n, 3n, 4n]] // always 3 strikes. But the roleId can be changed. 
  ); 

  const grantConfig = encodeAbiParameters(
    [
      { name: 'grantLaw', type: 'address' },
      { name: 'grantConditions', type: 'bytes' }
    ],
    [ 
      getLawAddress("Grant", chainId), 
      createEncodedConditions({
        allowedRole: 4n,
        needCompleted: 8n // Grantee needs to have created a proposal for payout. 
      })
    ]
  ); 

  // Law 2: Create a proposal
  // This law allows creating a proposal
  // Anyone can use this law
  lawInitData.push({
    nameDescription: "Create grant proposal: Anyone can make a grant proposal.",
    targetLaw: getLawAddress("GrantProposal", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE,
      readStateFrom: 9n // read state from the complaint law
    })
  });

  // Law 3: Assess a proposal on scope 
  lawInitData.push({
    nameDescription: "Scope Assessment: A scope assessor can assess a proposal on scope. If ok-ed, the action is executed and send to the technical assessment.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 1n, // Scope Assessors
      needCompleted: 2n // need to have created a proposal
    })
  });

  // Law 4: Assess a proposal on technical quality
  lawInitData.push({
    nameDescription: "Technical Assessment: A technical assessor can assess a proposal on technical quality. If ok-ed, the action is executed and send to the financial assessment.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 2n, // Technical Assessors
      needCompleted: 3n // need to have created a proposal
    })
  });

  // Law 5: Assess a proposal on financial viability
  lawInitData.push({
    nameDescription: "Financial Assessment: A financial assessor can assess a proposal on financial viability. If ok-ed, the action is executed and send to the grant assignment.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: proposalConfig,
    conditions: createConditions({
      allowedRole: 3n, // Financial Assessors
      needCompleted: 4n // need to have created a proposal
    })
  });

  // Law 6: Assign a grant
  lawInitData.push({
    nameDescription: "Assign a grant: A grant imburser can assign a grant to a successful proposal. This also assigns a grantee role to the original proposer. Do not forget to press the refresh button after executing this law.",
    targetLaw: getLawAddress("StartGrant", chainId),
    config: grantConfig,
    conditions: createConditions({
      allowedRole: 4n, // Grant Imburser
      needCompleted: 5n // all assessments need to be completed. 
    })
  });

  // Law 7: End a grant
  lawInitData.push({
    nameDescription: "End a grant: A grant imburser can end a grant. This is only possible after the final milestone of the grant has been disbursed. Do not forget to press the refresh button after executing this law.",
    targetLaw: getLawAddress("EndGrant", chainId),
    config: grantConfig,
    conditions: createConditions({
      allowedRole: 4n, // Grant Imburser
      needCompleted: 6n // all assessments need to be completed. 
    })
  });

  // Law 8: Request a milestone disbursement
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

  // Law 9: Log a complaint about grant assessment
  lawInitData.push({
    nameDescription: "Log a complaint about grant assessment: An applicant can log a complaint about a grant assessment. It has to be done by the applicant themselves.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: complaintConfig,
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE 
    })
  });

  // Law 10: Judge a complaint about grant assessment
  lawInitData.push({
    nameDescription: "Judge a complaint: A judge can assess a complaint about any action taken in this organisation. In case the complaint is about a proposal assessment and if it is upheld, a proposal can be resubmitted for assessment.",
    targetLaw: getLawAddress("FlagActions", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: 5n, // Judges
      needCompleted: 9n // need to have created a complaint
    })
  });

  // Law 11: NStrikesYourOut
  lawInitData.push({
    nameDescription: "Three strikes your out: If any assessor has three complaints upheld against them, they can be removed from the organization.",
    targetLaw: getLawAddress("NStrikesYourOut", chainId),
    config: nStrikesConfig, 
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE, // anyone is allowed to execute the law. 
      readStateFrom: 10n // Judges
    })
  });

  
  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 12: Assign any account to any role. 
  // Only previous DAO (role 3) can use this law
  lawInitData.push({
    nameDescription: "Assign accounts: The parent DAO can assign any account to any role. (1 = scope assessors, 2 = technical assessors, 3 = financial assessors, 4 = grant imburser, 5 = judges, 6 = grantees, 7 = parent DAO)",
    targetLaw: getLawAddress("BespokeAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'target', type: 'address' },
        { name: 'functionSelector', type: 'bytes4' },
        { name: 'inputParams', type: 'string[]' }
      ],
        [
          powersAddress,
          encodeFunctionData({
            abi: powersAbi,
            functionName: "assignRole",
            args: [0n, "0x0000000000000000000000000000000000000000"] // placeholder argument, we only need the selector
          }).slice(0, 10) as `0x${string}`, // Get just the 4-byte selector (0x + 8 hex chars)
          ["uint16 RoleId", "address Account"]
        ]
    ),
    conditions: createConditions({
      allowedRole: 7n, // Parent DAO
    })
  });

  return lawInitData;
}

/**
 * Creates law initialization data for Managed Grants
 * Includes grant distribution and management laws
 * The laws here are still copy-paste from the law split governance example. 
 * TODO: refactor this to use the new laws. 
 */
export function createPackagedUpgradesLawInitData(powersAddress: `0x${string}`, formData: ManagedUpgradesFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////
  // Law 1: option A: Powers 101 executive path. 
  const statementOfIntentConfig = encodeAbiParameters(
      [
        { name: 'inputParams', type: 'string[]' },
      ],
      [["address[] Targets", "uint256[] Values", "bytes[] Calldatas"]]
  ); // In the Solidity version: abi.encode(inputParams)
  
  lawInitData.push({
    nameDescription: "Option A: Add a Powers101 executive path. IMPORTANT, press the Refresh button after law has been executed.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          getMockAddress("Erc20TaxedMock", chainId),
          getMockAddress("Erc20VotesMock", chainId),
          powersAddress,
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n], // values
        [
          // optional law 9: create an SoI for an action that can later be executed by Delegates. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Statement of Intent: Create an SoI for an action that can later be executed by Delegates.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 1n,
                votingPeriod: minutesToBlocks(5, chainId),
                succeedAt: 51n, 
                quorum: 20n
              })
            }]
          }),
          // optional law 10: veto an action that has been proposed by the community. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: ADMIN_ROLE,
                needCompleted: 9n // references the Statement of Intent law
              })
            }]
          }),
          // optional law 11: execute an action that has been proposed by the community. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
              targetLaw: getLawAddress("OpenAction", chainId),
              config: "0x", // empty config, an open action takes address[], uint256[], bytes[] as input
              conditions: createConditions({
                allowedRole: 2n,
                quorum: 50n,
                succeedAt: 77n,
                votingPeriod: minutesToBlocks(5, chainId),
                needCompleted: 9n,
                needNotCompleted: 10n,
                delayExecution: minutesToBlocks(3, chainId)
              })
            }]
          }),
          // assign labels to roles. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Members"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [2n, "Delegates"]
          }), 
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // faucet 
          }),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [2500000000000000000n] // mint 2.5 votes to the admin
          }),
          // delete laws 1 & 2 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [2n]
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // Law 2: option B: Split Governance executive path. 
  lawInitData.push({
    nameDescription: "Option B: Add a Split Governance executive path. IMPORTANT, press the Refresh button after law has been executed.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress,
          getMockAddress("Erc20TaxedMock", chainId),
          getMockAddress("Erc20VotesMock", chainId),
          powersAddress,
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n], // values
        [
          // optional law 9: create an SoI for an action. This action can be anything. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Create proposal: Create a proposal.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: PUBLIC_ROLE
              })
            }]
          }),
          // optional law 10: assign proposal to path A
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Assign to path A: Assign a proposal to path A.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 1n, // SELECTORS
                needCompleted: 9n, // need to have created a proposal
                votingPeriod: 100n, // 100 blocks
                quorum: 50n, // 50% quorum
                succeedAt: 50n // 50% success threshold
              })
            }]
          }),
          // optional law 11: assign proposal to path B
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Assign to path B: Assign a proposal to path B.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 1n, // SELECTORS
                needCompleted: 9n, // need to have created a proposal
                votingPeriod: 100n, // 100 blocks
                quorum: 50n, // 50% quorum
                succeedAt: 50n // 50% success threshold
              })
            }]
          }),
          // optional law 12: assign proposal to path C
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Assign to path C: Assign a proposal to path C.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 1n, // SELECTORS
                needCompleted: 9n, // need to have created a proposal
                votingPeriod: 100n, // 100 blocks
                quorum: 50n, // 50% quorum
                succeedAt: 50n // 50% success threshold
              })
            }]
          }),
          // optional law 13: execute an action assigned to path A. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Execute proposal: Execute a proposal assigned to path A.",
              targetLaw: getLawAddress("OpenAction", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 3n, // EXECUTIVES
                needCompleted: 10n // need to have created a proposal and assigned to path 1
                // NOTE: no vote. Each and every executive can execute the proposal. 
              })
            }]
          }),
          // optional law 14: veto an action that has been assigned to path B. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Veto proposal: Veto a proposal assigned to path B.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 2n, // SECURITY COUNCIL
                needCompleted: 11n, // need to have created a proposal and assigned to path 2
                votingPeriod: 100n, // 100 blocks
                quorum: 70n, // 70% quorum: high
                succeedAt: 70n // 70% success threshold: high
              })
            }]
          }),
          // optional law 15: execute an action assigned to path B. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Execute proposal: Execute a proposal assigned to path B.",
              targetLaw: getLawAddress("OpenAction", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 3n, // EXECUTIVES
                needCompleted: 11n, // need to have created a proposal and assigned to path 2
                needNotCompleted: 14n // need to have vetoed the proposal
                // NOTE: no vote. Each and every executive can execute the proposal. 
              })
            }]
          }),
          // optional law 16: pass an action assigned to path C. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Pass proposal: Pass a proposal assigned to path C.",
              targetLaw: getLawAddress("StatementOfIntent", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 3n, // EXECUTIVES
                needCompleted: 12n, // need to have created a proposal and assigned to path 3
                votingPeriod: 100n, // 100 blocks
                quorum: 30n, // 30% quorum: low
                succeedAt: 51n // 51% success threshold: low
              })
            }]
          }),
          // optional law 17: execute an action assigned to path C. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "adoptLaw",
            args: [{
              nameDescription: "Execute proposal: Execute a proposal assigned to path C.",
              targetLaw: getLawAddress("OpenAction", chainId),
              config: statementOfIntentConfig,
              conditions: createConditions({
                allowedRole: 2n, // SECURITY COUNCIL
                needCompleted: 16n, 
                votingPeriod: 100n, // 100 blocks
                quorum: 30n, // 30% quorum: low
                succeedAt: 51n // 51% success threshold: low
              })
            }]
          }),
          // assign labels to roles. 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Selectors"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [2n, "Security Council"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [3n, "Executives"]
          }),
          encodeFunctionData({
            abi: erc20TaxedAbi,
            functionName: "faucet",
            args: [] // faucet 
          }),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [2500000000000000000n] // mint 2.5 votes to the admin
          }),
          // delete laws 1 & 2 
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [2n]
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });
  
  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  ////////////////////////////////////////////////////////////////// 
  // law 3: nominateMe for selectors council.
  lawInitData.push({
    nameDescription: "Assign role 1: Assign one or more accounts to role 1.",
    targetLaw: getLawAddress("DirectSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [1]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  // law 4: Admin (de)selects members for role 3. 
  lawInitData.push({
    nameDescription: "Remove role 1: Remove one or more accounts from role 1.",
    targetLaw: getLawAddress("DirectDeselect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [1]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needCompleted: 3n
    })
  });

  // law 5: nominateMe for role 2.
  lawInitData.push({
    nameDescription: "Assign role 2: Assign one or more accounts to role 2.",
    targetLaw: getLawAddress("DirectSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [2]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  // law 6: Admin (de)selects members for role 2. 
  lawInitData.push({
    nameDescription: "Remove role 2: Remove one or more accounts from role 2.",
    targetLaw: getLawAddress("DirectDeselect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [2]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needCompleted: 5n
    })
  });
  

  // law 7: Admin (de)selects members for role 3. 
  lawInitData.push({
    nameDescription: "Assign role 3: Assign one or more accounts to role 3.",
    targetLaw: getLawAddress("DirectSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [3]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
    })
  });

  // law 8: Admin (de)selects members for role 3. 
  lawInitData.push({
    nameDescription: "Remove role 3: Remove one or more accounts from role 3.",
    targetLaw: getLawAddress("DirectDeselect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'roleId', type: 'uint16' }
      ],
      [3]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needCompleted: 7n
    })
  });

  return lawInitData;
}

/**
 * Creates law initialization data for Single Upgrade
 * This is a single upgrade law that can be used to upgrade the contract. 
 * Based on the createConstitution function from DeployGovernedUpgrades.s.sol
 */
export function createSingleUpgradeLawInitData(powersAddress: `0x${string}`, formData: SingleUpgradeFormData, chainId: number): LawInitData[] {
  const lawInitData: LawInitData[] = [];

  //////////////////////////////////////////////////////////////////
  //                       Initiation Law                         // 
  //////////////////////////////////////////////////////////////////

  // Law 1: Initial setup - Assign labels and mint tokens
  // Only admin (role 0) can use this law
  lawInitData.push({
    nameDescription: "RUN THIS LAW FIRST: It assigns labels and mint tokens. Please press the refresh button after the election has been deployed.",
    targetLaw: getLawAddress("PresetAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'targets', type: 'address[]' },
        { name: 'values', type: 'uint256[]' },
        { name: 'calldatas', type: 'bytes[]' }
      ],
      [
        [
          powersAddress,
          powersAddress,
          powersAddress,
          powersAddress
        ], // targets
        [0n, 0n, 0n, 0n], // values
        [
          encodeFunctionData({
            abi: powersAbi,
            functionName: "assignRole",
            args: [3n, getMockAddress("GovernorMock", chainId)] // assign previous DAO role as admin
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [3n, "DAO admin"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "labelRole",
            args: [1n, "Delegates"]
          }),
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [1n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE // admin role
    })
  });


  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  // Create input parameters for adopt law
  const inputParamsAdopt = [
    "address Law",
    "uint256 AllowedRole",
    "uint32 VotingPeriod", 
    "uint8 Quorum",
    "uint8 SucceedAt",
    "uint16 NeedCompl",
    "uint16 NeedNotCompl", 
    "uint16 StateFrom",
    "uint48 DelayExec",
    "uint48 ThrottleExec",
    "bytes Config",
    "string Description"
  ];

  // Law 2: Veto adopting a law
  // Only delegates (role 1) can use this law
  lawInitData.push({
    nameDescription: "Veto new law: Veto the adoption of a new law.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: encodeAbiParameters(
      [
        { name: 'inputParams', type: 'string[]' }
      ],
      [inputParamsAdopt]
    ),
    conditions: createConditions({
      allowedRole: 1n, // delegate role
      votingPeriod: minutesToBlocks(5, chainId),
      quorum: 50n, // 50% quorum
      succeedAt: 33n // 33% majority
    })
  });

  // Law 3: Veto revoking a law
  // Only delegates (role 1) can use this law
  lawInitData.push({
    nameDescription: "Veto revoking law: Veto the revocation of an existing, stopped, law.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: encodeAbiParameters(
      [
        { name: 'inputParams', type: 'string[]' }
      ],
      [["uint16 LawId"]]
    ),
    conditions: createConditions({
      allowedRole: 1n, // delegate role
      votingPeriod: minutesToBlocks(5, chainId),
      quorum: 15n, // 15% quorum
      succeedAt: 66n // 66% majority
    })
  });

  // Law 4: Adopt a law
  // Only previous DAO (role 3) can use this law
  lawInitData.push({
    nameDescription: "Adopt a new law: Adopt a new law into Powers.",
    targetLaw: getLawAddress("AdoptLaw", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: 3n, // previous DAO role
      needNotCompleted: 2n // law 2 should NOT have passed
    })
  });

  // Law 5: Revoke a law
  // Only previous DAO (role 3) can use this law
  lawInitData.push({
    nameDescription: "Stop a law: Revoke a law in Powers.",
    targetLaw: getLawAddress("BespokeAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'target', type: 'address' },
        { name: 'functionSelector', type: 'bytes4' },
        { name: 'inputParams', type: 'string[]' }
      ],
        [
          powersAddress,
          encodeFunctionData({
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [0n] // placeholder argument, we only need the selector
          }).slice(0, 10) as `0x${string}`, // Get just the 4-byte selector (0x + 8 hex chars)
          ["uint16 LawId"]
        ]
    ),
    conditions: createConditions({
      allowedRole: 3n, // previous DAO role
      needNotCompleted: 3n // law 3 should NOT have passed
    })
  });

  // Law 6: Veto token mint
  // Only previous DAO (role 3) can use this law
  lawInitData.push({
    nameDescription: "Veto token mint: Veto minting of tokens to a delegate.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: encodeAbiParameters(
      [
        { name: 'inputParams', type: 'string[]' }
      ],
      [["uint256 Quantity"]]
    ),
    conditions: createConditions({
      allowedRole: 3n // previous DAO role
    })
  });

  // Law 7: Mint tokens
  // Only delegates (role 1) can use this law
  lawInitData.push({
    nameDescription: "Mint tokens: Mint tokens to a delegate address.",
    targetLaw: getLawAddress("BespokeAction", chainId),
    config: encodeAbiParameters(
      [
        { name: 'target', type: 'address' },
        { name: 'functionSelector', type: 'bytes4' },
        { name: 'inputParams', type: 'string[]' }
      ],
              [
          getMockAddress("Erc20VotesMock", chainId),
          encodeFunctionData({
            abi: erc20VotesAbi,
            functionName: "mintVotes",
            args: [0n] // placeholder argument, we only need the selector
          }).slice(0, 10) as `0x${string}`, // Get just the 4-byte selector (0x + 8 hex chars)
          ["uint256 Quantity"]
        ]
    ),
    conditions: createConditions({
      allowedRole: 1n, // delegate role
      votingPeriod: minutesToBlocks(5, chainId),
      quorum: 30n, // 30% quorum
      succeedAt: 51n, // 51% majority
      needNotCompleted: 6n // law 6 needs to have passed
    })
  });

  // //////////////////////////////////////////////////////////////////
  // //                       Electoral laws                         // 
  // //////////////////////////////////////////////////////////////////
  // Law 8: Nominate me for delegate
  // This law allows accounts to self-nominate for any role
  // It can be used by community members
  lawInitData.push({
    nameDescription: "Nominate oneself for delegate role.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: PUBLIC_ROLE
    })
  });

  // law 9: Call election for delegate role. 
  lawInitData.push({
    nameDescription: "Call delegate election!: Please press the refresh button after the election has been deployed.",
    targetLaw: getLawAddress("ElectionStart", chainId),
    config: encodeAbiParameters(
      [
        { name: 'ElectionList', type: 'address' },
        { name: 'ElectionTally', type: 'address' },
        { name: 'roleId', type: 'uint16' },
        { name: 'maxToElect', type: 'uint32' }
      ],
      [ getLawAddress("ElectionList", chainId), 
        getLawAddress("ElectionTally", chainId),
        1, // roleId for delegates
        5 // maxToElect
      ]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      readStateFrom: 8n
    })
  });

  return lawInitData;
}

/**
 * Generic function to create law initialization data based on organization type
 */
export function createLawInitDataByType(
  type: OrganizationType,
  powersAddress: `0x${string}`,
  formData: Powers101FormData | CrossChainGovernanceFormData | GrantsManagerFormData | SplitGovernanceFormData | ManagedUpgradesFormData | SingleUpgradeFormData,
  chainId: number
): LawInitData[] {
  switch (type) {
    case 'Powers 101':
      return createPowers101LawInitData(powersAddress, formData as Powers101FormData, chainId);
    case 'Bridging Off-Chain Governance':
      return createCrossChainGovernanceLawInitData(powersAddress, formData as CrossChainGovernanceFormData, chainId);
    case 'Grants Manager':
      return createGrantsManagerLawInitData(powersAddress, formData as GrantsManagerFormData, chainId);
    case 'Split Governance':
      return createSplitGovernanceLawInitData(powersAddress, formData as SplitGovernanceFormData, chainId);
    case 'Packaged Upgrades':
      return createPackagedUpgradesLawInitData(powersAddress, formData as ManagedUpgradesFormData, chainId);
    case 'Single Upgrades':
      return createSingleUpgradeLawInitData(powersAddress, formData as SingleUpgradeFormData, chainId);
    default:
      throw new Error(`Unknown organization type: ${type}`);
  }
}
