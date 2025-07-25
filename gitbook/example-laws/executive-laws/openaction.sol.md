# OpenAction.sol

OpenAction.sol is an executive law that enables the execution of any function call to any contract. It provides a mechanism for unrestricted execution of arbitrary actions.

## Overview

This law provides a mechanism to:
- Execute any function call to any contract
- Pass any parameters to the target function
- Track execution history
- Enforce execution rules
- Maintain execution state

## Configuration

When adopting an OpenAction instance, no parameters are required. The law is completely open-ended and allows any function call to be executed.

## Usage

### Proposing an Action

When calling the law, three parameters must be provided:

1. `target` (address): The address of the contract to call
2. `value` (uint256): The amount of ETH to send with the call
3. `calldata` (bytes): The encoded function call data

### Execution Flow

1. **Parameter Validation**
   - Verifies the target address
   - Validates the calldata format
   - Checks execution conditions

2. **Function Execution**
   - Prepares the function call
   - Sends ETH if value > 0
   - Executes the call to target contract

3. **State Management**
   - Records execution history
   - Updates execution state
   - Tracks function calls

## Technical Specifications

### State Variables

```solidity
mapping(bytes32 lawHash => bool) public initialized;
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
- Sets up execution tracking
- Marks law as initialized

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
- Processes the function call request
- Validates target and calldata
- Prepares target contract call
- Returns execution data

### Error Conditions

1. **Function Call Errors**
   - "Invalid target"
   - "Invalid calldata"
   - "Function call failed"

2. **Parameter Errors**
   - "Invalid value"
   - "Invalid calldata format"
   - "Invalid parameter count"

3. **Validation Errors**
   - Zero address target
   - Invalid calldata
   - Invalid value amount

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xbe7F998c9d5BAe3AF7bD5Fc2CadB8ABaCeDf1379  |
| 11155420  | Optimism Sepolia  | 0xbe7F998c9d5BAe3AF7bD5Fc2CadB8ABaCeDf1379  |
| 11155111  | Ethereum Sepolia  | 0xbe7F998c9d5BAe3AF7bD5Fc2CadB8ABaCeDf1379  | 



