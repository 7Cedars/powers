# Specs

### Source

See [the github repo here](https://github.com/7Cedars/powers/blob/main/solidity/src/Law.sol).

### Overview

Law.sol is the base implementation for Powers Protocol Laws. It provides core functionality for creating role-restricted governance actions in the Powers protocol. Laws serve five key functions:

1. Role restriction of community actions
2. Transformation of input data into executable calls
3. State management for the community
4. Validation of proposal and execution conditions
5. Returning of data to the Powers protocol

Laws can be customized through:
- Configuring checks in the constructor
- Inheriting and implementing bespoke logic in the `handleRequest`, `_replyPowers`, and `_changeState` functions

## State Variables

### laws
An internal mapping of `LawData` structs that tracks all law data.

```solidity
mapping(bytes32 lawHash => LawData) public laws;
```

## Functions

### Law Execution

#### initializeLaw
Initializes a law with its configuration and conditions.

```solidity
function initializeLaw(
    uint16 index,
    string memory nameDescription,
    bytes memory inputParams,
    Conditions memory conditions,
    bytes memory config
) public virtual
```

#### executeLaw
Executes the law's logic after validation. Called by the Powers protocol during action execution.

```solidity
function executeLaw(
    address caller,
    uint16 lawId,
    bytes calldata lawCalldata,
    uint256 nonce
) public returns (bool success)
```

#### handleRequest
Handles requests from the Powers protocol and returns data for execution.

```solidity
function handleRequest(
    address caller,
    address powers,
    uint16 lawId,
    bytes memory lawCalldata,
    uint256 nonce
) public view virtual returns (
    uint256 actionId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes memory stateChange
)
```

#### _changeState
Applies state changes from law execution.

```solidity
function _changeState(bytes32 lawHash, bytes memory stateChange) internal virtual
```

#### _replyPowers
Sends execution data back to Powers protocol.

```solidity
function _replyPowers(
    uint16 lawId,
    uint256 actionId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas
) internal
```

### Validation

#### checksAtPropose
Validates conditions required to propose an action.

```solidity
function checksAtPropose(
    address caller,
    Conditions memory conditions,
    bytes memory lawCalldata,
    uint256 nonce,
    address powers
) public view virtual
```

#### checksAtExecute
Validates conditions required to execute an action.

```solidity
function checksAtExecute(
    address caller,
    Conditions memory conditions,
    bytes memory lawCalldata,
    uint256 nonce,
    uint48[] memory executions,
    address powers,
    uint16 lawId
) public view virtual
```

### Helper Functions

#### getConditions
Gets the conditions for a law.

```solidity
function getConditions(address powers, uint16 lawId) public view returns (Conditions memory conditions)
```

#### getExecutions
Gets the execution data for a law.

```solidity
function getExecutions(address powers, uint16 lawId) public view returns (Executions memory executions)
```

#### getInputParams
Gets the input parameters for a law.

```solidity
function getInputParams(address powers, uint16 lawId) public view returns (bytes memory inputParams)
```

#### getNameDescription
Gets the name and description of a law.

```solidity
function getNameDescription(address powers, uint16 lawId) public view returns (string memory nameDescription)
```

## Structs

### LawData
Tracks a law's configuration and state.

```solidity
struct LawData {
    string nameDescription;
    bytes inputParams;
    Conditions conditions;
    Executions executions;
}
```

### Conditions
Defines the conditions for a law's execution.

```solidity
struct Conditions {
    uint256 allowedRole;
    uint16 needCompleted;
    uint48 delayExecution;
    uint48 throttleExecution;
    uint16 readStateFrom;
    uint32 votingPeriod;
    uint8 quorum;
    uint8 succeedAt;
    uint16 needNotCompleted;
}
```

### Executions
Tracks a law's execution history.

```solidity
struct Executions {
    address powers;
    bytes config;
    uint256[] actionsIds;
    uint48[] executions;
}
```

## Events

### Law Events
- `Law__Deployed`: Emitted when a law is deployed
- `Law__Initialized`: Emitted when a law is initialized

## Errors

### Law Errors
- `Law__OnlyPowers`: Emitted when a law is called by a non-powers account
- `Law__NoZeroAddress`: Emitted when a zero address is used
- `Law__ProposalNotSucceeded`: Emitted when a proposal is not succeeded
- `Law__ParentLawNotSet`: Emitted when a parent law is not set
- `Law__NoDeadlineSet`: Emitted when a deadline is not set
- `Law__InvalidPowersContractAddress`: Emitted when a powers contract address is invalid
- `Law__ParentNotCompleted`: Emitted when a parent law is not completed
- `Law__ParentBlocksCompletion`: Emitted when a parent law blocks completion
- `Law__ExecutionGapTooSmall`: Emitted when an execution gap is too small
- `Law__DeadlineNotPassed`: Emitted when a deadline is not passed

## Important Considerations

### 1. Law Implementation Requirements
- Must implement the `ILaw` interface
- Must provide validation logic
- Must handle state changes
- Must return execution data
- Must implement proper access controls

### 2. Gas Optimization
- Law data is stored efficiently
- Conditions are packed into a single struct
- Execution history is stored as arrays
- State changes are applied only when needed

### 3. Security Considerations
- Laws should be thoroughly tested
- Validation should be comprehensive
- State changes should be properly validated
- Execution data should be properly formatted
- Access controls should be properly implemented

### 4. Best Practices
- Use clear and descriptive law names
- Implement proper validation
- Document law conditions and requirements
- Test laws thoroughly
- Consider gas implications
- Implement proper error handling
- Use events for important state changes
- Consider upgrade paths

