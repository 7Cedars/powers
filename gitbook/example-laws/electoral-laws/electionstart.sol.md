# ElectionStart.sol

ElectionStart.sol is an electoral law that initiates an election process by setting up the election period, linking to a nominee list, and preparing subsequent voting and tallying laws.

## Overview

This law provides a mechanism to:
- Start an election by specifying the start and end block numbers
- Link to a NominateMe law for candidate nominations
- Deploy and configure ElectionList and ElectionTally laws for voting and tallying
- Store and expose election configuration data

## Configuration

When adopting an ElectionStart instance, four parameters must be provided:

1. `electionListAddress` (address): The address of the ElectionList law to be used for voting
2. `electionTallyAddress` (address): The address of the ElectionTally law to be used for tallying
3. `roleId` (uint16): The role ID to be assigned to winners
4. `maxToElect` (uint32): The maximum number of winners to elect

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `startElection` (uint48): The block number when the election starts
2. `endElection` (uint48): The block number when the election ends

### Execution Flow

1. **Input Validation**
   - Checks that start and end blocks are valid and in the future
   - Ensures a valid NominateMe contract is linked

2. **Law Deployment**
   - Deploys ElectionList and ElectionTally laws with the provided configuration
   - Sets up voting and tallying conditions

3. **State Management**
   - Stores election configuration and nominee list references
   - Exposes election data for downstream laws

## Technical Specifications

### State Variables

```solidity
struct Data {
    address electionListAddress;
    address electionTallyAddress;
    uint48 startElection;
    uint48 endElection;
    uint16 roleId;
    uint32 maxToElect;
    address nominateMeAddress;
    bytes32 nominateMeHash;
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
- Sets up election period and links to nominee and voting/tallying laws

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
- Processes the election start request
- Validates input and nominee contract
- Prepares calls to deploy ElectionList and ElectionTally laws
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates election configuration and nominee references

#### `getElectionData`
```solidity
function getElectionData(bytes32 lawHash) public view returns (
    uint48 startElection,
    uint48 endElection,
    uint16 roleId,
    uint32 maxToElect,
    address nominateMeAddress,
    bytes32 nominateMeHash
)
```
- Returns the current state of the election configuration

### Error Conditions

1. **Input Errors**
   - "No valid start or end election provided."
   - "Start election is after end election."
   - "No valid nominees contract provided"

2. **Deployment Errors**
   - Failure to deploy ElectionList or ElectionTally

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 