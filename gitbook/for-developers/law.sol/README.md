---
description: Checking under the hood of law implementations.
---

# Law.sol

## What are laws?

Laws define under which conditions a role can execute what actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favour.

Laws have the following characteristics:

* They are role restricted by a single role.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.

## Creating laws

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`.

The base `law.sol` implementation does not enable any action. It has the following checks included that are all disabled be default: 
* quorum: Percentage of FOR or ABSTAIN votes that need to be cast on a proposal for the action to be allowed to pass. 
* succeedAt: The percentage of FOR votes needed in a vote for it to pass. 
* votingPeriod: The number of blocks a vote on this law will last.
* needCompleted: a law that needs to have been completed before the law can be considered.
* needNotCompleted: a law that needs to have _not_ been completed before the law can be considered.
* delayExecution: the number of blocks that need to pass after the proposal succeeded before the law can be executed. 
* throttleExecution: the number of blocks that need to pass between executions of the law.

All these checks are optional, but some are mutually exclusive. If a quorum is set at 0, for instance, votingPeriod and succeedAt will be automatically ignored. It will mean that no proposal vote is needed for rhe law to be executed.  

Laws can be adapted by:

* Adjusting the above checks of a law by changing the `checks` object and construction time. 
* Adding new checks to `checksAtPropose` and/or `checksAtExecute`.
* Changing the allowed actions of a law by adjusting the `handleRequest`,  `_changeState` and/or `_replyPowers` functions.


Combining these changes makes it possible to pretty much do anything.

## Law functionalities

The core functionality of a Law is to receive an input of Powers and to return an output back to the same contract. This is done through the `executeLaw` function. When this function is called, the following happens:

1. Checks are run.
2. The calldata is decoded and transformed on the function `handleRequest`.
3. If `handleRequest` returns target contracts to be called by Powers, these are returned by the `_replyPowers` function.
4. If `handleRequest` returns state data, these are saved by the `_changeState` function.
