# NominateMe.sol

NominateMe.sol is a state law that enables accounts to self-nominate for roles or positions. It provides a mechanism for accounts to register themselves as nominees and manage their nomination status.

## Overview

This law provides a mechanism to:
- Register self-nominations
- Track nominee status
- Manage nominee list
- Enforce nomination rules
- Query nominee information

## Configuration

When adopting a NominateMe instance, no parameters are required. The law is designed to be a self-service nomination mechanism.

## Usage

### Proposing an Action

When calling the law, one parameter must be provided:

1. `nominate` (bool): 
   - `true`: Register as a nominee
   - `false`: Remove nomination

### Execution Flow

1. **Nomination Validation**
   - Verifies caller eligibility
   - Checks current nomination status
   - Validates nomination conditions

2. **Nomination Processing**
   - Records the nomination
   - Updates nominee list
   - Maintains nomination history

3. **State Management**
   - Updates nominee registry
   - Tracks nomination status
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] nominees;                      // List of all nominees
    mapping(address => bool) isNominee;      // Nomination status per address
    mapping(address => uint256) nominationTime; // When address was nominated
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
- Sets up nominee tracking
- Initializes empty nominee registry

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
- Processes the nomination request
- Validates caller and nomination
- Prepares nomination recording
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates nominee list
- Maintains nomination status
- Records state changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all nominee information

### Error Conditions

1. **Nomination Errors**
   - "Already nominated"
   - "Not nominated"
   - "Invalid nomination"

2. **Status Errors**
   - "Invalid status"
   - "Status unchanged"
   - "Invalid state change"

3. **Validation Errors**
   - Zero address
   - Invalid nomination
   - Invalid state

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0x53Fa2e3Da143d47359ecb0C0F45fcae928931dc8  |
| 11155420  | Optimism Sepolia  | 0x53Fa2e3Da143d47359ecb0C0F45fcae928931dc8  |
| 11155111  | Ethereum Sepolia  | 0x53Fa2e3Da143d47359ecb0C0F45fcae928931dc8  | 



