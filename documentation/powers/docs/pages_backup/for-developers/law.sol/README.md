---
description: Checking under the hood of law implementations.
---

# Law.sol

Law.sol is the base implementation for Powers Protocol Laws. It provides core functionality for creating role-restricted governance actions in the Powers protocol.

## Overview

Laws are modular, role-restricted governance actions that serve as building blocks of the Powers protocol. Each law is a singleton contract that can be used by multiple Powers protocols, and multiple times by a single protocol. The use of a law is linked to a unique adoption ID of a `Powers.sol` deployment.

## Key Functions

Laws serve five key functions in the Powers protocol:

1. **Role Restriction**: Laws enforce role-based access control for community actions
2. **Data Transformation**: Laws transform input data into executable calls
3. **State Management**: Laws manage state changes for the community
4. **Validation**: Laws validate proposal and execution conditions
5. **Data Return**: Laws return execution data to the Powers protocol

## Law Characteristics

- **Singleton Contracts**: One law instance can be used by multiple Powers protocols
- **Role Restricted**: Each law is restricted by a single role
- **Optional Checks**: Laws can implement multiple validation checks
- **State Management**: Laws can save and manage state
- **Function Return**: Laws return function calls to be executed
- **Protected Execution**: The `executeLaw` function can only be called by the associated `Powers.sol` deployment

## Core Functionality

### 1. Initialization
- Setting up law parameters and conditions
- Configuring role restrictions
- Defining validation rules

### 2. Execution Flow
1. **Validation**: Running checks for proposal and execution
2. **Request Handling**: Processing and transforming input data
3. **State Management**: Applying state changes if needed
4. **Reply**: Returning execution data to Powers protocol

### 3. State Management
- Tracking law executions
- Managing law conditions
- Storing law configuration
- Recording action IDs

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

## Governance Space

The Powers protocol ensures that each community can only interact with their adopted instance of a law. For example, the Yellow community cannot interfere with assigning roles in the Red community. This protects governance against outside interference.

<figure><img src="../../.gitbook/assets/image (4).png" alt=""><figcaption><p>Governance space of the Powers protocol </p></figcaption></figure>

🚧 **Everythign from here on is still completely work in progress and incomplete.** 🚧

## Law functionalities

The core functionality of a Law is to receive an input of Powers and to return an output back to the same contract. This is done through the `executeLaw` function. When this function is called, the following happens:

1. Checks are run.
2. The calldata is decoded and transformed on the function `handleRequest`.
3. If `handleRequest` returns target contracts to be called by Powers, these are returned by the `_replyPowers` function.
4. If `handleRequest` returns state data, these are saved by the `_changeState` function.
