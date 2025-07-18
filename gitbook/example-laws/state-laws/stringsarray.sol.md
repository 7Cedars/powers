# StringsArray.sol

StringsArray.sol is a state law that provides an array of strings for storing and managing text-based data. It enables the storage and retrieval of string values in an ordered list.

## Overview

This law provides a mechanism to:
- Store string values
- Manage string array
- Add/remove strings
- Track string history
- Query string data

## Configuration

When adopting a StringsArray instance, no parameters are required. The law is designed to be a simple string storage mechanism.

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `value` (string): The string value to add/remove
2. `add` (bool): 
   - `true`: Add the string to the array
   - `false`: Remove the string from the array

### Execution Flow

1. **String Validation**
   - Verifies the string value
   - Checks current array state
   - Validates operation conditions

2. **Array Update**
   - Updates the string array
   - Records the change
   - Maintains array order

3. **State Management**
   - Updates array state
   - Tracks string history
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    string[] values;                    // Array of string values
    mapping(string => bool) exists;     // Existence check for strings
    mapping(string => uint256) index;   // Index of each string
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
- Sets up empty string array
- Initializes string tracking

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
- Processes the string update request
- Validates string and operation
- Prepares array update
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates string array
- Maintains string indices
- Records state changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all string values

### Error Conditions

1. **String Errors**
   - "Invalid string"
   - "String already exists"
   - "String not found"

2. **Array Errors**
   - "Array full"
   - "Invalid index"
   - "Invalid operation"

3. **Validation Errors**
   - Empty string
   - Invalid state
   - Invalid update

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0xb1115dA4fF650AA685600B37A23009B2cDeCc830  |
| 11155420 | Optimism Sepolia | 0x198705747E88b84D8CbC3531267Bb1e79ab26c2f  |
| 11155111 | Ethereum Sepolia | 0xb1115dA4fF650AA685600B37A23009B2cDeCc830  | 



