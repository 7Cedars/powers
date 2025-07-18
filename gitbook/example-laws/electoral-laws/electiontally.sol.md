# ElectionTally.sol

ElectionTally.sol is an electoral law that manages the tallying of votes in an election. It provides a mechanism to count votes, determine winners, and assign roles based on election results.

## Overview

This law provides a mechanism to:
- Count and validate votes in an election
- Determine winners based on vote counts
- Assign roles to election winners
- Track election results and statistics
- Enforce election rules and constraints

## Configuration

When adopting an ElectionTally instance, four parameters must be provided:

1. `maxWinners` (uint256): Maximum number of winners that can be assigned the role
2. `roleID` (uint256): The role ID to be assigned to winners
3. `voterRoleID` (uint256): The role ID required to vote
4. `minVotes` (uint256): Minimum number of votes required for a valid election

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `candidate` (address): The candidate to vote for
2. `vote` (bool): 
   - `true`: Cast a vote for the candidate
   - `false`: Remove a vote for the candidate

### Execution Flow

1. **Vote Validation**
   - Verifies the voter has the required role
   - Checks if voter has already voted
   - Validates vote status

2. **Candidate Validation**
   - Verifies the candidate address
   - Checks candidate's eligibility
   - Validates maximum winners limit

3. **Vote Processing**
   - If `vote` is true:
     - Records vote for candidate
     - Updates vote counts
     - Checks if minimum votes reached
   - If `vote` is false:
     - Removes vote for candidate
     - Updates vote counts

4. **Winner Determination**
   - Tallys all votes
   - Identifies top vote-getters
   - Assigns roles to winners
   - Records election results

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 maxWinners;      // Maximum number of winners allowed
    uint256 roleId;         // Role ID to assign to winners
    uint256 voterRoleId;    // Role ID required to vote
    uint256 minVotes;       // Minimum votes required
    address[] candidates;   // List of candidates
    address[] winners;      // List of winners
    mapping(address => uint256) voteCounts; // Vote counts per candidate
    mapping(address => bool) hasVoted; // Voting history
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
- Sets up role IDs and election requirements
- Initializes empty vote tracking

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
- Validates voter and candidate status
- Prepares role assignments for winners
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates vote counts
- Maintains candidate and winner lists
- Records voting history

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all configuration and election data

### Error Conditions

1. **Voting Errors**
   - "Not a voter"
   - "Already voted"
   - "Invalid vote"

2. **Election Errors**
   - "Insufficient votes"
   - "Invalid candidate"
   - "Election not active"

3. **Role Assignment Errors**
   - "Max winners reached"
   - "Invalid winner"

4. **Validation Errors**
   - Invalid role ID
   - Invalid candidate address
   - Zero address candidate
   - Invalid vote count

## Current Deployments

| Chain ID | Address  |
| -------  | -------- | 
|          |          | 



