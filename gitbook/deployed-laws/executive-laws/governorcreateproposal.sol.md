# GovernorCreateProposal.sol

GovernorCreateProposal.sol is an executive law that enables the creation of governance proposals on a configured Governor contract. It provides a mechanism to create proposals that can be voted on through standard governance processes.

## Overview

This law provides a mechanism to:
- Create governance proposals on any Governor contract
- Define proposal targets, values, and calldatas
- Add human-readable descriptions to proposals
- Integrate with standard governance frameworks
- Track proposal creation

## Configuration

When adopting a GovernorCreateProposal instance, one parameter must be provided:

1. `governorContract` (address): The address of the Governor contract to create proposals on

## Usage

### Proposing an Action

When calling the law, four parameters must be provided:

1. `targets` (address[]): Array of target contract addresses for the proposal
2. `values` (uint256[]): Array of ETH values to send with each call
3. `calldatas` (bytes[]): Array of encoded function call data
4. `description` (string): Human-readable description of the proposal

### Execution Flow

1. **Parameter Validation**
   - Verifies governor contract is configured
   - Validates proposal parameters
   - Checks array length consistency
   - Ensures description is not empty

2. **Proposal Creation**
   - Encodes proposal parameters
   - Creates call to Governor.propose function
   - Prepares execution data

3. **State Management**
   - Records proposal creation
   - Updates governance state
   - Tracks proposal history

## Technical Specifications

### State Variables

```solidity
mapping(bytes32 lawHash => address governorContract) public governorContracts;
```

### Functions

#### `initializeLaw`
```solidity
function initializeLaw(
    uint16 index,
    string memory nameDescription,
    bytes memory inputParams,
    bytes memory config
) public override
```
- Initializes law with configuration parameters
- Sets up Governor contract address
- Configures proposal creation parameters

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
    bytes[] memory calldatas
)
```
- Processes the proposal creation request
- Validates proposal parameters
- Prepares call to Governor.propose
- Returns execution data

### Error Conditions

1. **Configuration Errors**
   - "GovernorCreateProposal: Governor contract not configured"
   - Invalid governor contract address

2. **Parameter Errors**
   - "GovernorCreateProposal: No targets provided"
   - "GovernorCreateProposal: Targets and values length mismatch"
   - "GovernorCreateProposal: Targets and calldatas length mismatch"
   - "GovernorCreateProposal: Description cannot be empty"

3. **Validation Errors**
   - Zero address governor contract
   - Empty targets array
   - Mismatched array lengths
   - Empty description

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155420  | Optimism Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155111  | Ethereum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  | 



