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

contract BespokeActionAdvanced is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.

    struct Data {
        address targetContract;
        bytes4 targetFunction;
        bytes[] staticParams; // each item is a pre-encoded parameter fragment
        string[] dynamicParams; // UI hinting only
        uint8[] indexDynamicParams; // insertion indices relative to original staticParams length
    }

    mapping(bytes32 => Data) internal _data;

    /// @notice constructor of the law
    constructor() {
        bytes memory configParams = abi.encode("address TargetContract", "bytes4 TargetFunction", "bytes[] StaticParams", "string[] DynamicParams", "uint8[] IndexDynamicParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        (address targetContract_, bytes4 targetFunction_, bytes[] memory staticParams_, string[] memory dynamicParams_, uint8[] memory indexDynamicParams_) =
            abi.decode(config, (address, bytes4, bytes[], string[], uint8[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        _data[lawHash] = Data({ targetContract: targetContract_, targetFunction: targetFunction_, staticParams: staticParams_, dynamicParams: dynamicParams_, indexDynamicParams: indexDynamicParams_ });
        inputParams = abi.encode(dynamicParams_);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address /*caller*/, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = _data[lawHash].targetContract;
        calldatas[0] = _buildCalldata(lawHash, lawCalldata);

        return (actionId, targets, values, calldatas);
    }

    /// @dev Builds the calldata for the configured target function by inserting dynamic params
    /// into the preconfigured static params according to insertion indices, then prefixing
    /// the 4-byte function selector.
    function _buildCalldata(bytes32 lawHash, bytes memory lawCalldata) internal view returns (bytes memory) {
        Data storage data = _data[lawHash];

        // lawCalldata is expected to be abi.encode(bytes[] dynamicParts) where
        // dynamicParts.length == d.indexDynamicParams.length
        bytes[] memory dynamicParts = abi.decode(lawCalldata, (bytes[]));

        if(dynamicParts.length != data.indexDynamicParams.length) revert ("Bad Dynamic Length");
        uint256 staticLen = data.staticParams.length;

        // Compose parameter bytes in the following order:
        // for k in [0..staticLen-1]:
        //   append all dynamicParts[j] where indexDynamicParams[j] == k
        //   append staticParams[k]
        // finally append all dynamicParts[j] where indexDynamicParams[j] == staticLen (insert at end)

        bytes memory packedParams;
        for (uint256 k; k < staticLen; k++) {
            // insert dynamics scheduled before static k
            for (uint256 j; j < dynamicParts.length; j++) {
                if (data.indexDynamicParams[j] == k) {
                    packedParams = abi.encodePacked(packedParams, dynamicParts[j]);
                }
            }
            // append static param k
            packedParams = abi.encodePacked(packedParams, data.staticParams[k]);
        }

        // append dynamics scheduled at the end
        for (uint256 j; j < dynamicParts.length; j++) {
            if (data.indexDynamicParams[j] == staticLen) {
                packedParams = abi.encodePacked(packedParams, dynamicParts[j]);
            }
        }

        return abi.encodePacked(data.targetFunction, packedParams);
    }
}
