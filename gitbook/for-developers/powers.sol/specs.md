# Specs

## Source

See [the github repo here](https://github.com/7Cedars/powers/blob/main/solidity/src/Powers.sol).

## Overview

Powers is a Role Restricted Governance Protocol that provides a modular, flexible, decentralized and efficient governance engine for DAOs. It is designed to be used in combination with implementations of `Law.sol` contracts.

Key differences from OpenZeppelin's Governor.sol:

1. DAO actions must be encoded in role-restricted external contracts (laws) following the `ILaw` interface
2. Proposing, voting, cancelling and executing actions are role-restricted along the target law
3. All DAO actions must run through the governance flow provided by Powers.sol
4. Uses a non-weighted voting mechanism: one account has one vote
5. Core protocol is intentionally minimalistic - complexity (timelocks, delayed execution, guardian roles, weighted votes, staking) must be integrated through laws

## State Variables

### \_actions

An internal mapping of `Action` structs. Its data can be accessed through the `getActionCalldata`, `getActionUri` and `getActionNonce` getter functions.

```solidity
mapping(uint256 actionId => Action) internal _actions;
```

### \_laws

An internal mapping of `ActiveLaw` structs that tracks all active laws in the protocol.

```solidity
mapping(uint16 lawId => ActiveLaw) internal laws;
```

### \_roles

An internal mapping of `Role` structs that tracks role assignments and membership.

```solidity
mapping(uint256 roleId => Role) internal roles;
```

### \_deposits

An internal mapping that tracks deposits from accounts (only covers chain native currency).

```solidity
mapping(address account => Deposit[]) internal deposits;
```

### Constants

* `ADMIN_ROLE`: Set to `type(uint256).min` (0)
* `PUBLIC_ROLE`: Set to `type(uint256).max`
* `DENOMINATOR`: Set to 100 (100%)

### Other State Variables

* `name`: Name of the DAO
* `uri`: URI to metadata of the DAO
* `_constituteExecuted`: Boolean tracking if constitute function has been called
* `lawCount`: Number of laws initiated (starts at 1)

## Functions

*Governance Functions*

### request

Initiates an action to be executed through a law. Entry point for all actions in the protocol.

```solidity
function request(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction) external payable
```

### fulfill

Completes an action by executing the actual calls. Can only be called by an active law contract.

```solidity
function fulfill(uint16 lawId, uint256 actionId, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas) external payable
```

### propose

Creates a new proposal for an action that requires voting. Only callable if the law requires voting (quorum > 0).

```solidity
function propose(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction) external returns (uint256)
```

### cancel

Cancels an existing proposal. Can only be called by the original proposer.

```solidity
function cancel(uint16 lawId, bytes calldata lawCalldata, uint256 nonce) public returns (uint256)
```

### castVote` & `castVoteWithReason

Casts a vote on an active proposal. Vote types: 0=Against, 1=For, 2=Abstain.

```solidity
function castVote(uint256 actionId, uint8 support) external
function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) public
```

*Role and Law Administration*

### constitute

Initializes the DAO by activating its founding laws. Can only be called once by an admin account.

```solidity
function constitute(LawInitData[] memory constituentLaws) external
```

### adoptLaw & revokeLaw

Activates or deactivates a law in the protocol.

```solidity
function adoptLaw(LawInitData memory lawInitData) public
function revokeLaw(uint16 lawId) public
```

### assignRole & revokeRole

Grants or removes a role from an account.

```solidity
function assignRole(uint256 roleId, address account) public
function revokeRole(uint256 roleId, address account) public
```

### labelRole

Assigns a human-readable label to a role.

```solidity
function labelRole(uint256 roleId, string memory label) public
```

## Structs

### Action

Tracks a proposal's state and voting information.

```solidity
struct Action {
    bool cancelled;
    bool requested;
    bool fulfilled;
    uint16 lawId;
    uint48 voteStart;
    uint32 voteDuration;
    address caller;
    uint32 againstVotes;
    uint32 forVotes;
    uint32 abstainVotes;
    mapping(address voter => bool) hasVoted;
    bytes lawCalldata;
    string uri;
    uint256 nonce;
}
```

### ActiveLaw

Tracks an active law's address and status.

```solidity
struct ActiveLaw {
    address targetLaw;
    bool active;
}
```

### Role

Tracks role assignments and membership.

```solidity
struct Role {
    mapping(address account => uint48 since) members;
    uint256 amountMembers;
    string label;
}
```

### Deposit

Tracks a deposit's amount and block number.

```solidity
struct Deposit {
    uint256 amount;
    uint48 atBlock;
}
```

## Events

### Governance Events

* `ActionRequested`: Emitted when an executive action is requested
* `ActionExecuted`: Emitted when an executive action has been executed
* `ProposedActionCreated`: Emitted when a proposal is created
* `ProposedActionCancelled`: Emitted when a proposal is cancelled
* `VoteCast`: Emitted when a vote is cast

### Role and Law Events

* `RoleSet`: Emitted when a role is assigned or revoked
* `RoleLabel`: Emitted when a role is labeled
* `LawAdopted`: Emitted when a law is adopted
* `LawRevoked`: Emitted when a law is revoked
* `LawRevived`: Emitted when a law is revived

### Other Events

* `Powers__Initialized`: Emitted when protocol is initialized
* `FundsReceived`: Emitted when protocol receives funds

## Enums

### ActionState

Represents the state of a proposal:

* Active
* Cancelled
* Defeated
* Succeeded
* Requested
* Fulfilled
* NonExistent

### VoteType

Supported vote types (matches Governor Bravo ordering):

* Against
* For
* Abstain
