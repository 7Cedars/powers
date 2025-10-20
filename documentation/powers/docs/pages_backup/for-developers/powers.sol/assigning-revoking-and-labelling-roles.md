# Assigning, revoking and labelling roles

The Powers protocol implements a role-based access control system that is fundamental to its governance mechanism. Roles are used to restrict access to laws and actions, ensuring that only authorized accounts can perform specific operations.

## Role System Overview

### Built-in Roles
- `ADMIN_ROLE` (0): The highest privilege role, assigned to the contract deployer
- `PUBLIC_ROLE` (type(uint256).max): A special role that everyone has by default

### Role Structure
Each role is represented by a `Role` struct containing:
- `members`: Mapping of addresses to block numbers (when they received the role)
- `amountMembers`: Total number of members with this role
- `label`: Human-readable description of the role

## Role Management Functions

### Assigning Roles
Roles are assigned through the `assignRole` function:
```solidity
function assignRole(uint256 roleId, address account) public
```

The function:
- Can only be called through the protocol itself (using `onlyPowers` modifier)
- Cannot assign the `PUBLIC_ROLE` (it's automatically given to everyone)
- Cannot assign roles to the zero address
- Records the block number when the role was assigned
- Increments the `amountMembers` counter
- Emits a `RoleSet` event

### Revoking Roles
Roles are revoked through the `revokeRole` function:
```solidity
function revokeRole(uint256 roleId, address account) public
```

The function:
- Can only be called through the protocol itself
- Cannot revoke the `PUBLIC_ROLE`
- Cannot revoke roles from the zero address
- Sets the member's block number to 0
- Decrements the `amountMembers` counter
- Emits a `RoleSet` event

### Labelling Roles
Roles can be labeled for better identification through the `labelRole` function:
```solidity
function labelRole(uint256 roleId, string memory label) public
```

The function:
- Can only be called through the protocol itself
- Cannot label `ADMIN_ROLE` or `PUBLIC_ROLE`
- Updates the role's label
- Emits a `RoleLabel` event

## Role Queries

### Checking Role Assignment
The `hasRoleSince` function checks when an account received a role:
```solidity
function hasRoleSince(address account, uint256 roleId) public view returns (uint48 since)
```
- Returns the block number when the role was assigned
- Returns 0 if the account never had the role

### Counting Role Members
The `getAmountRoleHolders` function returns the total number of accounts with a role:
```solidity
function getAmountRoleHolders(uint256 roleId) public view returns (uint256 amountMembers)
```

### Getting Role Label
The `getRoleLabel` function returns the human-readable label of a role:
```solidity
function getRoleLabel(uint256 roleId) public view returns (string memory label)
```

## Important Considerations

### 1. Role Assignment Restrictions
- Only the protocol itself can assign/revoke roles (through laws)
- The `PUBLIC_ROLE` cannot be assigned or revoked
- The zero address cannot be assigned roles
- Role assignments are permanent until revoked
- Role assignments are tracked with block numbers

### 2. Gas Optimization
- Role assignments use uint48 for block numbers
- Role membership counts are stored as uint256
- Role labels are stored as strings

### 3. Common Pitfalls
- Role assignments cannot be modified, only revoked and reassigned
- The `PUBLIC_ROLE` is always available to everyone
- Role labels cannot be set for `ADMIN_ROLE` or `PUBLIC_ROLE`
- Role assignments are permanent until explicitly revoked

### 4. Security Considerations
- Role assignments should be carefully managed through laws
- The `ADMIN_ROLE` should be used sparingly
- Role labels should be clear and descriptive
- Role assignments should be regularly audited
- Consider the implications of role revocation on active proposals

### 5. Best Practices
- Use descriptive role labels
- Implement laws for role management
- Consider implementing role hierarchies through laws
- Document role purposes and permissions
- Regularly review role assignments
- Implement proper access controls in laws
