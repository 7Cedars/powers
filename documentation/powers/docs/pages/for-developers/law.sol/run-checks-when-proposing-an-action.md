# Run Checks When Proposing an Action

When proposing an action in a law, several validation checks are performed to ensure the action is valid and authorized. These checks are implemented in the `checksAtPropose` function.

## Validation Process

### 1. Base Checks
The `baseChecksAtPropose` function in `LawUtilities` performs fundamental validations:

```solidity
function baseChecksAtPropose(
    ILaw.Conditions memory conditions,
    bytes memory lawCalldata,
    address powers,
    uint256 nonce
) external view
```

#### Parent Law Completion Check
- Verifies if a parent law has been completed (if required)
- Checks the state of the parent law's action
- Reverts with `LawUtilities__ParentNotCompleted` if parent law is not completed

#### Parent Law Block Check
- Verifies if a parent law must not be completed
- Checks the state of the parent law's action
- Reverts with `LawUtilities__ParentBlocksCompletion` if parent law is completed

### 2. Custom Checks
Laws can implement additional validation logic by overriding `checksAtPropose`:

```solidity
function checksAtPropose(
    address caller,
    Conditions memory conditions,
    bytes memory lawCalldata,
    uint256 nonce,
    address powers
) public view virtual
```

Common custom checks include:
- Role-based access control
- Input parameter validation
- State-dependent conditions
- Time-based restrictions
- Resource availability

## Error Handling

The following errors may be thrown during proposal checks:

- `LawUtilities__ParentNotCompleted`: Parent law has not been completed
- `LawUtilities__ParentBlocksCompletion`: Parent law is completed when it shouldn't be
- `LawUtilities__StringTooShort`: String parameter is too short
- `LawUtilities__StringTooLong`: String parameter is too long

## Best Practices

1. **Comprehensive Validation**
   - Validate all input parameters
   - Check all required conditions
   - Verify caller permissions
   - Ensure state consistency

2. **Gas Optimization**
   - Order checks from least to most expensive
   - Use early returns for invalid conditions
   - Cache frequently accessed values

3. **Error Messages**
   - Use clear and descriptive error messages
   - Include relevant context in errors
   - Follow consistent error naming

4. **Security**
   - Validate all external inputs
   - Check for reentrancy vulnerabilities
   - Verify caller permissions
   - Validate state transitions

## Example Implementation

```solidity
function checksAtPropose(
    address caller,
    Conditions memory conditions,
    bytes memory lawCalldata,
    uint256 nonce,
    address powers
) public view virtual override {
    // Run base checks
    LawUtilities.baseChecksAtPropose(conditions, lawCalldata, powers, nonce);
    
    // Custom role check
    if (!hasRequiredRole(caller, conditions.allowedRole)) {
        revert("Insufficient permissions");
    }
    
    // Custom state check
    if (!isValidState()) {
        revert("Invalid state for proposal");
    }
    
    // Custom parameter validation
    validateParameters(lawCalldata);
}
```
