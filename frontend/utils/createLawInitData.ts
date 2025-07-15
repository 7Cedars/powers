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
 * Creates law initialization data for Basic DAO
 * Includes basic governance and treasury management laws
 */
export function createPowers101LawInitData(formData: Powers101FormData, chainId: number): LawInitData[] {
  return [
    {
      nameDescription: "Statement of Intent Law",
      targetLaw: "0x0000000000000000000000000000000000000001", // Dummy governance law address
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
 * Creates law initialization data for Governed Upgrades
 * Includes upgrade governance and implementation management laws
 */
export function createCrossChainGovernanceLawInitData(formData: CrossChainGovernanceFormData, chainId: number): LawInitData[] {
    return [
        {
          nameDescription: "Statement of Intent Law",
          targetLaw: "0x0000000000000000000000000000000000000001", // Dummy governance law address
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
          targetLaw: "0x0000000000000000000000000000000000000001", // Dummy governance law address
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
