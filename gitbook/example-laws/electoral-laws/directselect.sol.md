# DirectSelect.sol

DirectSelect.sol is an electoral law that enables direct assignment or revocation of a specific role to any account. It provides a mechanism for authorized accounts to manage role assignments without requiring nominations.

## Overview

This law provides a mechanism to:
- Directly assign a specific role to any account
- Directly revoke a role from any account
- Track directly assigned accounts
- Enforce maximum role holder limits

## Configuration

When adopting a DirectSelect instance, two parameters must be provided:

1. `maxRoleHolders` (uint256): Maximum number of accounts that can be assigned the role
2. `roleID` (uint256): The role ID that can be directly assigned/revoked

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `target` (address): The account to assign/revoke the role from
2. `assign` (bool): 
   - `true`: Assign the role to the target
   - `false`: Revoke the role from the target

### Execution Flow

1. **Target Validation**
   - Verifies the target address
   - Checks target's current role status
   - Validates maximum role holders limit

2. **Role Assignment**
   - If `assign` is true:
     - Checks if target already has the role
     - Verifies maximum role holders limit
     - Assigns role if conditions are met
   - If `assign` is false:
     - Verifies target has the role
     - Revokes role if conditions are met

3. **State Management**
   - Updates directly assigned accounts list
   - Maintains sorted list of accounts
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxRoleHolders;    // Maximum number of role holders allowed
    uint256 roleId;           // Role ID to directly assign/revoke
    address[] directAssigned; // List of directly assigned accounts
    address[] directAssignedSorted;  // Sorted list of directly assigned accounts
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
- Initializes empty directly assigned lists

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
- Processes the direct assignment request
- Validates target's role status
- Prepares role assignment/revocation call
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates directly assigned accounts list
- Maintains sorted list of accounts
- Handles both assignments and revocations

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and directly assigned accounts

### Error Conditions

1. **Role Assignment Errors**
   - "Account already has role"
   - "Max role holders reached"

2. **Role Revocation Errors**
   - "Account does not have role"

3. **Validation Errors**
   - Invalid role ID
   - Invalid target address
   - Zero address target

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155420  | Optimism Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155111  | Ethereum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  | 



