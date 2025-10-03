# BuyAccess.sol

BuyAccess.sol is an electoral law that assigns roles based on the latest donation an account made to a Donations contract. It provides a mechanism for token-gated access where role assignments are determined by donation amounts and duration.

## Overview

This law provides a mechanism to:
- Assign roles based on donation amounts
- Support multiple token types with different rates
- Calculate access duration based on donation size
- Automatically revoke roles when access expires
- Track donation-based access

## Configuration

When adopting a BuyAccess instance, four parameters must be provided:

1. `donationsContract` (address): The address of the Donations contract
2. `tokens` (address[]): Array of supported token addresses (address(0) for native currency)
3. `tokensPerBlock` (uint256[]): Array of tokens per block for access duration calculation
4. `roleId` (uint16): The role ID to assign/revoke based on donations

## Usage

### Proposing an Action

When calling the law, one parameter must be provided:

1. `account` (address): The account to check and potentially assign/revoke the role for

### Execution Flow

1. **Donation Check**
   - Retrieves all donations for the account
   - Finds the most recent donation
   - Determines if access is still valid

2. **Access Calculation**
   - Calculates access duration based on donation amount
   - Determines if access has expired
   - Checks if token is supported

3. **Role Management**
   - If access is valid and account doesn't have role:
     - Assigns the role
   - If access is expired and account has role:
     - Revokes the role
   - If no change needed:
     - Returns empty execution data

4. **State Management**
   - Records role assignment/revocation
   - Updates access tracking
   - Maintains donation history

## Technical Specifications

### State Variables

```solidity
struct TokenConfig {
    address token;              // Token address (address(0) for native)
    uint256 tokensPerBlock;     // Tokens per block for access duration
}

struct Data {
    address donationsContract;  // Donations contract address
    TokenConfig[] tokenConfigs; // Token configurations
    uint16 roleIdToSet;        // Role ID to assign/revoke
}

mapping(bytes32 lawHash => Data) public data;
```

### Functions

#### `initializeLaw`
```solidity
function initializeLaw(
    uint16 index,
    string memory nameDescription,
    bytes memory inputParams,
    bytes memory config
) public override
```
- Initializes law with configuration parameters
- Sets up donations contract and token configurations
- Configures role assignment parameters

#### `handleRequest`
```solidity
function handleRequest(
    address caller,
    address powers,
    uint16 lawId,
    bytes memory lawCalldata,
    uint256 nonce
) public view virtual override returns (
    uint256 actionId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas
)
```
- Processes the role management request
- Checks donation access validity
- Prepares role assignment/revocation call
- Returns execution data

#### `_checkDonationAccess`
```solidity
function _checkDonationAccess(
    address account,
    address donationsContract,
    TokenConfig[] memory tokenConfigs,
    uint48 currentBlock
) internal view returns (bool shouldAssign)
```
- Checks if account has valid donation access
- Calculates access duration from most recent donation
- Determines if access is still valid

### Error Conditions

1. **Configuration Errors**
   - "Tokens and TokensPerBlock arrays must have the same length"
   - "At least one token configuration is required"
   - Invalid donations contract address

2. **Access Errors**
   - No donations found
   - Token not configured
   - Donation too small for access
   - Access expired

3. **Validation Errors**
   - Zero address account
   - Invalid token configuration
   - Invalid role ID

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155420  | Optimism Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155111  | Ethereum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  | 



