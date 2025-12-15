// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - the mandateCalldata includes a single bool. If the bool is set to true, it will send the preset calldatas to the execute function of the Powers protocol.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

contract PresetSingleAction is Mandate {
    /// @dev Data structure for storing preset action configuration
    struct Data {
        address[] targets; /// @dev Target contract addresses for the action
        uint256[] values; /// @dev ETH values to send with the action
        bytes[] calldatas; /// @dev Calldata for the action
    }

    mapping(bytes32 mandateHash => Data data) internal data;

    /// @notice Constructor of the PresetSingleAction mandate
    constructor() {
        bytes memory configParams = abi.encode("address[] targets", "uint256[] values", "bytes[] calldatas");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_) =
            abi.decode(config, (address[], uint256[], bytes[]));

        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        data[mandateHash] = Data({ targets: targets_, values: values_, calldatas: calldatas_ });

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the mandate by returning the preset action data
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

        return (actionId, data[mandateHash].targets, data[mandateHash].values, data[mandateHash].calldatas);
    }

    /// @notice Get the stored data for a specific mandate instance
    /// @param mandateHash The hash identifying the mandate instance
    /// @return The data structure containing the preset action
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
