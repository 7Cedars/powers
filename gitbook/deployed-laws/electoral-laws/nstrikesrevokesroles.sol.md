# NStrikesRevokesRoles.sol

NStrikesRevokesRoles.sol is an electoral law that revokes roles from all current holders when the number of flagged actions exceeds a configured threshold. It provides a mechanism for automatic role revocation based on behavioral violations.

## Overview

This law provides a mechanism to:
- Monitor flagged actions for a specific role
- Count violations against role holders
- Automatically revoke roles when threshold is exceeded
- Reset flagged actions after revocation
- Enforce behavioral standards

## Configuration

When adopting an NStrikesRevokesRoles instance, three parameters must be provided:

1. `roleId` (uint256): The role ID to monitor for violations
2. `numberOfStrikes` (uint256): The threshold number of strikes before revocation
3. `flagActionsAddress` (address): The address of the FlagActions contract

## Usage

### Proposing an Action

When calling the law, no parameters are required. The law automatically checks the current number of flagged actions and revokes roles if the threshold is exceeded.

### Execution Flow

1. **Strike Count Validation**
   - Queries the FlagActions contract for flagged actions
   - Counts violations for the specific role ID
   - Compares count against configured threshold

2. **Role Holder Retrieval**
   - Gets all current holders of the monitored role
   - Prepares revocation calls for each holder

3. **Role Revocation**
   - If threshold is exceeded:
     - Creates revocation calls for all role holders
     - Executes role revocation in batch
   - If threshold not met:
     - Returns empty execution data

4. **State Management**
   - Records revocation actions
   - Updates role holder lists
   - Tracks violation counts

## Technical Specifications

### State Variables

```solidity
struct Data {
    uint256 roleId;              // Role ID to monitor
    uint256 numberOfStrikes;     // Threshold for revocation
    address flagActionsAddress;  // FlagActions contract address
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
    bytes memory config
) public override
```
- Initializes law with configuration parameters
- Sets up role monitoring and strike threshold
- Configures FlagActions contract address

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
- Processes the revocation request
- Checks flagged actions count
- Prepares role revocation calls if threshold exceeded
- Returns execution data

#### `shouldRevokeRole`
```solidity
function shouldRevokeRole(bytes32 lawHash) external view returns (bool shouldRevoke)
```
- Checks if the role should be revoked based on current strikes
- Returns true if threshold is exceeded

### Error Conditions

1. **Threshold Errors**
   - "Not enough strikes to revoke roles"
   - Insufficient flagged actions

2. **Configuration Errors**
   - Invalid role ID
   - Invalid FlagActions contract address
   - Invalid strike threshold

3. **Validation Errors**
   - Zero address FlagActions contract
   - Invalid role configuration

## Current Deployments

| Chain ID  | Chain Name         | Address                                      |
|-----------|-------------------|----------------------------------------------|
| 421614    | Arbitrum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155420  | Optimism Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  |
| 11155111  | Ethereum Sepolia  | 0xa797799EE0C6FA7d9b76eF52e993288a04982267  | 



