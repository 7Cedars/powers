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
 * Contract dpeloyment data */
export interface DeployableContract {
  name: string;
  abi: Abi;
  args?: any[];
  bytecode: `0x${string}`;
  ownable?: boolean;
}

export type LawData = { name: string; address: `0x${string}` };

/**
 * Complete organization definition
 */
export interface Organization {
  metadata: OrganizationMetadata;
  fields: OrganizationField[];
  dependencies: DeployableContract[];
  
  /**
   * Generate law initialization data for this organization
   * @param powersAddress - Address of the deployed Powers contract
   * @param formData - User input from deployment form
   * @param deployedLaws - List of deployed laws
   */
  createLawInitData: (
    powersAddress: `0x${string}`, 
    deployedLaws: Record<string, `0x${string}`>,
    deployedMocks: Record<string, `0x${string}`>
  ) => LawInitData[];

  /**
   * Optional: Validation function for form data
   */
  validateFormData?: (formData: Record<string, any>) => { valid: boolean; errors?: string[] };
}

