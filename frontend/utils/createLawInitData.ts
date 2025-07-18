import { powersAbi, erc20TaxedAbi, erc20VotesAbi } from "@/context/abi";
import { getConstants } from "@/context/constants";
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

export interface Powers101FormData {
  treasuryAddress?: `0x${string}`;
}

export interface CrossChainGovernanceFormData {
  snapshotSpace?: string;
  governorAddress?: `0x${string}`;
  chainlinkSubscriptionId: number;
}

export interface GrantsManagerFormData {
  parentDaoAddress?: `0x${string}`;
  grantTokenAddress?: `0x${string}`;
  assessors?: `0x${string}`[];
}

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

  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////
  // Law 1: Nominate me for delegate
  // This law allows accounts to self-nominate for any role
  // It can be used by community members
  lawInitData.push({
    nameDescription: "Nominate me for delegate: Nominate yourself for a delegate role. You need to be a community member to use this law.",
    targetLaw: getLawAddress("NominateMe", chainId),
    config: "0x", // empty config
    conditions: createConditions({
      allowedRole: 1n
    })
  });

  // Law 2: Elect delegates
  // This law enables role selection through delegated voting using an ERC20 token
  // Only role 0 (admin) can use this law
  // Note: We'll need mock addresses for this config, using placeholder for now
  // In the Solidity version: abi.encode(parseMockAddress(2, "Erc20VotesMock"), 15, 2)
  lawInitData.push({
    nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
    targetLaw: getLawAddress("DelegateSelect", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' },
        { name: 'maxRoleHolders', type: 'uint256' },
        { name: 'roleId', type: 'uint256' }
      ],
      [getMockAddress("Erc20VotesMock", chainId), 15n, 2n]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      readStateFrom: 1n
    })
  });

  // Law 3: Self select as community member
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

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 4: Statement of Intent
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

  // Law 5: Veto an action
  // This law allows a proposed action to be vetoed
  // Only the admin can use this law
  lawInitData.push({
    nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
    targetLaw: getLawAddress("StatementOfIntent", chainId),
    config: statementOfIntentConfig,
    conditions: createConditions({
      allowedRole: ADMIN_ROLE,
      needCompleted: 4n // references the Statement of Intent law
    })
  });

  // Law 6: Execute an action
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
      needCompleted: 4n,
      needNotCompleted: 5n,
      delayExecution: minutesToBlocks(3, chainId)
    })
  });

  // Law 7: Initial setup
  // This law sets up initial role assignments for the DAO & role labelling
  // Only the admin can use this law
  // In the Solidity version: abi.encode(targetsRoles, valuesRoles, calldatasRoles)
  // This would need the actual mock addresses and powers address, but for now using placeholders
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
          powersAddress, powersAddress, powersAddress
        ], // targets
        [0n, 0n, 0n], // values
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
            abi: powersAbi,
            functionName: "revokeLaw",
            args: [7n] // revoke the initial setup law
          })
        ]
      ]
    ),
    conditions: createConditions({
      allowedRole: ADMIN_ROLE
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
    nameDescription: "Does proposal exist?: Check if a proposal and choice exists at the hvax.eth Snapshot space.",
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
    nameDescription: "Did choice pass?: Check if a proposal and choice passed at the hvax.eth Snapshot space.",
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
    nameDescription: "Create Governor.sol proposal: Create a new Governor.sol proposal using Erc20VotesMock as votes.",
    targetLaw: getLawAddress("SnapToGov_CreateGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' }
      ],
      [getMockAddress("Erc20VotesMock", chainId)]
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
    nameDescription: "Cancel Governor.sol proposal: Cancel a Governor.sol proposal.",
    targetLaw: getLawAddress("SnapToGov_CancelGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' }
      ],
      [getMockAddress("Erc20VotesMock", chainId)]
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
    nameDescription: "Execute Governor.sol proposal: Execute a Governor.sol proposal.",
    targetLaw: getLawAddress("SnapToGov_ExecuteGov", chainId),
    config: encodeAbiParameters(
      [
        { name: 'tokenAddress', type: 'address' }
      ],
      [getMockAddress("Erc20VotesMock", chainId)]
    ),
    conditions: createConditions({
      allowedRole: 1n,
      needCompleted: 3n,
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
    nameDescription: "Elect executives: Elect executives using delegated tokens.",
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
    nameDescription: "Initial setup: Assign role labels. This law can only be executed once.",
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
          powersAddress
        ], // targets
        [0n, 0n, 0n], // values
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

/**
 * Creates law initialization data for Managed Grants
 * Includes grant distribution and management laws
 */
export function createGrantsManagerLawInitData(formData: GrantsManagerFormData, chainId: number): LawInitData[] {
    return [
        {
          nameDescription: "Statement of Intent Law",
          targetLaw: "0x4d30c1B4f522af77d9208472af616bAE8E550615", // Dummy governance law address
          config: "0x", // Empty bytes
          conditions: {
            allowedRole: ADMIN_ROLE, // ADMIN_ROLE
            needCompleted: 0n,
            delayExecution: 0n,
            throttleExecution: 0n,
            readStateFrom: 0n,
            votingPeriod: 100n, // 100 blocks
            quorum: 50n, // 50% quorum
            succeedAt: 60n, // 60% success threshold
            needNotCompleted: 0n
          }
        }
      ];
}

/**
 * Generic function to create law initialization data based on organization type
 */
export function createLawInitDataByType(
  type: 'Powers101' | 'CrossChainGovernance' | 'GrantsManager',
  powersAddress: `0x${string}`,
  formData: Powers101FormData | CrossChainGovernanceFormData | GrantsManagerFormData,
  chainId: number
): LawInitData[] {
  switch (type) {
    case 'Powers101':
      return createPowers101LawInitData(powersAddress, formData as Powers101FormData, chainId);
    case 'CrossChainGovernance':
      return createCrossChainGovernanceLawInitData(powersAddress, formData as CrossChainGovernanceFormData, chainId);
    case 'GrantsManager':
      return createGrantsManagerLawInitData(formData as GrantsManagerFormData, chainId);
    default:
      throw new Error(`Unknown organization type: ${type}`);
  }
}
