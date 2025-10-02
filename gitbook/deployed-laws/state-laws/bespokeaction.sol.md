# BespokeAction.sol

BespokeAction.sol is an executive law that enables the execution of a single, predefined function call to a target contract. It provides a mechanism to execute custom actions with specific parameters.

## Overview

This law provides a mechanism to:
- Execute a single function call to a target contract
- Pass custom parameters to the target function
- Track execution history
- Enforce execution rules
- Maintain execution state

## Configuration

When adopting a BespokeAction instance, three parameters must be provided:

1. `targetContract` (address): The address of the contract to call
2. `targetFunction` (bytes4): The function selector to call
3. `params` (string[]): Array of parameter names for the function

## Usage

### Proposing an Action

When calling the law, the parameters must match the function signature of the target function. The parameters are passed as calldata without the function signature.

### Execution Flow

1. **Parameter Validation**
   - Verifies the calldata matches the target function
   - Validates parameter types and values
   - Checks execution conditions

2. **Function Execution**
   - Prepares the function call
   - Encodes the calldata with function selector
   - Executes the call to target contract

3. **State Management**
   - Records execution history
   - Updates execution state
   - Tracks function calls

## Technical Specifications

### State Variables

```solidity
mapping(bytes32 lawHash => address targetContract) public targetContract;
mapping(bytes32 lawHash => bytes4 targetFunction) public targetFunction;
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
- Sets up target contract and function
- Stores parameter names

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
- Validates calldata
- Prepares target contract call
- Returns execution data

### Error Conditions

1. **Function Call Errors**
   - "Invalid function selector"
   - "Invalid calldata"
   - "Function call failed"

2. **Parameter Errors**
   - "Invalid parameter count"
   - "Invalid parameter type"
   - "Invalid parameter value"

3. **Validation Errors**
   - Invalid target contract
   - Invalid function selector
   - Zero address target
   - Invalid calldata format

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  |
| 11155420  | Optimism Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  |
| 11155111  | Ethereum Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  | 



