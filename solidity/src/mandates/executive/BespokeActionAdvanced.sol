// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a bespoke action with a single function call.
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

// import { console } from "forge-std/console.sol"; // only for testing purposes.

contract BespokeActionAdvanced is Mandate {
    /// @dev Data structure for storing mandate configuration
    struct Data {
        address targetContract; /// @dev Target contract address to call
        bytes4 targetFunction; /// @dev Function selector to call on target contract
        bytes[] staticParams; /// @dev Pre-encoded parameter fragments that don't change
        string[] dynamicParams; /// @dev UI hints for dynamic parameters (not used in execution)
        uint8[] indexDynamicParams; /// @dev Insertion indices for dynamic params relative to static params length
    }

    mapping(bytes32 => Data) internal _data;

    /// @notice Constructor of the BespokeActionAdvanced mandate
    constructor() {
        bytes memory configParams = abi.encode(
            "address TargetContract",
            "bytes4 TargetFunction",
            "bytes[] StaticParams",
            "string[] DynamicParams",
            "uint8[] IndexDynamicParams"
        );
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        (
            _data[mandateHash].targetContract,
            _data[mandateHash].targetFunction,
            _data[mandateHash].staticParams,
            _data[mandateHash].dynamicParams,
            _data[mandateHash].indexDynamicParams
        ) = abi.decode(config, (address, bytes4, bytes[], string[], uint8[]));

        inputParams = abi.encode(_data[mandateHash].dynamicParams);

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the mandate by calling the configured target function with mixed static/dynamic parameters
    /// @param mandateCalldata the calldata containing dynamic parameters to insert into the function call
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

        // Send the calldata to the target function
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = _data[mandateHash].targetContract;
        calldatas[0] = _buildCalldata(mandateHash, mandateCalldata);

        return (actionId, targets, values, calldatas);
    }

    /// @dev Builds the calldata for the configured target function by inserting dynamic params
    /// into the preconfigured static params according to insertion indices, then prefixing
    /// the 4-byte function selector
    /// @param mandateHash The hash identifying the mandate instance
    /// @param mandateCalldata The dynamic parameters encoded as bytes[]
    /// @return The complete calldata ready for execution
    function _buildCalldata(bytes32 mandateHash, bytes memory mandateCalldata) internal view returns (bytes memory) {
        Data storage data = _data[mandateHash];

        // mandateCalldata is expected to be abi.encode(bytes[] dynamicParts) where
        // dynamicParts.length == data.indexDynamicParams.length
        bytes[] memory dynamicParts = abi.decode(mandateCalldata, (bytes[]));

        if (dynamicParts.length != data.indexDynamicParams.length) revert("Bad Dynamic Length");
        uint256 staticLen = data.staticParams.length;

        // Compose parameter bytes in the following order:
        // for k in [0..staticLen-1]:
        //   append all dynamicParts[j] where indexDynamicParams[j] == k
        //   append staticParams[k]
        // finally append all dynamicParts[j] where indexDynamicParams[j] == staticLen (insert at end)

        bytes memory packedParams;
        for (uint256 k; k < staticLen; k++) {
            // Insert dynamics scheduled before static k
            for (uint256 j; j < dynamicParts.length; j++) {
                if (data.indexDynamicParams[j] == k) {
                    packedParams = abi.encodePacked(packedParams, dynamicParts[j]);
                }
            }
            // Append static param k
            packedParams = abi.encodePacked(packedParams, data.staticParams[k]);
        }

        // Append dynamics scheduled at the end
        for (uint256 j; j < dynamicParts.length; j++) {
            if (data.indexDynamicParams[j] == staticLen) {
                packedParams = abi.encodePacked(packedParams, dynamicParts[j]);
            }
        }

        return abi.encodePacked(data.targetFunction, packedParams);
    }
}
