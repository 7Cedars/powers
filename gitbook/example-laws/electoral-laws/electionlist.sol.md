# ElectionList.sol

ElectionList.sol is an electoral law that manages the list of nominees for an election and allows voters to cast their votes for a single nominee. It integrates with NominateMe.sol and ElectionStart.sol to coordinate the election process.

## Overview

This law provides a mechanism to:
- Load a list of nominees from a NominateMe contract
- Allow voters to cast a single vote for a nominee
- Track votes and prevent double voting
- Enforce election start and end periods

## Configuration

When adopting an ElectionList instance, the following parameter must be provided:

1. `readStateFrom` (uint16): The law ID of the ElectionStart law to read election configuration and nominee list from

## Usage

### Proposing an Action

When calling the law, a single parameter must be provided:

1. `vote` (bool[]): An array of booleans, one for each nominee, where only one value can be true (the selected nominee)

### Execution Flow

1. **Nominee and Election Validation**
   - Loads nominees from the linked NominateMe contract
   - Checks that the election is active (between start and end blocks)

2. **Vote Validation**
   - Ensures the voter has not already voted
   - Ensures only one nominee is selected

3. **Vote Processing**
   - Records the vote for the selected nominee
   - Marks the voter as having voted

4. **State Management**
   - Updates vote counts for nominees
   - Tracks voting history

## Technical Specifications

### State Variables

```solidity
struct Data {
    mapping(address nominee => uint256 votes) votes;
    mapping(address voter => bool voted) voted;
    address[] nominees;
    uint48 startElection;
    uint48 endElection;
    uint16 roleId;
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
- Loads nominees and election period from ElectionStart and NominateMe

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
- Processes the vote request
- Validates voter and election status
- Prepares state change for vote recording

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates vote counts and voting history

#### `getElectionData`
```solidity
function getElectionData(bytes32 lawHash) public view returns (
    address[] memory nominees,
    uint48 startElection,
    uint48 endElection
)
```
- Returns the current list of nominees and election period

#### `getElectionTally`
```solidity
function getElectionTally(bytes32 lawHash) public view returns (
    address[] memory nominees,
    uint256[] memory votes
)
```
- Returns the current vote tally for each nominee

### Error Conditions

1. **Voting Errors**
   - "Voter has already voted."
   - "Election has not started yet."
   - "Election has ended."
   - "Voter has voted for more than one nominee."

2. **Validation Errors**
   - Invalid nominee list
   - Invalid election period

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 