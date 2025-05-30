# Setting up a new law

🚧 **This page is incomplete.** 🚧

This guide explains how to create, deploy, and adopt a new law in the Powers protocol.

## Creating a Law

A law in Powers is a smart contract that implements the `ILaw` interface. Laws define specific actions that can be executed through the governance system, with configurable voting and execution parameters.

### Basic Structure

1. Create a new contract that inherits from `Law.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../Law.sol";

contract MyNewLaw is Law {
    constructor() {
        // Optional: Configure parameters needed at initlisation. This can be left empty.  
        bytes memory configParams = abi.encode(
            "uint256 maxBudgetLeft",
            "bool checkDuration"
        );
        emit Law__Deployed(configParams);
    }

    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    ) public view virtual override returns (
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes memory stateChange
    ) {
        // Implement your law's logic here
    }
}
```

### Key Components

1. **Optional Law Configuration**
   - Any input parameters need at inilisation, in the format of `abi.encode("type Name", "type2 Name2")`. 

2. **Required Functions**
   - `handleRequest()`: Core logic executed when the law is triggered
   - `_changeState()`: Handle state changes (if needed)
   - `_replyPowers()`: Define interactions with other powers

3. **Validation Functions**
   - `checksAtPropose()`: Validates conditions for proposing an action
   - `checksAtExecute()`: Validates conditions for executing an action

## Deploying a Law

1. **Compile the Contract**
   ```bash
   forge build
   ```

2. **Deploy to Network**
   ```bash
   forge script script/DeployMyNewLaw.s.sol --rpc-url <RPC_URL> --broadcast
   ```

3. **Verify Contract**
   ```bash
   forge verify-contract <DEPLOYED_ADDRESS> src/MyNewLaw.sol:MyNewLaw --chain-id <CHAIN_ID>
   ```

## Adopting a Law

To adopt a law in a Powers implementation:

1. **Initialize the Law**
   ```solidity
   function initializeLaw(
       uint16 index,
       string memory nameDescription,
       bytes memory inputParams, 
       Conditions memory conditions,
       bytes memory config // the abi encoded values needed for the optional input parameters. 
   ) public virtual
   ```

   Parameters:
   - `index`: Unique identifier for the law
   - `nameDescription`: Human-readable description
   - `inputParams`: Encoded input parameters
   - `conditions`: Voting and execution conditions
   - `config`: Additional configuration data for the law. 

2. **Register with Powers**
   - Call the Powers protocol's law registration function
   - Provide the law's address and configuration
   - Set up any required permissions

3. **Test the Integration**
   - Verify the law is properly registered
   - Test proposal creation
   - Test execution flow
   - Verify state changes

## Best Practices

1. **Security**
   - Implement proper access controls
   - Validate all inputs
   - Handle edge cases
   - Test thoroughly

2. **Gas Optimization**
   - Optimize storage usage
   - Minimize state changes
   - Use efficient data structures

3. **Documentation**
   - Document all parameters
   - Explain the law's purpose
   - Provide usage examples
   - Include error conditions

## Example Use Cases

1. **Executive Laws**
   - Token transfers
   - Parameter updates
   - Contract upgrades
   - Permission changes

2. **Electoral Laws**
   - Voting mechanisms
   - Election processes
   - Delegation rules

3. **State Laws**
   - State management
   - Data updates
   - Configuration changes

For more examples, refer to the existing laws in the protocol:
- Executive laws: `solidity/src/laws/executive/`
- Electoral laws: `solidity/src/laws/electoral/`
- State laws: `solidity/src/laws/state/`



