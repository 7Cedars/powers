// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - the lawCalldata includes an array of arrays of descriptions, targets, values and calldatas to be used in the calls.
/// - the lawCalldata is decoded into an array of arrays of descriptions, targets, values and calldatas.
/// - the law shows an array of bool and their descriptions. Which ever one is set to true, will be executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

contract PresetMultipleActions is Law {
    /// @dev Data structure for storing preset action configurations
    struct Data {
        string[] descriptions; /// @dev Human-readable descriptions for each action
        address[] targets; /// @dev Target contract addresses for each action
        uint256[] values; /// @dev ETH values to send with each action
        bytes[] calldatas; /// @dev Calldata for each action
    }

    mapping(bytes32 lawHash => Data data) internal data;

    /// @notice Constructor of the PresetMultipleActions law
    constructor() {
        bytes memory configParams =
            abi.encode("string[] descriptions", "address[] targets", "uint256[] values", "bytes[] calldatas");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (string[] memory descriptions_, address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_)
        = abi.decode(config, (string[], address[], uint256[], bytes[]));

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({ descriptions: descriptions_, targets: targets_, values: values_, calldatas: calldatas_ });

        string[] memory parameters = new string[](descriptions_.length);

        for (uint256 i = 0; i < descriptions_.length; i++) {
            parameters[i] = string.concat("bool ", descriptions_[i]);
        }

        inputParams = abi.encode(parameters);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the law by executing selected preset actions
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        bool[] memory bools = abi.decode(lawCalldata, (bool[]));
        uint256 length = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                length++;
            }
        }
        if (length == 0) {
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
            return (actionId, targets, values, calldatas);
        }

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);
        uint256 j = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                targets[j] = data[lawHash].targets[i];
                values[j] = data[lawHash].values[i];
                calldatas[j] = data[lawHash].calldatas[i];
                j++;
            }
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a specific law instance
    /// @param lawHash The hash identifying the law instance
    /// @return The data structure containing all preset actions
    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
