# RandomlySelect.sol

RandomlySelect.sol is an electoral law that enables random selection of accounts from a pool of candidates to assign a specific role. It uses a verifiable random number generation mechanism to ensure fair and transparent selection.

## Overview

This law provides a mechanism to:
- Maintain a pool of eligible candidates
- Generate verifiable random numbers
- Select random winners from the candidate pool
- Assign roles to randomly selected winners
- Track selection history and statistics

## Configuration

When adopting a RandomlySelect instance, three parameters must be provided:

1. `maxWinners` (uint256): Maximum number of winners that can be selected
2. `roleID` (uint256): The role ID to be assigned to winners
3. `minCandidates` (uint256): Minimum number of candidates required for selection

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `candidate` (address): The candidate to add/remove from the pool
2. `add` (bool): 
   - `true`: Add candidate to the pool
   - `false`: Remove candidate from the pool

### Execution Flow

1. **Candidate Validation**
   - Verifies the candidate address
   - Checks if candidate is already in pool
   - Validates pool size limits

2. **Pool Management**
   - If `add` is true:
     - Adds candidate to pool
     - Updates pool statistics
   - If `add` is false:
     - Removes candidate from pool
     - Updates pool statistics

3. **Random Selection**
   - Generates verifiable random number
   - Selects winners from pool
   - Assigns roles to winners
   - Records selection results

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxWinners;      // Maximum number of winners allowed
    uint256 roleId;         // Role ID to assign to winners
    uint256 minCandidates;  // Minimum candidates required
    address[] candidates;   // List of candidates
    address[] winners;      // List of winners
    mapping(address => bool) isCandidate; // Candidate status
    uint256 lastSelection;  // Timestamp of last selection
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
- Sets up role ID and selection requirements
- Initializes empty candidate pool

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
- Processes the candidate management request
- Validates candidate status
- Prepares role assignments for winners
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates candidate pool
- Maintains winner list
- Records selection history

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and selection data

### Error Conditions

1. **Candidate Errors**
   - "Invalid candidate"
   - "Already in pool"
   - "Not in pool"

2. **Selection Errors**
   - "Insufficient candidates"
   - "Selection not ready"
   - "Invalid selection"

3. **Role Assignment Errors**
   - "Max winners reached"
   - "Invalid winner"

4. **Validation Errors**
   - Invalid role ID
   - Invalid candidate address
   - Zero address candidate
   - Invalid pool size

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 



