---
description: Checking under the hood of law implementations.
---

# Law.sol

Law.sol is the base implementation for Powers Protocol Laws. It provides core functionality for creating role-restricted governance actions in the Powers protocol.

## Overview

Laws serve five key functions in the Powers protocol:

1. **Role Restriction**: Laws enforce role-based access control for community actions
2. **Data Transformation**: Laws transform input data into executable calls
3. **State Management**: Laws manage state changes for the community
4. **Validation**: Laws validate proposal and execution conditions
5. **Data Return**: Laws return execution data to the Powers protocol

## Key Components

### Law Structure
Each law is defined by:
- A unique law hash
- Configuration data
- Execution conditions
- State management logic

### Core Functionality
- **Initialization**: Setting up law parameters and conditions
- **Execution**: Processing and validating actions
- **State Management**: Handling state changes
- **Validation**: Checking conditions and permissions
- **Communication**: Interacting with the Powers protocol

## Implementation Guide

To implement a new law:

1. Inherit from the Law contract
2. Implement required functions:
   - `handleRequest`: Process incoming requests
   - `_changeState`: Manage state changes
3. Configure validation logic
4. Set up proper access controls
5. Implement error handling

## Related Documentation

- [Run Checks When Proposing an Action](./run-checks-when-proposing-an-action.md)
- [Execute a Law](./execute-a-law.md)
- [Simulate a Law](./simulate-a-law.md)
- [Change State](./change-state.md)
- [Reply to Powers](./reply-to-powers.md)
- [Specifications](./specs.md)

## What are laws?

Laws define under what conditions a role can execute which actions.

Laws have the following characteristics:

* They are singleton contracts. One law instance can be used by multiple Powers protocols, and multiple times by a single protocol.
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
