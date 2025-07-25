# DelegateSelect.sol

DelegateSelect.sol is an electoral law that enables delegation-based role assignment. It allows accounts to delegate their role assignment rights to other accounts, who can then assign or revoke roles on their behalf.

## Overview

This law provides a mechanism to:
- Delegate role assignment rights to other accounts
- Assign roles through delegation
- Revoke roles through delegation
- Track delegated assignments and revocations
- Enforce maximum role holder limits

## Configuration

When adopting a DelegateSelect instance, three parameters must be provided:

1. `maxRoleHolders` (uint256): Maximum number of accounts that can be assigned the role
2. `roleID` (uint256): The role ID that can be assigned/revoked through delegation
3. `delegateRoleID` (uint256): The role ID required to act as a delegate

## Usage

### Proposing an Action

When calling the law, three parameters must be provided:

1. `target` (address): The account to assign/revoke the role from
2. `assign` (bool): 
   - `true`: Assign the role to the target
   - `false`: Revoke the role from the target
3. `delegator` (address): The account whose delegation rights are being used

### Execution Flow

1. **Delegation Validation**
   - Verifies the delegate has the required role
   - Checks if delegator has delegated their rights
   - Validates delegation status

2. **Target Validation**
   - Verifies the target address
   - Checks target's current role status
   - Validates maximum role holders limit

3. **Role Assignment**
   - If `assign` is true:
     - Checks if target already has the role
     - Verifies maximum role holders limit
     - Assigns role if conditions are met
   - If `assign` is false:
     - Verifies target has the role
     - Revokes role if conditions are met

4. **State Management**
   - Updates delegated assignments list
   - Maintains sorted list of accounts
   - Records delegation usage

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxRoleHolders;    // Maximum number of role holders allowed
    uint256 roleId;           // Role ID to assign/revoke
    uint256 delegateRoleId;   // Role ID required to act as delegate
    address[] delegatedAssigned; // List of delegated assignments
    address[] delegatedAssignedSorted;  // Sorted list of delegated assignments
    mapping(address => address) delegations; // Mapping of delegator to delegate
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
- Sets up maximum role holders and role IDs
- Initializes empty delegated assignment lists

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
- Processes the delegation-based assignment request
- Validates delegation and target status
- Prepares role assignment/revocation call
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates delegated assignments list
- Maintains sorted list of accounts
- Handles both assignments and revocations

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and delegated assignments

### Error Conditions

1. **Delegation Errors**
   - "Not a delegate"
   - "No delegation rights"
   - "Invalid delegator"

2. **Role Assignment Errors**
   - "Account already has role"
   - "Max role holders reached"

3. **Role Revocation Errors**
   - "Account does not have role"

4. **Validation Errors**
   - Invalid role ID
   - Invalid target address
   - Zero address target
   - Invalid delegation

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0x4cba41C3D34A6177659126517b9806ACeFA0F83C  |
| 11155420  | Optimism Sepolia  | 0x4cba41C3D34A6177659126517b9806ACeFA0F83C  |
| 11155111  | Ethereum Sepolia  | 0x4cba41C3D34A6177659126517b9806ACeFA0F83C  | 



