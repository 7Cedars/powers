# Executing actions

Executing an action in the Powers protocol follows a request and callback logic between the Powers contract and Law contracts. Here's how it works:

## Requesting an action

An account requests an action by calling the `request` function in Powers.sol. It takes the following parameters:

* `lawId`: The ID of the law that will be called
* `lawCalldata`: The encoded function call data for the law
* `nonce`: A random nonce to ensure uniqueness
* `uriAction`: A brief description or URI to an IPFS document

## Execution Flow

1. **Initial Request**
   - User calls `request()` in Powers.sol
   - Powers checks if:
     - The law is active
     - The caller has the appropriate role to call this law
     - The action hasn't been requested before
     - The action hasn't been cancelled
   - If all checks pass, Powers creates an actionId by hashing `lawId`, `lawCalldata`, and `nonce`
   - Powers stores the action details in its `_actions` mapping
   - Powers calls `executeLaw()` on the target law contract

2. **Law Execution**
   - The law's `executeLaw()` function is called with:
     - `caller`: The original requestor's address
     - `lawId`: The ID of the law
     - `lawCalldata`: The original calldata
     - `nonce`: The original nonce
   - The law performs validation checks:
     - `checksAtPropose()`: Validates proposal conditions
     - `checksAtExecute()`: Validates execution conditions
   - The law calls its `handleRequest()` function which:
     - Processes the request
     - Returns execution data including:
       - `actionId`: The unique identifier
       - `targets`: Array of contract addresses to call
       - `values`: Array of ETH values to send
       - `calldatas`: Array of encoded function calls
       - `stateChange`: Any state changes to apply

3. **State Changes and Execution**
   - If `stateChange` is returned, the law calls `_changeState()` to apply state changes
   - The law calls `_replyPowers()` which calls back to Powers.sol's `fulfill()` function
   - The law records the execution in its storage

4. **Final Execution**
   - Powers.sol's `fulfill()` function:
     - Verifies the caller is an active law
     - Verifies the action was requested
     - Executes all the calls returned by the law
     - Marks the action as fulfilled
     - Emits an `ActionExecuted` event

## ActionId

The `actionId` is a crucial component that:
- Is created when `request()` is called by hashing `lawId`, `lawCalldata`, and `nonce`
- Is used to track the action throughout its lifecycle
- Is used by laws to check the status of specific actions
- Ensures uniqueness of actions and prevents replay attacks

## Important Considerations

1. **Role Restrictions**
   - All actions are role-restricted
   - The caller must have the appropriate role to call the law
   - Role checks happen at both the Powers and Law level

2. **State Management**
   - Laws can maintain their own state
   - State changes are applied before execution
   - Each execution is recorded in the law's storage

3. **Error Handling**
   - If any check fails, the entire execution reverts
   - Laws can implement custom validation logic
   - Failed executions are recorded in the law's storage

4. **Gas Considerations**
   - Each step in the execution flow consumes gas
   - Complex laws with many state changes will cost more
   - Failed executions still consume gas up to the point of failure
