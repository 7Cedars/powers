# DirectDeselect.sol

DirectDeselect.sol is an electoral law that enables authorized accounts to directly revoke a specific role from any account. It provides a mechanism for role management without requiring nominations or voting.

## Overview

This law provides a mechanism to:
- Allow authorized accounts to revoke roles
- Process direct role revocation requests
- Track revocation history
- Maintain role holder statistics
- Enforce revocation rules

## Configuration

When adopting a DirectDeselect instance, two parameters must be provided:

1. `roleID` (uint256): The role ID that can be revoked
2. `revokerRoleID` (uint256): The role ID required to revoke roles

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `target` (address): The account to revoke the role from
2. `revoke` (bool): 
   - `true`: Process role revocation
   - `false`: Cancel revocation request

### Execution Flow

1. **Authorization Validation**
   - Verifies the caller has revoker role
   - Checks target's role status
   - Validates revocation eligibility

2. **Revocation Processing**
   - If `revoke` is true:
     - Revokes role from target
     - Updates role holder statistics
     - Records revocation
   - If `revoke` is false:
     - Cancels pending revocation
     - Updates revocation status

3. **State Management**
   - Updates role holder list
   - Maintains revocation history
   - Records role statistics

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 roleId;         // Role ID that can be revoked
    uint256 revokerRoleId;  // Role ID required to revoke
    address[] roleHolders;  // List of current role holders
    mapping(address => bool) pendingRevocation; // Pending revocation status
    mapping(address => uint256) revocationCount; // Number of revocations by revoker
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
- Sets up role IDs and revocation requirements
- Initializes empty role holder tracking

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
- Processes the revocation request
- Validates revoker and target status
- Prepares role revocation
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates role holder list
- Maintains revocation history
- Records role statistics

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and role data

### Error Conditions

1. **Authorization Errors**
   - "Not a revoker"
   - "Invalid revoker role"
   - "Revocation not allowed"

2. **Target Errors**
   - "Target not a role holder"
   - "Invalid target"
   - "Cannot revoke self"

3. **Revocation Errors**
   - "No pending revocation"
   - "Revocation not allowed"
   - "Invalid revocation"

4. **Validation Errors**
   - Invalid role ID
   - Invalid revoker role ID
   - Zero address target
   - Invalid revocation status

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0xDBEf9280dd21d318Ea3b8af18Fe5fC72D7a347eE  |
| 11155420 | Optimism Sepolia | 0x9e21b95913c20aD8FB8114Bb950245AEDE1B3735  |
| 11155111 | Ethereum Sepolia | 0xDBEf9280dd21d318Ea3b8af18Fe5fC72D7a347eE  | 

 