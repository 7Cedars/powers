---
description: Checking under the hood of law implementations.
---

# Law.sol

## What are laws?

Laws define under what conditions a role can execute which actions.&#x20;

&#x20;Laws have the following characteristics:

* They are singleton contracts. One law instance can be used by multiple Powers protocols, and multiple times by a single protocol.&#x20;
* Their use is linked to a unique adoption ID of a `Powers.sol` deployment.
* They are role restricted by a single role.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment using a correct law ID.

To make abundantly clear: The Powers protocol ensures that each community can only interact with their adopted instance of a law. The Yellow community below, for instance, cannot interfere with assigning roles in the Red community. Governance is protected against outside interference.

<figure><img src="../../.gitbook/assets/image (4).png" alt=""><figcaption><p>Governance space of the Powers protocol </p></figcaption></figure>

🚧 **Everythign from here on is still completely work in progress and incomplete.** 🚧

## Law functionalities

The core functionality of a Law is to receive an input of Powers and to return an output back to the same contract. This is done through the `executeLaw` function. When this function is called, the following happens:

1. Checks are run.
2. The calldata is decoded and transformed on the function `handleRequest`.
3. If `handleRequest` returns target contracts to be called by Powers, these are returned by the `_replyPowers` function.
4. If `handleRequest` returns state data, these are saved by the `_changeState` function.
