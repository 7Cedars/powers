import { getConstants } from "@/context/constants";

/**
 * Common role constants used across organizations
 */
export const ADMIN_ROLE = 0n;
export const PUBLIC_ROLE = 115792089237316195423570985008687907853269984665640564039457584007913129639935n;

/**
 * Parameters for creating law conditions
 */
export interface CreateConditionsParams {
  allowedRole?: bigint;
  needFulfilled?: bigint;
  delayExecution?: bigint;
  throttleExecution?: bigint;
  readStateFrom?: bigint;
  votingPeriod?: bigint;
  quorum?: bigint;
  succeedAt?: bigint;
  needNotFulfilled?: bigint;
}

/**
 * Law conditions structure
 */
export interface LawConditions {
  allowedRole: bigint;
  needFulfilled: bigint;
  delayExecution: bigint;
  throttleExecution: bigint;
  readStateFrom: bigint;
  votingPeriod: bigint;
  quorum: bigint;
  succeedAt: bigint;
  needNotFulfilled: bigint;
}

/**
 * Create law conditions object with defaults
 */
export const createConditions = (params: CreateConditionsParams): LawConditions => ({
  allowedRole: params.allowedRole ?? 0n,
  needFulfilled: params.needFulfilled ?? 0n,
  delayExecution: params.delayExecution ?? 0n,
  throttleExecution: params.throttleExecution ?? 0n,
  readStateFrom: params.readStateFrom ?? 0n,
  votingPeriod: params.votingPeriod ?? 0n,
  quorum: params.quorum ?? 0n,
  succeedAt: params.succeedAt ?? 0n,
  needNotFulfilled: params.needNotFulfilled ?? 0n
});

/**
 * Get a law contract address by its name
 * @param lawName - Name of the law (e.g., "OpenAction", "StatementOfIntent")
 * @param chainId - Chain ID
 * @returns The address of the law contract
 * @throws Error if law not found
 */
export const getLawAddress = (lawName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.LAW_ADDRESSES[constants.LAW_NAMES.indexOf(lawName)];
  if (!address) {
    throw new Error(`Law address not found for: ${lawName}`);
  }
  return address;
};

/**
 * Get a mock contract address by its name
 * @param mockName - Name of the mock contract
 * @param chainId - Chain ID
 * @returns The address of the mock contract
 * @throws Error if mock not found
 */
export const getMockAddress = (mockName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.MOCK_ADDRESSES[constants.MOCK_NAMES.indexOf(mockName)];
  if (!address) {
    throw new Error(`Mock address not found for: ${mockName}`);
  }
  return address;
};

/**
 * Convert days to blocks based on chain-specific block time
 * @param days - Number of days
 * @param chainId - Chain ID
 * @returns Number of blocks
 */
export const daysToBlocks = (days: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(days * constants.BLOCKS_PER_HOUR * 24));
};

/**
 * Convert hours to blocks based on chain-specific block time
 * @param hours - Number of hours
 * @param chainId - Chain ID
 * @returns Number of blocks
 */
export const hoursToBlocks = (hours: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(hours * constants.BLOCKS_PER_HOUR));
};

/**
 * Convert minutes to blocks based on chain-specific block time
 * @param minutes - Number of minutes
 * @param chainId - Chain ID
 * @returns Number of blocks
 */
export const minutesToBlocks = (minutes: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(minutes * constants.BLOCKS_PER_HOUR / 60));
};

/**
 * Validate an Ethereum address format
 * @param address - Address to validate
 * @returns True if valid Ethereum address
 */
export const isValidAddress = (address: string): boolean => {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
};

/**
 * Validate a percentage value (0-100)
 * @param value - Value to validate
 * @returns True if valid percentage
 */
export const isValidPercentage = (value: number): boolean => {
  return value >= 0 && value <= 100;
};

/**
 * Validate a positive integer
 * @param value - Value to validate
 * @returns True if positive integer
 */
export const isPositiveInteger = (value: number): boolean => {
  return Number.isInteger(value) && value > 0;
};

/**
 * Common validation errors
 */
export const ValidationErrors = {
  INVALID_ADDRESS: "Invalid Ethereum address format",
  REQUIRED_FIELD: (field: string) => `${field} is required`,
  INVALID_PERCENTAGE: "Value must be between 0 and 100",
  INVALID_POSITIVE_INTEGER: "Value must be a positive integer",
  INVALID_RANGE: (min: number, max: number) => `Value must be between ${min} and ${max}`,
} as const;

/**
 * Common form field validators
 */
export const validators = {
  address: (value: string, fieldName: string) => {
    if (!value) return ValidationErrors.REQUIRED_FIELD(fieldName);
    if (!isValidAddress(value)) return ValidationErrors.INVALID_ADDRESS;
    return null;
  },

  optionalAddress: (value: string) => {
    if (!value) return null; // Optional field
    if (!isValidAddress(value)) return ValidationErrors.INVALID_ADDRESS;
    return null;
  },

  percentage: (value: number, fieldName: string) => {
    if (value === undefined || value === null) {
      return ValidationErrors.REQUIRED_FIELD(fieldName);
    }
    if (!isValidPercentage(value)) return ValidationErrors.INVALID_PERCENTAGE;
    return null;
  },

  positiveInteger: (value: number, fieldName: string) => {
    if (value === undefined || value === null) {
      return ValidationErrors.REQUIRED_FIELD(fieldName);
    }
    if (!isPositiveInteger(value)) return ValidationErrors.INVALID_POSITIVE_INTEGER;
    return null;
  },

  range: (value: number, min: number, max: number, fieldName: string) => {
    if (value === undefined || value === null) {
      return ValidationErrors.REQUIRED_FIELD(fieldName);
    }
    if (value < min || value > max) {
      return ValidationErrors.INVALID_RANGE(min, max);
    }
    return null;
  },
} as const;

/**
 * Helper to create a validation result
 */
export const createValidationResult = (errors: string[]) => ({
  valid: errors.length === 0,
  errors: errors.length > 0 ? errors : undefined,
});

/**
 * Common function selectors for Grant.sol
 * These are the 4-byte function selectors for Grant contract methods
 */
export const GrantFunctionSelectors = {
  updateNativeBudget: "0x8b5e3b4a" as `0x${string}`,
  updateTokenBudget: "0x1c5a9d9e" as `0x${string}`,
  whitelistToken: "0x0a3b0a4f" as `0x${string}`,
  dewhitelistToken: "0x9c52a7f1" as `0x${string}`,
  submitProposal: "0x7c5e9b1a" as `0x${string}`,
  approveProposal: "0x6f0f6698" as `0x${string}`,
  rejectProposal: "0x9d888e86" as `0x${string}`,
  releaseMilestone: "0x4b8a4e9c" as `0x${string}`,
} as const;

/**
 * Common function selectors for Powers.sol
 */
export const PowersFunctionSelectors = {
  assignRole: "0xf6a3d24e" as `0x${string}`,
  revokeRole: "0x2f2ff15d" as `0x${string}`,
  labelRole: "0x8c7e8e0a" as `0x${string}`,
  adoptLaw: "0x3c6b16ab" as `0x${string}`,
  revokeLaw: "0x9d5c4c9f" as `0x${string}`,
} as const;

/**
 * Common function selectors for ERC20 tokens
 */
export const ERC20FunctionSelectors = {
  transfer: "0xa9059cbb" as `0x${string}`,
  approve: "0x095ea7b3" as `0x${string}`,
  transferFrom: "0x23b872dd" as `0x${string}`,
  mint: "0x40c10f19" as `0x${string}`,
  burn: "0x42966c68" as `0x${string}`,
} as const;

/**
 * Helper to format role names for display
 */
export const formatRoleName = (roleName: string): string => {
  return roleName
    .split(/(?=[A-Z])/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
};

/**
 * Helper to create a proposal configuration for StatementOfIntent
 */
export const createProposalConfig = (inputParams: string[]) => {
  const { encodeAbiParameters } = require("viem");
  return encodeAbiParameters(
    [{ name: 'inputParams', type: 'string[]' }],
    [inputParams]
  );
};

/**
 * Helper to create a BespokeActionSimple configuration
 */
export const createBespokeActionConfig = (
  target: `0x${string}`,
  functionSelector: `0x${string}`,
  inputParams: string[]
) => {
  const { encodeAbiParameters } = require("viem");
  return encodeAbiParameters(
    [
      { name: 'target', type: 'address' },
      { name: 'functionSelector', type: 'bytes4' },
      { name: 'inputParams', type: 'string[]' }
    ],
    [target, functionSelector, inputParams]
  );
};

