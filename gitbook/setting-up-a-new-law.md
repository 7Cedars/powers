# Setting up a new law

🚧 **This page is incomplete.** 🚧

## Creating laws

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`.

The base `law.sol` implementation does not enable any action. It has the following checks included that are all disabled be default:

* `quorum`: Percentage of FOR or ABSTAIN votes that need to be cast on a proposal for the action to be allowed to pass.
* `succeedAt`: The percentage of FOR votes needed in a vote for it to pass.
* `votingPeriod`: The number of blocks a vote on this law will last.
* `needCompleted`: a law that needs to have been completed before the law can be considered.
* `needNotCompleted`: a law that needs to have _not_ been completed before the law can be considered.
* `delayExecution`: the number of blocks that need to pass after the proposal succeeded before the law can be executed.
* `throttleExecution`: the number of blocks that need to pass between executions of the law.

All these checks are optional, but some are mutually exclusive. If a quorum is set at 0, for instance, votingPeriod and succeedAt will be automatically ignored. It will mean that no proposal vote is needed for rhe law to be executed.

Laws can be adapted by:

* Adjusting the above checks of a law by changing the `checks` object and construction time.
* Adding new checks to `checksAtPropose` and/or `checksAtExecute`.
* Changing the allowed actions of a law by adjusting the `handleRequest`, `_changeState` and/or `_replyPowers` functions.

Combining these changes makes it possible to pretty much do anything.

## Config

Text and explanation here.

## Parameters

Text and explanation here

## Law utils

Text and explanation here.

## Changing functions

See next sub pages.

