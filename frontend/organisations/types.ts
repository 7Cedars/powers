import { Abi } from "viem";
import { LawConditions } from "./helpers";

/**
 * Law initialization data
 */
export interface LawInitData {
  nameDescription: string;
  targetLaw: `0x${string}`;
  config: `0x${string}`;
  conditions: LawConditions;
}

/**
 * Represents a form field for organization deployment
 */
export interface OrganizationField {
  name: string;
  placeholder: string;
  type: string;
  required: boolean;
}
 
/**
 * Metadata for an organization
 */
export interface OrganizationMetadata {
  id: string;
  title: string;
  uri: string;
  banner: string;
  description: string;
  disabled: boolean;
  onlyLocalhost: boolean;
}

/**
 * Contract deployment data */
export interface DeployableContract {
  name: string;
  abi: Abi;
  args?: any[];
  bytecode: `0x${string}`;
  ownable?: boolean;
}

/**
 * Function call dependency data */
export interface FunctionCallDependency {
  name: string;
  target: `0x${string}`;
  abi: Abi;
  functionName: string;
  args?: any[];
  ownable?: boolean;
}

/**
 * Executable dependency - can be either contract deployment or function call */
export type ExecutableDependency = DeployableContract | FunctionCallDependency;

/**
 * Type guard to check if dependency is a contract deployment
 */
export function isDeployableContract(dep: ExecutableDependency): dep is DeployableContract {
  return 'bytecode' in dep;
}

/**
 * Type guard to check if dependency is a function call
 */
export function isFunctionCallDependency(dep: ExecutableDependency): dep is FunctionCallDependency {
  return 'target' in dep && 'functionName' in dep;
}

export type LawData = { name: string; address: `0x${string}` };

/**
 * Complete organization definition
 */
export interface Organization {
  metadata: OrganizationMetadata;
  fields: OrganizationField[];
  dependencies: ExecutableDependency[];
  
  /**
   * Allowed chains for public deployment
   */
  allowedChains: number[];
  
  /**
   * Allowed chains when deployed locally (localhost)
   */
  allowedChainsLocally: number[];
  
  /**
   * Generate law initialization data for this organization
   * @param powersAddress - Address of the deployed Powers contract
   * @param formData - User input from deployment form
   * @param deployedLaws - List of deployed laws
   * @param dependencyReceipts - Raw transaction receipts from dependency executions
   * @param chainId - Chain ID
   */
  createLawInitData: (
    powersAddress: `0x${string}`, 
    formData: Record<string, any>,
    deployedLaws: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ) => LawInitData[];

  /**
   * Optional: Validation function for form data
   */
  validateFormData?: (formData: Record<string, any>) => { valid: boolean; errors?: string[] };
}
