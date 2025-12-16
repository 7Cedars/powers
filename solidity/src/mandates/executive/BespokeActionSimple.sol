// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a bespoke action.
///
/// Note 1: as of now, it only allows for a single function to be called.
/// Note 2: as of now, it does not allow sending of ether values to the target function.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

contract BespokeActionSimple is Mandate {
    /// @dev Mapping from mandate hash to target contract address for each mandate instance
    mapping(bytes32 mandateHash => address targetContract) public targetContract;
    /// @dev Mapping from mandate hash to target function selector for each mandate instance
    mapping(bytes32 mandateHash => bytes4 targetFunction) public targetFunction;

    /// @notice Constructor of the BespokeActionSimple mandate
    constructor() {
        bytes memory configParams =
            abi.encode("address TargetContract", "bytes4 FunctionSelector", "string[] Params");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address targetContract_, bytes4 targetFunction_, string[] memory params_) =
            abi.decode(config, (address, bytes4, string[]));
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        targetContract[mandateHash] = targetContract_;
        targetFunction[mandateHash] = targetFunction_;
        inputParams = abi.encode(params_);

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the mandate by calling the configured target function
    /// @param mandateCalldata the calldata _without function signature_ to send to the function
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Send the calldata to the target function
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = targetContract[mandateHash];
        calldatas[0] = abi.encodePacked(targetFunction[mandateHash], mandateCalldata);

        return (actionId, targets, values, calldatas);
    }
}
