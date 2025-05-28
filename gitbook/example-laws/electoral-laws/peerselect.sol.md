# PeerSelect.sol

## Summary

Select an accounts from a list of nominated accounts and assign or revoke it a role ID.

## Configuration

When adopting a PeerSelect instance there are three parameters that need to be provided.

1. `uint256 maxRoleHolders`: maximum number of accounts that can be assigned a role ID.
2. `uint256 roleID`: The role ID that can be assigned.
3. As a `condition.readStateFrom`: an address of a `NominateMe.sol` instance needs to be provided.   

## Calling the law

When calling the law, two parameters need to be provided.

1. `uint256 NomineeIndex`: The index of the nominee in the nominee list. 
2. `bool assign`: a bool indicating if the address needs to be assigned a role ID (true) or if a role ID needs to be revoked (false).

## Execution

The law executes the following logic:

1. Loads data from the `NominateMe.sol` instance.
2. Retrieves address from the list of nominees.
3. Checks if this address has already been assigned the role ID.
4. In case of assigning role,
   1. Will revert if already has the role.
   2. Will assign role if not. 
5. In case of revoking role
   1. Will revert if does not have role.
   2. Will revoke role if not.
6. Adapts the list of selected accounts and saves it to state. 

## Specs

Only specs that are in addition to the specs of `Law.sol` are noted here.

### Source

.. link to github source.

### State Variables

... State Variables

### Functions

... State Variables

### Structs

... Structs

### Events

... list of law specific events.

## Current deployments

| Address | Chain Id | Date |
| ------- | -------- | ---- |
|         |          |      |
|         |          |      |
|         |          |      |

## Previous deployments

| Address | Chain Id | Date |
| ------- | -------- | ---- |
|         |          |      |
|         |          |      |
|         |          |      |

