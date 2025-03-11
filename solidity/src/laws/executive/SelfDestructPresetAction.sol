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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars
pragma solidity 0.8.26;

// laws
import { PresetAction } from "./PresetAction.sol";
import { SelfDestruct } from "../modules/SelfDestruct.sol";

contract SelfDestructPresetAction is PresetAction, SelfDestruct {
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    )
        PresetAction(name_, description_, powers_, allowedRole_, config_, targets_, values_, calldatas_)
        SelfDestruct()
    { }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override(PresetAction, SelfDestruct)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }
}
