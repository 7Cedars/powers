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

/// @notice A base contract that takes an input but does not execute any logic.
///
/// The logic:
/// - the lawCalldata includes targets[], values[], calldatas[] - that are sent straight to the Powers protocol without any checks.
/// - the lawCalldata is not executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

contract StatementOfIntent is Law {
    /// @notice Constructor function for StatementOfIntent law
    constructor() {
        // This law does not require config; it forwards user-provided calls.
        // Expose expected input parameters for UIs.
        bytes memory configParams = abi.encode("string[] inputParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = config;
        
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Return calls provided by the user without modification
    /// @param lawCalldata The calldata containing targets, values, and calldatas arrays
    /// @return actionId The unique action identifier
    /// @return targets Array of target contract addresses
    /// @return values Array of ETH values to send
    /// @return calldatas Array of calldata for each call
    function handleRequest(
        address, /*caller*/
        address, /*powers*/
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        pure
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        return (actionId, targets, values, calldatas);
    }
}
