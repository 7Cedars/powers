// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - the lawCalldata includes a single bool. If the bool is set to true, it will send the preset calldatas to the execute function of the Powers protocol.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

contract PresetSingleAction is Law {
    /// @dev Data structure for storing preset action configuration
    struct Data {
        address[] targets; /// @dev Target contract addresses for the action
        uint256[] values; /// @dev ETH values to send with the action
        bytes[] calldatas; /// @dev Calldata for the action
    }

    mapping(bytes32 lawHash => Data data) internal data;

    /// @notice Constructor of the PresetSingleAction law
    constructor() {
        bytes memory configParams = abi.encode("address[] targets", "uint256[] values", "bytes[] calldatas");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_) =
            abi.decode(config, (address[], uint256[], bytes[]));

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({ targets: targets_, values: values_, calldatas: calldatas_ });

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the law by returning the preset action data
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, data[lawHash].targets, data[lawHash].values, data[lawHash].calldatas);
    }

    /// @notice Get the stored data for a specific law instance
    /// @param lawHash The hash identifying the law instance
    /// @return The data structure containing the preset action
    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
