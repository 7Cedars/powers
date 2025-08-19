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

/// @title FlagActions - Flag Actions Contract for Powers Protocol
/// @notice Flags an action
/// @dev Inherits from Law contract to implement role-restricted action flagging
/// @author 7Cedars

/// @notice The logic of this law is to flag an action.
/// An actionId is mapped against a bool. 
/// This allows actionIds to be 'flagged'. 
/// Can be used to flag actions as malicious, etc.
// 
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/console2.sol"; // only for testing

contract FlagActions is Law {
    mapping(uint256 actionId => bool isFlagged) public flaggedActions;

    event FlagActions__Flagged(uint256 actionId);
    event FlagActions__Unflagged(uint256 actionId);

    constructor() { emit Law__Deployed(""); }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("uint256 ActionId", "bool Flag");

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    }

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
        // retrieve the account that was revoked
        (uint256 actionId, bool flag) = abi.decode(lawCalldata, (uint256, bool));
        if (uint8(Powers(payable(powers)).state(actionId)) != uint8(PowersTypes.ActionState.Fulfilled)) {
            revert("Action not fulfilled");
        }
        if (flag && flaggedActions[actionId]) {
            revert("Already true.");
        } else if (!flag && !flaggedActions[actionId]) {
            revert("Already false.");
        }

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint256 actionId, bool flag) = abi.decode(stateChange, (uint256, bool));

        if (flag) {
            flaggedActions[actionId] = true;
            emit FlagActions__Flagged(actionId);
        } else {
            flaggedActions[actionId] = false;
            emit FlagActions__Unflagged(actionId);
        }
    }

    function isActionIdFlagged(uint256 actionId) external view returns (bool) {
        return flaggedActions[actionId];
    }
}
