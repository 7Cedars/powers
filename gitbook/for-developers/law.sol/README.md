---
description: Checking under the hood of law implementations.
---

# Law.sol

## What are laws?

Laws define under which conditions a role can execute what actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favour.&#x20;

Laws have the following characteristics:

* They are role restricted by a single role.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.

## Creating laws

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`.

Laws can be adapted by:&#x20;

* Changing the configuration file of an existing the law.&#x20;
* Changing the content of the functions `handleRequest`,  `_changeState` and/or `_replyPowers.` This can include adding addition state variables and constructor parameters.&#x20;
* Adding checks to `checksAtPropose` and/or `checksAtExecute`.

Combining these changes makes it possible to pretty much make anything possible.&#x20;

## Law functionalities

The core functionality of a Law is to receive an input of Powers and to return an output back to the same contract. This is done through the `executeLaw` function. When this function is called, the following happens:&#x20;

1. Checks are run.&#x20;
2. The calldata is decoded and transformed on the function `handleRequest`.
3. If `handleRequest` returns target contracts to be called by Powers, these are returned by the `_replyPowers` function.&#x20;
4. If `handleRequest` returns state data, these are saved by the `_changeState` function.&#x20;
