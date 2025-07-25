# PeerSelect.sol

PeerSelect.sol is an electoral law that enables the selection of accounts from a list of nominees to assign or revoke a specific role. It integrates with NominateMe.sol to manage the nomination process.

## Overview

This law provides a mechanism to:
- Select accounts from a list of nominees
- Assign or revoke a specific role ID
- Track elected accounts and maintain a sorted list
- Enforce maximum role holder limits

## Configuration

When adopting a PeerSelect instance, three parameters must be provided:

1. `maxRoleHolders` (uint256): Maximum number of accounts that can be assigned the role
2. `roleID` (uint256): The role ID that can be assigned/revoked
3. `readStateFrom` (address): Address of the NominateMe.sol instance to read nominees from

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `NomineeIndex` (uint256): Index of the nominee in the nominee list
2. `assign` (bool): 
   - `true`: Assign the role to the nominee
   - `false`: Revoke the role from the nominee

### Execution Flow

1. **Nominee Validation**
   - Loads nominee data from NominateMe.sol instance
   - Retrieves nominee address from the list
   - Verifies nominee exists at the specified index

2. **Role Assignment**
   - If `assign` is true:
     - Checks if nominee already has the role
     - Verifies maximum role holders limit
     - Assigns role if conditions are met
   - If `assign` is false:
     - Verifies nominee has the role
     - Revokes role if conditions are met

3. **State Management**
   - Updates elected accounts list
   - Maintains sorted list of elected accounts
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxRoleHolders;    // Maximum number of role holders allowed
    uint256 roleId;           // Role ID to assign/revoke
    address[] elected;        // List of elected accounts
    address[] electedSorted;  // Sorted list of elected accounts
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
- Initializes empty elected lists

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
- Processes the selection request
- Validates nominee and role status
- Prepares role assignment/revocation call
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates elected accounts list
- Maintains sorted list of elected accounts
- Handles both assignments and revocations

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and elected accounts

### Error Conditions

1. **Role Assignment Errors**
   - "Account already has role"
   - "Max role holders reached"

2. **Role Revocation Errors**
   - "Account does not have role"

3. **Validation Errors**
   - Invalid nominee index
   - Invalid role ID
   - Invalid NominateMe instance

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0x9f31dcac5429716128D667850d9c704af811f430  |
| 11155420  | Optimism Sepolia  | 0x9f31dcac5429716128D667850d9c704af811f430  |
| 11155111  | Ethereum Sepolia  | 0x9f31dcac5429716128D667850d9c704af811f430  | 



