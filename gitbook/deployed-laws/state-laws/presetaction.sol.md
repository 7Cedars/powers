# PresetAction.sol

PresetAction.sol is an executive law that enables the execution of a predefined set of function calls. It provides a mechanism to execute multiple actions in a specific order with fixed parameters.

## Overview

This law provides a mechanism to:
- Execute multiple function calls in sequence
- Use predefined target contracts and functions
- Pass fixed parameters to the functions
- Track execution history
- Enforce execution rules

## Configuration

When adopting a PresetAction instance, three parameters must be provided:

1. `targets` (address[]): Array of target contract addresses
2. `values` (uint256[]): Array of ETH values to send with each call
3. `calldatas` (bytes[]): Array of encoded function call data

## Usage

### Proposing an Action

When calling the law, no parameters are required. The law executes the predefined set of actions in the order they were configured.

### Execution Flow

1. **Configuration Validation**
   - Verifies target addresses
   - Validates calldata formats
   - Checks execution conditions

2. **Function Execution**
   - Executes each function call in sequence
   - Sends ETH if values > 0
   - Maintains execution order

3. **State Management**
   - Records execution history
   - Updates execution state
   - Tracks function calls

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] targets;    // Array of target contracts
    uint256[] values;     // Array of ETH values
    bytes[] calldatas;    // Array of function call data
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
- Sets up target contracts and functions
- Stores execution parameters

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
- Processes the execution request
- Validates configuration
- Prepares function calls
- Returns execution data

### Error Conditions

1. **Function Call Errors**
   - "Invalid target"
   - "Invalid calldata"
   - "Function call failed"

2. **Parameter Errors**
   - "Invalid value"
   - "Invalid calldata format"
   - "Array length mismatch"

3. **Validation Errors**
   - Zero address target
   - Invalid calldata
   - Invalid value amount

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0x81Bb430DF6ab37466270ECFE6f7c29B3D3e44A35  |
| 11155420  | Optimism Sepolia  | 0x81Bb430DF6ab37466270ECFE6f7c29B3D3e44A35  |
| 11155111  | Ethereum Sepolia  | 0x81Bb430DF6ab37466270ECFE6f7c29B3D3e44A35  | 



