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
    struct Data {
        address targetContract;
        bytes4 targetFunction;
    }

    mapping(bytes32 mandateHash => Data) public data;

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
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        string[] memory params_;

        (data[mandateHash].targetContract, data[mandateHash].targetFunction, params_) =
            abi.decode(config, (address, bytes4, string[]));

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
        targets[0] = data[mandateHash].targetContract;
        calldatas[0] = abi.encodePacked(data[mandateHash].targetFunction, mandateCalldata);

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a mandate
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
