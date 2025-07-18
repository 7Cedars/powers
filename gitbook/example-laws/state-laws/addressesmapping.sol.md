# AddressesMapping.sol

AddressesMapping.sol is a state law that provides a mapping of addresses to boolean values. It enables tracking and management of address-based permissions or statuses within the Powers protocol.

## Overview

This law provides a mechanism to:
- Store address-to-boolean mappings
- Track address statuses
- Manage address permissions
- Update address states
- Query address status

## Configuration

When adopting an AddressesMapping instance, no parameters are required. The law is designed to be a simple state storage mechanism.

## Usage

### Proposing an Action

When calling the law, two parameters must be provided:

1. `target` (address): The address to update
2. `value` (bool): The boolean value to set for the address

### Execution Flow

1. **Address Validation**
   - Verifies the target address
   - Checks current mapping state
   - Validates update conditions

2. **State Update**
   - Updates the mapping value
   - Records the change
   - Maintains state history

3. **State Management**
   - Updates mapping state
   - Tracks address status
   - Records state changes

## Technical Specifications

### State Variables

```solidity
struct Data {
    mapping(address => bool) addressMap;  // Mapping of addresses to boolean values
    address[] addresses;                  // List of all addresses in the mapping
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
- Sets up empty address mapping
- Initializes address tracking

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
- Processes the mapping update request
- Validates address and value
- Prepares state change
- Returns execution data

#### `_changeState`
```solidity
function _changeState(
    bytes32 lawHash,
    bytes memory stateChange
) internal override
```
- Updates address mapping
- Maintains address list
- Records state changes

#### `getData`
```solidity
function getData(bytes32 lawHash) public view returns (Data memory)
```
- Returns the current state of the law
- Includes all address mappings

### Error Conditions

1. **Address Errors**
   - "Invalid address"
   - "Address not found"
   - "Invalid address state"

2. **Value Errors**
   - "Invalid boolean value"
   - "Value unchanged"
   - "Invalid state change"

3. **Validation Errors**
   - Zero address
   - Invalid state
   - Invalid update

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0xB9260dD1b3bf29E81F5C21bC6A7A7B3F3Ce0C832  |
| 11155420 | Optimism Sepolia | 0x8Ec1D2e176a3341d3fBe18Ef9fBdD95E2AAeC400  |
| 11155111 | Ethereum Sepolia | 0xB9260dD1b3bf29E81F5C21bC6A7A7B3F3Ce0C832  | 



