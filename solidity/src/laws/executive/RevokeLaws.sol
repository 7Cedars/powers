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

/// @notice Revoke a set of laws configured at initialization.
/// @dev Builds calls to `IPowers.revokeLaw` for each configured law. No self-destruction occurs.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract RevokeLaws is Law {
    constructor() {
        bytes memory configParams = abi.encode();
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode("uint16[] lawIds");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to revoke the configured laws
    /// @param lawCalldata Unused for this law
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (uint16[] memory lawIds_) = abi.decode(lawCalldata, (uint16[]));

        // Create arrays for the calls to revokeLaw
        uint256 length = lawIds_.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);
        for (uint256 i; i < length; i++) {
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawIds_[i]);
        }
        return (actionId, targets, values, calldatas);
    }
}
