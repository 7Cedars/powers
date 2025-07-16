import { getDeployedLawAddresses } from "@/context/constants";
import { encodeAbiParameters } from "viem";

export interface LawConditions {
  allowedRole: number;
  needCompleted: number;
  delayExecution: number;
  throttleExecution: number;
  readStateFrom: number;
  votingPeriod: number;
  quorum: number;
  succeedAt: number;
  needNotCompleted: number;
}

export interface LawInitData {
  nameDescription: string;
  targetLaw: string;
  config: string;
  conditions: LawConditions;
}

export interface Powers101FormData {
  treasuryAddress?: string;
}

export interface CrossChainGovernanceFormData {
  snapshotSpace?: string;
  governorAddress?: string;
}

export interface GrantsManagerFormData {
  parentDaoAddress?: string;
  grantTokenAddress?: string;
  assessors?: string[];
}

// other examples tbi: 
// - WG manager
// - Accountability of Service providers (think Uniswap UAC but for service providers :) 
// - dynamic governance for different type of proposals? 
// - Inter-DAO governance? 

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

// Type for deployment file structure
export interface DeploymentFile {
  returns: DeploymentReturns;
}

/**
 * Fetches the address of a deployed law by its name and chain ID
 * @param lawName - The name of the law to find
 * @param chainId - The chain ID to search in
 * @returns The law address if found, undefined otherwise
 */
export async function getLawAddressByName(lawName: string, chainId: number): Promise<string | undefined> {
  try {
    // Dynamically import the deployment file for the specified chain
    const deploymentData = await import(`../../solidity/broadcast/DeployLaws.s.sol/${chainId}/run-latest.json`) as DeploymentFile;
    
    if (deploymentData && deploymentData.returns) {
      // Parse the JSON string arrays from the returns data
      const addresses = JSON.parse(deploymentData.returns.addresses.value) as string[];
      const names = JSON.parse(deploymentData.returns.names.value) as string[];
      
      // Find the index of the law name
      const lawIndex = names.findIndex(name => name === lawName);
      
      // Return the corresponding address if found
      if (lawIndex !== -1 && addresses[lawIndex]) {
        return addresses[lawIndex];
      }
    }
    
    return undefined;
  } catch (error) {
    console.warn(`Could not load deployment data for chain ${chainId}:`, error);
    return undefined;
  }
}

/**
 * Fetches multiple law addresses by their names and chain ID
 * @param lawNames - Array of law names to find
 * @param chainId - The chain ID to search in
 * @returns Object mapping law names to their addresses (undefined if not found)
 */
export async function getLawAddressesByNames(lawNames: string[], chainId: number): Promise<Record<string, string | undefined>> {
  const result: Record<string, string | undefined> = {};
  
  for (const lawName of lawNames) {
    result[lawName] = await getLawAddressByName(lawName, chainId);
  }
  
  return result;
}

/**
 * Creates law initialization data for Powers 101 DAO
 * Based on the createConstitution function from DeployPowers101.s.sol
 */
export function createPowers101LawInitData(formData: Powers101FormData, chainId: number): LawInitData[] {
  const blocksPerHour = getBlocksPerHour(chainId);
  
  // Helper function to convert minutes to blocks
  const minutesToBlocks = (minutes: number): number => {
    return Math.floor(minutes * blocksPerHour / 60);
  };

  // Helper function to get law address by name
  const getLawAddress = (lawName: string): string => {
    const address = getDeployedLawAddresses(lawName);
    if (!address) {
      throw new Error(`Law address not found for: ${lawName}`);
    }
    return address;
  };

  // Helper function to create empty conditions
  const createEmptyConditions = (): LawConditions => ({
    allowedRole: 0,
    needCompleted: 0,
    delayExecution: 0,
    throttleExecution: 0,
    readStateFrom: 0,
    votingPeriod: 0,
    quorum: 0,
    succeedAt: 0,
    needNotCompleted: 0
  });

  const lawInitData: LawInitData[] = [];

  //////////////////////////////////////////////////////////////////
  //                       Electoral laws                         // 
  //////////////////////////////////////////////////////////////////
  
  // Law 1: Nominate me for delegate
  // This law allows accounts to self-nominate for any role
  // It can be used by community members
  let conditions = createEmptyConditions();
  conditions.allowedRole = 1;
  lawInitData.push({
    nameDescription: "Nominate me for delegate: Nominate yourself for a delegate role. You need to be a community member to use this law.",
    targetLaw: getLawAddress("NominateMe"),
    config: "0x", // empty config
    conditions: conditions
  });

  // Law 2: Elect delegates
  // This law enables role selection through delegated voting using an ERC20 token
  // Only role 0 (admin) can use this law
  conditions = createEmptyConditions();
  conditions.allowedRole = 0;
  conditions.readStateFrom = 1;
  // Note: We'll need mock addresses for this config, using placeholder for now
  // In the Solidity version: abi.encode(parseMockAddress(2, "Erc20VotesMock"), 15, 2)
  const delegateSelectConfig = encodeAbiParameters(
    [
      { name: 'tokenAddress', type: 'address' },
      { name: 'maxRoleHolders', type: 'uint256' },
      { name: 'roleId', type: 'uint256' }
    ],
    ["0x0000000000000000000000000000000000000000", 15n, 2n] // Placeholder address, will need actual mock address
  );
  lawInitData.push({
    nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
    targetLaw: getLawAddress("DelegateSelect"),
    config: delegateSelectConfig,
    conditions: conditions
  });

  // Law 3: Self select as community member
  // This law enables anyone to select themselves as a community member
  // Anyone can use this law
  conditions = createEmptyConditions();
  conditions.throttleExecution = 25; // this law can be called once every 25 blocks
  conditions.allowedRole = Number.MAX_SAFE_INTEGER; // equivalent to type(uint256).max
  // In the Solidity version: abi.encode(1)
  const selfSelectConfig = encodeAbiParameters(
    [
      { name: 'roleId', type: 'uint256' }
    ],
    [1n] // roleId to be elected
  );
  lawInitData.push({
    nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
    targetLaw: getLawAddress("SelfSelect"),
    config: selfSelectConfig,
    conditions: conditions
  });

  //////////////////////////////////////////////////////////////////
  //                       Executive laws                         // 
  //////////////////////////////////////////////////////////////////

  // Law 4: Statement of Intent
  // This law allows proposing changes to core values of the DAO
  // Only community members can use this law. It is subject to a vote.
  conditions = createEmptyConditions();
  conditions.allowedRole = 1;
  conditions.votingPeriod = minutesToBlocks(5); // about 5 minutes
  conditions.succeedAt = 51; // 51% simple majority needed
  conditions.quorum = 20; // 20% quorum needed
  // In the Solidity version: abi.encode(inputParams)
  const inputParams = ["address[] Targets", "uint256[] Values", "bytes[] Calldatas"];
  const statementOfIntentConfig = encodeAbiParameters(
    [
      { name: 'inputParams', type: 'string[]' }
    ],
    [inputParams]
  );
  lawInitData.push({
    nameDescription: "Statement of Intent: Create an SoI for an action that can later be executed by Delegates.",
    targetLaw: getLawAddress("StatementOfIntent"),
    config: statementOfIntentConfig,
    conditions: conditions
  });

  // Law 5: Veto an action
  // This law allows a proposed action to be vetoed
  // Only the admin can use this law
  conditions = createEmptyConditions();
  conditions.allowedRole = 0;
  conditions.needCompleted = 4; // references the Statement of Intent law
  lawInitData.push({
    nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
    targetLaw: getLawAddress("StatementOfIntent"),
    config: statementOfIntentConfig,
    conditions: conditions
  });

  // Law 6: Execute an action
  // This law allows executing any action with voting requirements
  // Only role 2 can use this law
  conditions = createEmptyConditions();
  conditions.allowedRole = 2;
  conditions.quorum = 50; // 50% quorum needed
  conditions.succeedAt = 77; // 77% simple majority needed for executing an action
  conditions.votingPeriod = minutesToBlocks(5);
  conditions.needCompleted = 4; // references the Statement of Intent law
  conditions.needNotCompleted = 5; // references the Veto law
  conditions.delayExecution = minutesToBlocks(3); // 3 minutes delay to give admin time to veto
  lawInitData.push({
    nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
    targetLaw: getLawAddress("OpenAction"),
    config: "0x", // empty config, an open action takes address[], uint256[], bytes[] as input
    conditions: conditions
  });

  // Law 7: Initial setup
  // This law sets up initial role assignments for the DAO & role labelling
  // Only the admin can use this law
  conditions = createEmptyConditions();
  conditions.allowedRole = 0;
  // In the Solidity version: abi.encode(targetsRoles, valuesRoles, calldatasRoles)
  // This would need the actual mock addresses and powers address, but for now using placeholders
  const initialSetupConfig = encodeAbiParameters(
    [
      { name: 'targets', type: 'address[]' },
      { name: 'values', type: 'uint256[]' },
      { name: 'calldatas', type: 'bytes[]' }
    ],
    [
      ["0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000"], // targets
      [0n, 0n, 0n, 0n, 0n], // values
      ["0x", "0x", "0x", "0x", "0x"] // calldatas - would need actual encoded function calls
    ]
  );
  lawInitData.push({
    nameDescription: "Initial setup: Assign labels and mint tokens. This law can only be executed once.",
    targetLaw: getLawAddress("PresetAction"),
    config: initialSetupConfig,
    conditions: conditions
  });

  return lawInitData;
}

/**
 * Helper function to get blocks per hour for a given chain ID
 */
function getBlocksPerHour(chainId: number): number {
  switch (chainId) {
    case 421614: // arb sepolia
      return 300;
    case 11155420: // optimism sepolia
      return 1800;
    case 11155111: // mainnet sepolia
      return 300;
    case 31337: // anvil local
      return 300;
    default:
      return 300;
  }
}

/**
 * Creates law initialization data for Governed Upgrades
 * Includes upgrade governance and implementation management laws
 */
export function createCrossChainGovernanceLawInitData(formData: CrossChainGovernanceFormData, chainId: number): LawInitData[] {
    return [
        {
          nameDescription: "Statement of Intent Law",
          targetLaw: "0x4d30c1B4f522af77d9208472af616bAE8E550615", // Dummy governance law address
          config: "0x", // Empty bytes
          conditions: {
            allowedRole: 0, // ADMIN_ROLE
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 0,
            votingPeriod: 100, // 100 blocks
            quorum: 50, // 50% quorum
            succeedAt: 60, // 60% success threshold
            needNotCompleted: 0
          }
        }
      ];
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
            allowedRole: 0, // ADMIN_ROLE
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 0,
            votingPeriod: 100, // 100 blocks
            quorum: 50, // 50% quorum
            succeedAt: 60, // 60% success threshold
            needNotCompleted: 0
          }
        }
      ];
}

/**
 * Generic function to create law initialization data based on organization type
 */
export function createLawInitDataByType(
  type: 'Powers101' | 'CrossChainGovernance' | 'GrantsManager',
  formData: Powers101FormData | CrossChainGovernanceFormData | GrantsManagerFormData,
  chainId: number
): LawInitData[] {
  switch (type) {
    case 'Powers101':
      return createPowers101LawInitData(formData as Powers101FormData, chainId);
    case 'CrossChainGovernance':
      return createCrossChainGovernanceLawInitData(formData as CrossChainGovernanceFormData, chainId);
    case 'GrantsManager':
      return createGrantsManagerLawInitData(formData as GrantsManagerFormData, chainId);
    default:
      throw new Error(`Unknown organization type: ${type}`);
  }
}
