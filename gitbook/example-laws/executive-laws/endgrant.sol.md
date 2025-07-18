# EndGrant.sol

EndGrant.sol is an executive law that enables the termination of grant programs. It provides a mechanism to end active grants and handle remaining funds according to specified rules.

## Overview

This law provides a mechanism to:
- Terminate active grant programs
- Process remaining grant funds
- Handle grant closure rules
- Track grant termination history
- Enforce termination conditions

## Configuration

When adopting an EndGrant instance, three parameters must be provided:

1. `grantToken` (address): The token being distributed as grants
2. `returnAddress` (address): Address to return remaining funds to
3. `minDuration` (uint256): Minimum duration before grant can be ended

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `recipient` (address): The grant recipient to end grant for
2. `end` (bool): 
   - `true`: End the grant
   - `false`: Cancel grant termination

### Execution Flow

1. **Grant Validation**
   - Verifies grant is active
   - Validates minimum duration
   - Checks termination conditions

2. **Grant Termination**
   - If `end` is true:
     - Ends grant for recipient
     - Processes remaining funds
     - Records termination
   - If `end` is false:
     - Cancels termination
     - Updates grant status

3. **State Management**
   - Updates grant registry
   - Maintains termination history
   - Tracks fund returns

## Technical Specifications

### State Variables

```solidity
struct Data {
    address grantToken;      // Token being distributed
    address returnAddress;   // Address to return funds to
    uint256 minDuration;     // Minimum grant duration
    address[] terminated;    // List of terminated grants
    mapping(address => uint256) terminationTime; // When grant ended
    mapping(address => uint256) returnedAmount; // Amount returned
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
- Sets up termination rules
- Initializes empty termination tracking

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
- Processes the termination request
- Validates grant status
- Prepares fund return
- Returns execution data

### Error Conditions

1. **Termination Errors**
   - "Grant not active"
   - "Minimum duration not met"
   - "Grant already ended"

2. **Recipient Errors**
   - "Invalid recipient"
   - "No active grant"
   - "Invalid termination"

3. **Validation Errors**
   - Invalid token address
   - Invalid return address
   - Zero address recipient
   - Invalid grant status

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x7b4B4dFCee8fe1Fb2f95121f8925e17a9f72F07F  |
| 11155420 | Optimism Sepolia | 0x7A44e32e9E171e4F856602b95D636947C1dC0D61  |
| 11155111 | Ethereum Sepolia | 0x7b4B4dFCee8fe1Fb2f95121f8925e17a9f72F07F  | 

 