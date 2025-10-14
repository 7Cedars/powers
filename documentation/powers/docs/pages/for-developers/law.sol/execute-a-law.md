# Execute a Law

The `executeLaw` function is the main entry point for executing a law in the Powers protocol. It handles the complete execution flow of a law, from validation to state changes.

## Execution Flow

### 1. Initial Validation
```solidity
function executeLaw(
    address caller,
    uint16 lawId,
    bytes calldata lawCalldata,
    uint256 nonce
) public returns (bool success)
```

The function first validates:
- The caller is the Powers contract
- The law is properly initialized
- The law hash is valid

### 2. Validation Checks
Two sets of checks are performed:

#### Proposal Checks
```solidity
checksAtPropose(caller, laws[lawHash].conditions, lawCalldata, nonce, msg.sender);
```
- Validates parent law completion
- Checks role permissions
- Verifies input parameters

#### Execution Checks
```solidity
checksAtExecute(
    caller,
    laws[lawHash].conditions,
    lawCalldata,
    nonce,
    laws[lawHash].executions.executions,
    msg.sender,
    lawId
);
```
- Validates execution timing
- Checks proposal success
- Verifies execution delay

### 3. Law Execution
The law's logic is executed through `handleRequest`:
```solidity
(
    uint256 actionId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes memory stateChange
) = handleRequest(caller, msg.sender, lawId, lawCalldata, nonce);
```

### 4. State Changes
If state changes are required:
```solidity
if (stateChange.length > 0) {
    _changeState(lawHash, stateChange);
}
```

### 5. Reply to Powers
If execution targets are provided:
```solidity
if (targets.length > 0) {
    _replyPowers(lawId, actionId, targets, values, calldatas);
}
```

### 6. Execution Tracking
The execution is recorded:
```solidity
laws[lawHash].executions.executions.push(uint48(block.number));
laws[lawHash].executions.actionsIds.push(actionId);
```

## Error Handling

The following errors may be thrown during execution:

- `Law__OnlyPowers`: Caller is not the Powers contract
- `Law__ProposalNotSucceeded`: Proposal has not succeeded
- `Law__ExecutionGapTooSmall`: Execution gap is too small
- `Law__DeadlineNotPassed`: Execution deadline has not passed

## Best Practices

1. **Execution Safety**
   - Validate all inputs
   - Check execution conditions
   - Verify state consistency
   - Handle errors gracefully

2. **Gas Optimization**
   - Minimize state changes
   - Use efficient data structures
   - Cache frequently accessed values
   - Batch operations when possible

3. **State Management**
   - Update state atomically
   - Validate state transitions
   - Emit appropriate events
   - Maintain state consistency

4. **Security**
   - Validate caller permissions
   - Check for reentrancy
   - Verify execution conditions
   - Protect against manipulation

## Example Implementation

```solidity
function executeLaw(
    address caller,
    uint16 lawId,
    bytes calldata lawCalldata,
    uint256 nonce
) public returns (bool success) {
    bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
    
    // Validate caller
    if (laws[lawHash].executions.powers != msg.sender) {
        revert Law__OnlyPowers();
    }
    
    // Run validation checks
    checksAtPropose(caller, laws[lawHash].conditions, lawCalldata, nonce, msg.sender);
    checksAtExecute(
        caller,
        laws[lawHash].conditions,
        lawCalldata,
        nonce,
        laws[lawHash].executions.executions,
        msg.sender,
        lawId
    );
    
    // Execute law logic
    (
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes memory stateChange
    ) = handleRequest(caller, msg.sender, lawId, lawCalldata, nonce);
    
    // Apply state changes
    if (stateChange.length > 0) {
        _changeState(lawHash, stateChange);
    }
    
    // Reply to Powers
    if (targets.length > 0) {
        _replyPowers(lawId, actionId, targets, values, calldatas);
    }
    
    // Record execution
    laws[lawHash].executions.executions.push(uint48(block.number));
    laws[lawHash].executions.actionsIds.push(actionId);
    
    return true;
}
```
