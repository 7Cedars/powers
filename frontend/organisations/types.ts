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
 * Mock contract that needs to be deployed before the organization
 */
export interface MockContract {
  name: string;
  contractName: string;
  constructorArgs?: any[];
}

/**
 * Complete organization definition
 */
export interface Organization {
  metadata: OrganizationMetadata;
  fields: OrganizationField[];
  
  /**
   * Generate law initialization data for this organization
   * @param powersAddress - Address of the deployed Powers contract
   * @param formData - User input from deployment form
   * @param chainId - Chain ID where deployment is happening
   */
  createLawInitData: (
    powersAddress: `0x${string}`,
    formData: Record<string, any>,
    chainId: number
  ) => LawInitData[];
  
  /**
   * Optional: Mock contracts that need to be deployed
   * These will be deployed before the Powers contract
   */
  getMockContracts?: (formData: Record<string, any>) => MockContract[];
  
  /**
   * Optional: Validation function for form data
   */
  validateFormData?: (formData: Record<string, any>) => { valid: boolean; errors?: string[] };
}

