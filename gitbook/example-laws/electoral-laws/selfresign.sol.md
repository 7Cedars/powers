# SelfResign.sol

SelfResign.sol is an electoral law that allows accounts to voluntarily resign from a specific role. It provides a mechanism for role holders to self-revoke their role assignment.

## Overview

This law provides a mechanism to:
- Allow role holders to voluntarily resign
- Process self-resignation requests
- Track resignation history
- Maintain role holder statistics
- Enforce resignation rules

## Configuration

When adopting a SelfResign instance, two parameters must be provided:

1. `roleID` (uint256): The role ID that can be resigned from
2. `minHoldTime` (uint256): Minimum time a role must be held before resignation

## Usage

### Proposing an Action

When calling the law, one parameter must be provided:

1. `resign` (bool): 
   - `true`: Process resignation request
   - `false`: Cancel resignation request

### Execution Flow

1. **Role Validation**
   - Verifies the caller has the role
   - Checks minimum hold time requirement
   - Validates resignation eligibility

2. **Resignation Processing**
   - If `resign` is true:
     - Revokes role from caller
     - Updates role holder statistics
     - Records resignation
   - If `resign` is false:
     - Cancels pending resignation
     - Updates resignation status

3. **State Management**
   - Updates role holder list
   - Maintains resignation history
   - Records role statistics

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 roleId;         // Role ID that can be resigned from
    uint256 minHoldTime;    // Minimum time role must be held
    address[] roleHolders;  // List of current role holders
    mapping(address => uint256) holdStartTime; // When role was assigned
    mapping(address => bool) pendingResignation; // Pending resignation status
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
- Sets up role ID and hold time requirements
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
- Processes the resignation request
- Validates role holder status
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
- Maintains resignation history
- Records role statistics

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and role data

### Error Conditions

1. **Role Errors**
   - "Not a role holder"
   - "Invalid role"
   - "Role not held long enough"

2. **Resignation Errors**
   - "No pending resignation"
   - "Resignation not allowed"
   - "Invalid resignation"

3. **Validation Errors**
   - Invalid role ID
   - Invalid hold time
   - Zero address caller
   - Invalid resignation status

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 



