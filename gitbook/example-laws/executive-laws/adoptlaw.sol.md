# AdoptLaw.sol

AdoptLaw.sol is an executive law that enables the adoption of new laws into the Powers protocol. It provides a mechanism to add new governance rules and functionality to the system.

## Overview

This law provides a mechanism to:
- Adopt new laws into the protocol
- Configure law parameters
- Set up law conditions
- Track law adoption history
- Enforce adoption rules

## Configuration

When adopting an AdoptLaw instance, no parameters are required. The law is designed to facilitate the adoption of other laws.

## Usage

### Proposing an Action

When calling the law, four parameters must be provided:

1. `law` (address): The address of the law contract to adopt
2. `nameDescription` (string): Name and description of the law
3. `inputParams` (bytes): Encoded input parameters for the law
4. `conditions` (bytes): Encoded conditions for the law

### Execution Flow

1. **Law Validation**
   - Verifies the law contract address
   - Validates law parameters
   - Checks adoption conditions

2. **Law Adoption**
   - Adopts the new law
   - Configures law parameters
   - Sets up law conditions

3. **State Management**
   - Updates adoption history
   - Maintains law registry
   - Tracks law status

## Technical Specifications

### State Variables

```solidity
struct Data {
    address[] adoptedLaws;     // List of adopted laws
    mapping(address => bool) isAdopted; // Adoption status
    mapping(address => uint256) adoptionTime; // When law was adopted
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
- Sets up adoption tracking
- Initializes empty law registry

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
- Processes the adoption request
- Validates law and parameters
- Prepares adoption data
- Returns execution data

### Error Conditions

1. **Adoption Errors**
   - "Invalid law"
   - "Law already adopted"
   - "Invalid parameters"

2. **Parameter Errors**
   - "Invalid name"
   - "Invalid conditions"
   - "Invalid input parameters"

3. **Validation Errors**
   - Zero address law
   - Invalid law contract
   - Invalid adoption status

## Current Deployments

| Chain ID | Chain Name      | Address                                      |
|----------|----------------|----------------------------------------------|
| 421614   | Arbitrum Sepolia | 0x29da0f1A6bFB57AECF9DC114dCbc426400B2B543  |
| 11155420 | Optimism Sepolia | 0x9A70425FCADbDBAc6c68506df6727B3f56b6b705  |
| 11155111 | Ethereum Sepolia | 0x29da0f1A6bFB57AECF9DC114dCbc426400B2B543  | 

 