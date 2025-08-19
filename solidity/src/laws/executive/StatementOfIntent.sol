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
/// - any the lawCalldata includes targets[], values[], calldatas[] - that are send straight to the Powers protocol. without any checks.
/// - the lawCalldata is not executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract StatementOfIntent is Law {
    /// @notice Constructor function for Open contract.
    constructor() {
        bytes memory configParams = abi.encode("string[] InputParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = config;

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    
    }

    // note that we are returning empty arrays as we are not executing any logic.
    // we DO need to return the actionId as it has to be set to 'fulfilled' in the Powers contract.
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1); // if we send an array of length 0, the actionId will not be set as fulfilled.

        return (actionId, targets, values, calldatas, "");
    }

    // note this law does not need to override handleRequest as it does not execute any logic.
}
