# Adopting and revoking laws

The Powers protocol uses laws as modular, role-restricted governance actions. Laws are the building blocks of the protocol's governance system, allowing for flexible and customizable governance rules.

## Law System Overview

### Law Structure
Each law is represented by an `ActiveLaw` struct containing:
- `targetLaw`: The address of the law contract
- `active`: Boolean indicating if the law is currently active

### Law Initialization Data
When adopting a law, the following data is required (`LawInitData` struct):
- `nameDescription`: Human-readable description of the law
- `targetLaw`: Address of the law contract
- `config`: Additional configuration data for the law
- `conditions`: Governance conditions for the law

## Law Management Functions

### Initial Law Adoption
The initial set of laws is adopted through the `constitute` function:
```solidity
function constitute(LawInitData[] memory constituentLaws) external
```

The function:
- Can only be called once by an admin
- Can only be called before any other law adoption
- Initializes each law in the array
- Sets `_constituteExecuted` to true
- Emits `LawAdopted` events for each law

### Adopting Additional Laws
New laws can be adopted through the `adoptLaw` function:
```solidity
function adoptLaw(LawInitData memory lawInitData) public
```

The function:
- Can only be called through the protocol itself
- Verifies the target contract implements the `ILaw` interface
- Increments the `lawCount`
- Initializes the law with the provided data
- Emits a `LawAdopted` event

### Revoking Laws
Laws can be revoked through the `revokeLaw` function:
```solidity
function revokeLaw(uint16 lawId) public
```

The function:
- Can only be called through the protocol itself
- Verifies the law is currently active
- Sets the law's active status to false
- Emits a `LawRevoked` event

## Law Queries

### Checking Law Status
The `getActiveLaw` function returns information about a law:
```solidity
function getActiveLaw(uint16 lawId) external view returns (address law, bytes32 lawHash, bool active)
```

### Law Conditions
Laws can be queried for their conditions through the law contract:
```solidity
function getConditions(address powers, uint16 lawId) public view returns (Conditions memory conditions)
```

## Important Considerations

### 1. Law Adoption Restrictions
- Initial laws can only be adopted once through `constitute`
- Only the protocol itself can adopt or revoke laws
- Laws must implement the `ILaw` interface
- Law IDs start at 1 (0 is used as a default 'false' value)
- Laws cannot be modified after adoption

### 2. Law Implementation Requirements
- Must implement the `ILaw` interface
- Must provide validation logic
- Must handle state changes
- Must return execution data
- Must implement proper access controls

### 3. Common Pitfalls
- Laws cannot be re-adopted after revocation
- Law conditions cannot be modified after adoption
- Law addresses cannot be changed
- Active laws cannot be overwritten
- Law IDs are sequential and cannot be reused

### 4. Security Considerations
- Laws should be thoroughly tested before adoption
- Law conditions should be carefully designed
- Role restrictions should be properly implemented
- State changes should be properly validated
- Execution data should be properly formatted

### 5. Best Practices
- Use clear and descriptive law names
- Implement proper validation in laws
- Document law conditions and requirements
- Test laws thoroughly before adoption
- Consider gas implications of law execution
- Implement proper error handling
- Use events for important state changes
- Consider upgrade paths for laws

### 6. Gas Optimization
- Law data is stored efficiently
- Active status is stored as a boolean
- Law addresses are stored as addresses
- Law hashes are computed on-demand
- Conditions are stored in the law contract

### 7. Law Lifecycle
1. **Development**
   - Implement the `ILaw` interface
   - Add validation logic
   - Add state management
   - Add execution logic
   - Test thoroughly

2. **Adoption**
   - Prepare law initialization data
   - Call `adoptLaw` or `constitute`
   - Verify law is active
   - Test law functionality

3. **Usage**
   - Call law through `request` or `propose`
   - Monitor law execution
   - Handle law responses
   - Manage law state

4. **Revocation**
   - Call `revokeLaw` when needed
   - Verify law is inactive
   - Handle any cleanup needed
   - Consider replacement law
