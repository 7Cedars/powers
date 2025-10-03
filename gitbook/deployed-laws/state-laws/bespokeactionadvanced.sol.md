# BespokeActionAdvanced.sol

BespokeActionAdvanced.sol is an executive law that enables the execution of custom function calls with mixed static and dynamic parameters. It provides a mechanism to execute bespoke actions with pre-configured static parameters and user-provided dynamic parameters.

## Overview

This law provides a mechanism to:
- Execute custom function calls to any contract
- Mix static (pre-configured) and dynamic (user-provided) parameters
- Insert dynamic parameters at specific positions in the function call
- Support complex parameter structures
- Maintain execution flexibility

## Configuration

When adopting a BespokeActionAdvanced instance, five parameters must be provided:

1. `targetContract` (address): The address of the contract to call
2. `targetFunction` (bytes4): The function selector to call
3. `staticParams` (bytes[]): Array of pre-encoded static parameters
4. `dynamicParams` (string[]): Array of UI hints for dynamic parameters
5. `indexDynamicParams` (uint8[]): Array of insertion indices for dynamic parameters

## Usage

### Proposing an Action

When calling the law, an array of dynamic parameter values must be provided. The parameters are inserted into the function call at the positions specified by `indexDynamicParams`.

### Execution Flow

1. **Parameter Validation**
   - Verifies dynamic parameter count matches configuration
   - Validates parameter insertion indices
   - Checks function call structure

2. **Parameter Assembly**
   - Inserts dynamic parameters at specified positions
   - Combines with static parameters in correct order
   - Builds complete function calldata

3. **Function Execution**
   - Prepares the function call with assembled parameters
   - Executes call to target contract
   - Returns execution results

4. **State Management**
   - Records execution history
   - Updates execution state
   - Tracks function calls

## Technical Specifications

### State Variables

```solidity
struct Data {
    address targetContract;        // Target contract address
    bytes4 targetFunction;        // Function selector
    bytes[] staticParams;         // Pre-encoded static parameters
    string[] dynamicParams;       // UI hints for dynamic parameters
    uint8[] indexDynamicParams;   // Insertion indices for dynamic params
}

mapping(bytes32 => Data) internal _data;
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
- Sets up target contract and function
- Configures static and dynamic parameter structure
- Sets up parameter insertion indices

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
- Processes the function call request
- Assembles parameters from static and dynamic sources
- Builds complete function calldata
- Returns execution data

#### `_buildCalldata`
```solidity
function _buildCalldata(bytes32 lawHash, bytes memory lawCalldata) internal view returns (bytes memory)
```
- Builds complete calldata by inserting dynamic parameters
- Combines static and dynamic parameters in correct order
- Prefixes with function selector

### Error Conditions

1. **Parameter Errors**
   - "Bad Dynamic Length"
   - Invalid parameter count
   - Invalid parameter type

2. **Function Call Errors**
   - "Invalid function selector"
   - "Invalid calldata"
   - "Function call failed"

3. **Validation Errors**
   - Invalid target contract
   - Invalid function selector
   - Zero address target
   - Invalid parameter structure

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  |
| 11155420  | Optimism Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  |
| 11155111  | Ethereum Sepolia  | 0xac5fec8992EC477a1921EEBe13bb962FDf41a197  | 



