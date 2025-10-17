# Change State

The `_changeState` function is responsible for applying state changes in a law after successful execution. This function is called internally by `executeLaw` when state changes are required.

## State Change Process

### 1. Function Signature
```solidity
function _changeState(bytes32 lawHash, bytes memory stateChange) internal virtual
```

### 2. Implementation Requirements

#### Virtual Function
- Must be `virtual` to allow overriding
- Must be `internal` for security
- Must handle state changes safely

#### State Change Data
- `lawHash`: Unique identifier for the law
- `stateChange`: Encoded state changes to apply

## Implementation Guidelines

### 1. State Change Safety
- Validate state changes before applying
- Ensure atomic state updates
- Maintain state consistency
- Handle errors gracefully

### 2. Gas Optimization
- Minimize state changes
- Use efficient data structures
- Batch related changes
- Cache frequently accessed values

### 3. Security
- Validate all inputs
- Check permissions
- Prevent reentrancy
- Protect against manipulation

## Example Implementation

```solidity
function _changeState(bytes32 lawHash, bytes memory stateChange) internal virtual override {
    // Decode state changes
    (uint256 newValue, address newAddress) = abi.decode(
        stateChange,
        (uint256, address)
    );
    
    // Validate state changes
    require(newValue <= maxValue, "Value too high");
    require(newAddress != address(0), "Invalid address");
    
    // Apply state changes
    LawData storage law = laws[lawHash];
    law.value = newValue;
    law.target = newAddress;
    
    // Emit event
    emit StateChanged(lawHash, newValue, newAddress);
}
```

## Best Practices

1. **State Management**
   - Update state atomically
   - Validate all changes
   - Maintain consistency
   - Handle edge cases

2. **Error Handling**
   - Validate inputs
   - Check conditions
   - Provide clear errors
   - Handle failures

3. **Gas Optimization**
   - Minimize storage writes
   - Use efficient data structures
   - Batch related changes
   - Cache values

4. **Security**
   - Validate permissions
   - Check for reentrancy
   - Protect against manipulation
   - Maintain invariants

## Common Pitfalls

1. **State Inconsistency**
   - Partial state updates
   - Invalid state transitions
   - Missing validations
   - Race conditions

2. **Gas Issues**
   - Excessive storage writes
   - Inefficient data structures
   - Unnecessary computations
   - Poor batching

3. **Security Vulnerabilities**
   - Missing validations
   - Reentrancy issues
   - Permission bypasses
   - State manipulation

4. **Error Handling**
   - Missing validations
   - Unclear error messages
   - Incomplete error handling
   - Silent failures

## State Change Flow

1. **Preparation**
   - Decode state changes
   - Validate inputs
   - Check conditions
   - Prepare updates

2. **Application**
   - Update state
   - Maintain consistency
   - Handle errors
   - Emit events

3. **Verification**
   - Verify changes
   - Check invariants
   - Validate results
   - Handle failures

4. **Cleanup**
   - Clear temporary data
   - Update counters
   - Finalize changes
   - Emit final events
