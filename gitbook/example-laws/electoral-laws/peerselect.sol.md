# PeerSelect.sol

## Summary&#x20;

Select an accounts from a list of nominated accounts and assign or revoke it a role ID.

## Configuration

When adopting a PeerSelect instance there are three parameters that need to be provided.&#x20;

1. `uint256 maxRoleHolders`: maximum number of accounts that can be assigned a role ID.&#x20;
2. `uint256 roleID`: The role ID that can be assigned.
3. As a `condition.readStateFrom`: an address of a `NominateMe.sol` instance needs to be provided.   &#x20;

## Calling the law&#x20;

When calling the law, two parameters need to be provided.&#x20;

1. `uint256 NomineeIndex`: The index of the nominee in the nominee list. &#x20;
2. `bool assign`: a bool indicating if the address needs to be assigned a role ID (true) or if a role ID needs to be revoked (false).&#x20;

## Execution

The law executes the following logic:&#x20;

1. Loads data from the `NominateMe.sol` instance.&#x20;
2. Retrieves address from the list of nominees.&#x20;
3. Checks if this address has already been assigned the role ID.&#x20;
4. In case of assigning role,&#x20;
   1. Will revert if already has the role.&#x20;
   2. Will assign role if not. &#x20;
5. In case of revoking role&#x20;
   1. Will revert if does not have role.&#x20;
   2. Will revoke role if not.&#x20;
6. Adapts the list of selected accounts and saves it to state. &#x20;

## Specs

Only specs that are in addition to the specs of `Law.sol` are noted here.&#x20;

### Source&#x20;

.. link to github source.&#x20;

### State Variables

... State Variables

### Functions

... State Variables

### Structs

... Structs&#x20;

### Events

... list of law specific events.&#x20;

&#x20;&#x20;
