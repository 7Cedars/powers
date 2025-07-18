# VoteOnNominees.sol

VoteOnNominees.sol is a state law that enables voting on nominees for various roles or positions. It provides a mechanism to collect and track votes for nominated accounts.

## Overview

This law provides a mechanism to:
- Record votes for nominees
- Track voting history
- Manage vote counts
- Enforce voting rules
- Query vote results

## Configuration

When adopting a VoteOnNominees instance, no parameters are required. The law is designed to be a flexible voting mechanism.

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `nominee` (address): The address of the nominee to vote for
2. `vote` (bool): 
   - `true`: Vote for the nominee
   - `false`: Remove vote from the nominee

### Execution Flow

1. **Vote Validation**
   - Verifies the nominee address
   - Checks voter eligibility
   - Validates vote conditions

2. **Vote Processing**
   - Records the vote
   - Updates vote counts
   - Maintains voting history

3. **State Management**
   - Updates vote registry
   - Tracks nominee votes
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    mapping(address => uint256) voteCounts;  // Number of votes per nominee
    mapping(address => mapping(address => bool)) hasVoted;  // Voter to nominee votes
    address[] nominees;                      // List of all nominees
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
- Sets up vote tracking
- Initializes empty vote registry

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
- Validates nominee and vote
- Prepares vote recording
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates vote counts
- Maintains nominee list
- Records vote changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all vote counts

### Error Conditions

1. **Vote Errors**
   - "Invalid nominee"
   - "Already voted"
   - "Vote not found"

2. **Nominee Errors**
   - "Invalid nominee address"
   - "Nominee not found"
   - "Invalid nominee state"

3. **Validation Errors**
   - Zero address nominee
   - Invalid vote
   - Invalid state change

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x84172AC5E14dC09f8E506975D63be04A7d828356  |
| 11155420 | Optimism Sepolia | 0x063796FCD3767AD811e2A806Ed324a354395Ab52  |
| 11155111 | Ethereum Sepolia | 0x84172AC5E14dC09f8E506975D63be04A7d828356  | 



