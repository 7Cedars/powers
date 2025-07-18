# StartGrant.sol

StartGrant.sol is an executive law that enables the initiation of grant programs. It provides a mechanism to set up and start new grant distributions with specific parameters and conditions.

## Overview

This law provides a mechanism to:
- Initialize grant programs
- Set grant parameters and conditions
- Configure grant distribution rules
- Track grant program status
- Enforce grant rules

## Configuration

When adopting a StartGrant instance, four parameters must be provided:

1. `grantToken` (address): The token to be distributed as grants
2. `totalAmount` (uint256): Total amount of tokens to be distributed
3. `duration` (uint256): Duration of the grant program
4. `maxRecipients` (uint256): Maximum number of grant recipients

## Usage

### Proposing an Action

When calling the law, three parameters must be provided:

1. `recipient` (address): The address to receive the grant
2. `amount` (uint256): Amount of tokens to grant
3. `start` (bool): 
   - `true`: Start the grant program
   - `false`: Cancel grant program start

### Execution Flow

1. **Grant Validation**
   - Verifies grant parameters
   - Validates recipient eligibility
   - Checks grant conditions

2. **Grant Initialization**
   - If `start` is true:
     - Initializes grant program
     - Sets up distribution parameters
     - Records grant details
   - If `start` is false:
     - Cancels grant program
     - Updates program status

3. **State Management**
   - Updates grant registry
   - Maintains recipient list
   - Tracks grant status

## Technical Specifications

### State Variables

```solidity
struct Data {
    address grantToken;      // Token to be distributed
    uint256 totalAmount;     // Total grant amount
    uint256 duration;        // Program duration
    uint256 maxRecipients;   // Max number of recipients
    address[] recipients;    // List of grant recipients
    mapping(address => uint256) grantAmounts; // Amount per recipient
    mapping(address => uint256) grantStartTime; // When grant started
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
- Sets up grant parameters
- Initializes empty recipient tracking

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
- Validates grant parameters
- Prepares grant distribution
- Returns execution data

### Error Conditions

1. **Grant Errors**
   - "Invalid grant amount"
   - "Max recipients reached"
   - "Grant already started"

2. **Recipient Errors**
   - "Invalid recipient"
   - "Recipient already has grant"
   - "Invalid recipient amount"

3. **Validation Errors**
   - Invalid token address
   - Invalid grant parameters
   - Zero address recipient
   - Invalid grant status

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x07A2FCC652E91B0e80a34F671213C08e5A5180fc  |
| 11155420 | Optimism Sepolia | 0x7A44e32e9E171e4F856602b95D636947C1dC0D61  |
| 11155111 | Ethereum Sepolia | 0x07A2FCC652E91B0e80a34F671213C08e5A5180fc  | 

 