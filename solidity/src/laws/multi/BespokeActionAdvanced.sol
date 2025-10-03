// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @notice A base contract that executes a bespoke action with a single function call.
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

// import { console } from "forge-std/console.sol"; // only for testing purposes.

contract BespokeActionAdvanced is Law {
    /// @dev Data structure for storing law configuration
    struct Data {
        address targetContract; /// @dev Target contract address to call
        bytes4 targetFunction; /// @dev Function selector to call on target contract
        bytes[] staticParams; /// @dev Pre-encoded parameter fragments that don't change
        string[] dynamicParams; /// @dev UI hints for dynamic parameters (not used in execution)
        uint8[] indexDynamicParams; /// @dev Insertion indices for dynamic params relative to static params length
    }

    mapping(bytes32 => Data) internal _data;

    /// @notice Constructor of the BespokeActionAdvanced law
    constructor() {
        bytes memory configParams = abi.encode(
            "address TargetContract",
            "bytes4 TargetFunction",
            "bytes[] StaticParams",
            "string[] DynamicParams",
            "uint8[] IndexDynamicParams"
        );
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (
            address targetContract_,
            bytes4 targetFunction_,
            bytes[] memory staticParams_,
            string[] memory dynamicParams_,
            uint8[] memory indexDynamicParams_
        ) = abi.decode(config, (address, bytes4, bytes[], string[], uint8[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        _data[lawHash] = Data({
            targetContract: targetContract_,
            targetFunction: targetFunction_,
            staticParams: staticParams_,
            dynamicParams: dynamicParams_,
            indexDynamicParams: indexDynamicParams_
        });
        inputParams = abi.encode(dynamicParams_);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the law by calling the configured target function with mixed static/dynamic parameters
    /// @param lawCalldata the calldata containing dynamic parameters to insert into the function call
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = _data[lawHash].targetContract;
        calldatas[0] = _buildCalldata(lawHash, lawCalldata);

        return (actionId, targets, values, calldatas);
    }

    /// @dev Builds the calldata for the configured target function by inserting dynamic params
    /// into the preconfigured static params according to insertion indices, then prefixing
    /// the 4-byte function selector
    /// @param lawHash The hash identifying the law instance
    /// @param lawCalldata The dynamic parameters encoded as bytes[]
    /// @return The complete calldata ready for execution
    function _buildCalldata(bytes32 lawHash, bytes memory lawCalldata) internal view returns (bytes memory) {
        Data storage data = _data[lawHash];

        // lawCalldata is expected to be abi.encode(bytes[] dynamicParts) where
        // dynamicParts.length == data.indexDynamicParams.length
        bytes[] memory dynamicParts = abi.decode(lawCalldata, (bytes[]));

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
