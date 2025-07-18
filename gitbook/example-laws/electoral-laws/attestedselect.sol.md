# AttestedSelect.sol

AttestedSelect.sol is an electoral law that enables role assignment based on attestations. It allows accounts to be assigned roles only after receiving a required number of attestations from other accounts with specific attestation roles.

## Overview

This law provides a mechanism to:
- Assign roles based on attestations
- Track attestations for each account
- Enforce minimum attestation requirements
- Manage attestation roles
- Enforce maximum role holder limits

## Configuration

When adopting an AttestedSelect instance, four parameters must be provided:

1. `maxRoleHolders` (uint256): Maximum number of accounts that can be assigned the role
2. `roleID` (uint256): The role ID that can be assigned through attestations
3. `attestorRoleID` (uint256): The role ID required to provide attestations
4. `minAttestations` (uint256): Minimum number of attestations required for role assignment

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `target` (address): The account to attest for/against
2. `attest` (bool): 
   - `true`: Provide a positive attestation
   - `false`: Provide a negative attestation

### Execution Flow

1. **Attestation Validation**
   - Verifies the attestor has the required role
   - Checks if attestor has already attested
   - Validates attestation status

2. **Target Validation**
   - Verifies the target address
   - Checks target's current role status
   - Validates maximum role holders limit

3. **Attestation Processing**
   - If `attest` is true:
     - Records positive attestation
     - Checks if minimum attestations reached
     - Assigns role if conditions are met
   - If `attest` is false:
     - Records negative attestation
     - Removes existing attestations if any

4. **State Management**
   - Updates attestation counts
   - Maintains list of attested accounts
   - Records attestation history

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxRoleHolders;    // Maximum number of role holders allowed
    uint256 roleId;           // Role ID to assign through attestations
    uint256 attestorRoleId;   // Role ID required to provide attestations
    uint256 minAttestations;  // Minimum attestations required
    address[] attestedAccounts; // List of attested accounts
    mapping(address => uint256) attestationCounts; // Count of attestations per account
    mapping(address => mapping(address => bool)) hasAttested; // Attestation history
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
- Sets up role IDs and attestation requirements
- Initializes empty attestation tracking

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
- Processes the attestation request
- Validates attestor and target status
- Prepares role assignment if conditions met
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates attestation counts
- Maintains attested accounts list
- Records attestation history

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and attestation data

### Error Conditions

1. **Attestation Errors**
   - "Not an attestor"
   - "Already attested"
   - "Invalid attestation"

2. **Role Assignment Errors**
   - "Account already has role"
   - "Max role holders reached"
   - "Insufficient attestations"

3. **Validation Errors**
   - Invalid role ID
   - Invalid target address
   - Zero address target
   - Invalid attestation count

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 

