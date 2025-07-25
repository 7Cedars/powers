# SelfSelect.sol

SelfSelect.sol is an electoral law that enables accounts to self-assign or self-revoke a specific role. It provides a mechanism for accounts to manage their own role assignments.

## Overview

This law provides a mechanism to:
- Allow accounts to assign themselves a specific role
- Enable accounts to revoke their own role
- Track self-assigned accounts
- Enforce maximum role holder limits

## Configuration

When adopting a SelfSelect instance, two parameters must be provided:

1. `maxRoleHolders` (uint256): Maximum number of accounts that can be assigned the role
2. `roleID` (uint256): The role ID that can be self-assigned/revoked

## Usage

### Proposing an Action

When calling the law, one parameter must be provided:

1. `assign` (bool): 
   - `true`: Self-assign the role
   - `false`: Self-revoke the role

### Execution Flow

1. **Account Validation**
   - Verifies the caller's address
   - Checks current role status
   - Validates maximum role holders limit

2. **Role Assignment**
   - If `assign` is true:
     - Checks if account already has the role
     - Verifies maximum role holders limit
     - Assigns role if conditions are met
   - If `assign` is false:
     - Verifies account has the role
     - Revokes role if conditions are met

3. **State Management**
   - Updates self-assigned accounts list
   - Maintains sorted list of accounts
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxRoleHolders;    // Maximum number of role holders allowed
    uint256 roleId;           // Role ID to self-assign/revoke
    address[] selfAssigned;   // List of self-assigned accounts
    address[] selfAssignedSorted;  // Sorted list of self-assigned accounts
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
    Conditions memory conditions,
    bytes memory config
) public override
```
- Initializes law with configuration parameters
- Sets up maximum role holders and role ID
- Initializes empty self-assigned lists

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
    bytes[] memory calldatas,
    bytes memory stateChange
)
```
- Processes the self-assignment request
- Validates caller's role status
- Prepares role assignment/revocation call
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates self-assigned accounts list
- Maintains sorted list of accounts
- Handles both assignments and revocations

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and self-assigned accounts

### Error Conditions

1. **Role Assignment Errors**
   - "Account already has role"
   - "Max role holders reached"

2. **Role Revocation Errors**
   - "Account does not have role"

3. **Validation Errors**
   - Invalid role ID
   - Invalid caller address

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0x1C1dbed377bafA71CA935B40102Ea7A2C1D6ec8d  |
| 11155420  | Optimism Sepolia  | 0x1C1dbed377bafA71CA935B40102Ea7A2C1D6ec8d  |
| 11155111  | Ethereum Sepolia  | 0x1C1dbed377bafA71CA935B40102Ea7A2C1D6ec8d  | 



