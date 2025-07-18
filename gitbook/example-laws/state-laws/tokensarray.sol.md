# TokensArray.sol

TokensArray.sol is a state law that provides an array of token addresses for storing and managing ERC20 token references. It enables the storage and retrieval of token addresses in an ordered list.

## Overview

This law provides a mechanism to:
- Store token addresses
- Manage token array
- Add/remove tokens
- Track token history
- Query token data

## Configuration

When adopting a TokensArray instance, no parameters are required. The law is designed to be a simple token address storage mechanism.

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `token` (address): The token address to add/remove
2. `add` (bool): 
   - `true`: Add the token to the array
   - `false`: Remove the token from the array

### Execution Flow

1. **Token Validation**
   - Verifies the token address
   - Checks current array state
   - Validates operation conditions

2. **Array Update**
   - Updates the token array
   - Records the change
   - Maintains array order

3. **State Management**
   - Updates array state
   - Tracks token history
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] tokens;                   // Array of token addresses
    mapping(address => bool) exists;    // Existence check for tokens
    mapping(address => uint256) index;  // Index of each token
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
- Sets up empty token array
- Initializes token tracking

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
- Processes the token update request
- Validates token and operation
- Prepares array update
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates token array
- Maintains token indices
- Records state changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all token addresses

### Error Conditions

1. **Token Errors**
   - "Invalid token"
   - "Token already exists"
   - "Token not found"

2. **Array Errors**
   - "Array full"
   - "Invalid index"
   - "Invalid operation"

3. **Validation Errors**
   - Zero address token
   - Invalid state
   - Invalid update

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x3E38A61C98204c6d507F7Df18015478fEe3ffA47  |
| 11155420 | Optimism Sepolia | 0x695e4B597c0615299c185A69c1874b18689A8702  |
| 11155111 | Ethereum Sepolia | 0x3E38A61C98204c6d507F7Df18015478fEe3ffA47  |



