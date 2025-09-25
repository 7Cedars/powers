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

/// @title FlagActions (standalone)
/// @notice Minimal helper to flag/unflag actionIds, controlled by a Powers contract
/// @dev Standalone pattern with immutable powers address and onlyPowers modifier
/// @author 7Cedars

pragma solidity 0.8.26;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FlagActions is Ownable {
    // Storage
    mapping(uint256 actionId => bool isFlagged) public flaggedActions;
    
    // Events
    event FlagActions__Flagged(uint256 actionId);
    event FlagActions__Unflagged(uint256 actionId);

    constructor(address powers) Ownable(powers) { }

    /// @notice Flags an action id. Reverts if already flagged
    function flag(uint256 actionId) external onlyOwner {
        if (flaggedActions[actionId]) revert("Already true");
        flaggedActions[actionId] = true;
        emit FlagActions__Flagged(actionId);
    }

    /// @notice Unflags an action id. Reverts if not flagged
    function unflag(uint256 actionId) external onlyOwner {
        if (!flaggedActions[actionId]) revert("Already false");
        flaggedActions[actionId] = false;
        emit FlagActions__Unflagged(actionId);
    }

    /// @notice View helper to check if an action is flagged
    function isActionIdFlagged(uint256 actionId) external view returns (bool) {
        return flaggedActions[actionId];
    }
}
