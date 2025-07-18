# Grant.sol

Grant.sol is a state law that manages grant distributions and tracks grant-related data. It provides a mechanism to store and manage information about grants, including recipients, amounts, and status.

## Overview

This law provides a mechanism to:
- Store grant information
- Track grant distributions
- Manage grant status
- Record grant history
- Query grant data

## Configuration

When adopting a Grant instance, no parameters are required. The law is designed to be a comprehensive grant management mechanism.

## Usage

### Proposing an Action

When calling the law, three parameters must be provided:

1. `recipient` (address): The address to receive the grant
2. `amount` (uint256): The amount of tokens to grant
3. `grant` (bool): 
   - `true`: Create/update grant
   - `false`: Remove grant

### Execution Flow

1. **Grant Validation**
   - Verifies recipient address
   - Checks grant amount
   - Validates grant conditions

2. **Grant Processing**
   - Records grant information
   - Updates grant status
   - Maintains grant history

3. **State Management**
   - Updates grant registry
   - Tracks grant distributions
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] recipients;                // List of grant recipients
    mapping(address => uint256) amounts; // Grant amount per recipient
    mapping(address => uint256) grantTime; // When grant was made
    mapping(address => bool) active;     // Active grant status
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
- Sets up grant tracking
- Initializes empty grant registry

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
- Processes the grant request
- Validates recipient and amount
- Prepares grant recording
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates grant registry
- Maintains recipient list
- Records state changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all grant information

### Error Conditions

1. **Grant Errors**
   - "Invalid grant amount"
   - "Grant already exists"
   - "Grant not found"

2. **Recipient Errors**
   - "Invalid recipient"
   - "Recipient already has grant"
   - "Invalid recipient state"

3. **Validation Errors**
   - Zero address recipient
   - Zero amount
   - Invalid state

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x9B5576d05524c371010D44168349EcFcE39629Ac  |
| 11155420 | Optimism Sepolia | 0x2D16b04c012ffb94d73CAa6230d2bCb100035Fde  |
| 11155111 | Ethereum Sepolia | 0x9B5576d05524c371010D44168349EcFcE39629Ac  |



