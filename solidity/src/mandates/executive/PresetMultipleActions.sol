// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - the mandateCalldata includes an array of arrays of descriptions, targets, values and calldatas to be used in the calls.
/// - the mandateCalldata is decoded into an array of arrays of descriptions, targets, values and calldatas.
/// - the mandate shows an array of bool and their descriptions. Which ever one is set to true, will be executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

contract PresetMultipleActions is Mandate {
    /// @dev Data structure for storing preset action configurations
    struct Data {
        string[] descriptions; /// @dev Human-readable descriptions for each action
        address[] targets; /// @dev Target contract addresses for each action
        uint256[] values; /// @dev ETH values to send with each action
        bytes[] calldatas; /// @dev Calldata for each action
    }

    mapping(bytes32 mandateHash => Data data) internal data;

    /// @notice Constructor of the PresetMultipleActions mandate
    constructor() {
        bytes memory configParams =
            abi.encode("string[] descriptions", "address[] targets", "uint256[] values", "bytes[] calldatas");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        (
            data[mandateHash].descriptions,
            data[mandateHash].targets,
            data[mandateHash].values,
            data[mandateHash].calldatas
        ) = abi.decode(config, (string[], address[], uint256[], bytes[]));

        string[] memory parameters = new string[](data[mandateHash].descriptions.length);

        for (uint256 i = 0; i < data[mandateHash].descriptions.length; i++) {
            parameters[i] = string.concat("bool ", data[mandateHash].descriptions[i]);
        }

        inputParams = abi.encode(parameters);

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the mandate by executing selected preset actions
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
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        bool[] memory bools = abi.decode(mandateCalldata, (bool[]));
        uint256 length = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                length++;
            }
        }
        if (length == 0) {
            (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
            return (actionId, targets, values, calldatas);
        }

        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(length);
        uint256 j = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                targets[j] = data[mandateHash].targets[i];
                values[j] = data[mandateHash].values[i];
                calldatas[j] = data[mandateHash].calldatas[i];
                j++;
            }
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a specific mandate instance
    /// @param mandateHash The hash identifying the mandate instance
    /// @return The data structure containing all preset actions
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
