# StatementOfIntent.sol

StatementOfIntent.sol is an executive law that enables the creation of proposals without execution. It provides a mechanism to propose actions that can be executed by other laws.

## Overview

This law provides a mechanism to:
- Create proposals for future execution
- Store proposal parameters
- Track proposal history
- Enforce proposal rules
- Maintain proposal state

## Configuration

When adopting a StatementOfIntent instance, no parameters are required. The law is designed to only create proposals without executing them.

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
   - Checks proposal conditions

2. **Proposal Creation**
   - Creates a new proposal
   - Stores proposal parameters
   - Records proposal details

3. **State Management**
   - Updates proposal history
   - Maintains proposal state
   - Tracks proposal status

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] targets;    // Array of proposed targets
    uint256[] values;     // Array of proposed values
    bytes[] calldatas;    // Array of proposed calldata
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
- Sets up proposal tracking
- Initializes empty proposal storage

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
- Processes the proposal request
- Validates proposal parameters
- Prepares proposal data
- Returns execution data

### Error Conditions

1. **Proposal Errors**
   - "Invalid target"
   - "Invalid calldata"
   - "Invalid proposal"

2. **Parameter Errors**
   - "Invalid value"
   - "Invalid calldata format"
   - "Invalid parameter count"

3. **Validation Errors**
   - Zero address target
   - Invalid calldata
   - Invalid value amount

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x4d30c1B4f522af77d9208472af616bAE8E550615  |
| 11155420 | Optimism Sepolia | 0x7b42C3Ca539B47B339D2aE570386d0DAead252d6  |
| 11155111 | Ethereum Sepolia | 0x4d30c1B4f522af77d9208472af616bAE8E550615  | 



