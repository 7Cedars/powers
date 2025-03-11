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

import { BespokeAction } from "../../executive/BespokeAction.sol";
import { Powers } from "../../../Powers.sol";
import { NominateMe } from "../../state/NominateMe.sol";

contract AssignCouncilRole is BespokeAction {
    uint32[] public allowedRoles;
    string[] public placeholder = new string[](1); 

    constructor(
        // standard
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // 
        uint32[] memory allowedRoles_
    ) BespokeAction(
        name_, 
        description_, 
        powers_, 
        allowedRole_, 
        config_, 
        // 
        powers_, // address targetContract_,
        Powers.assignRole.selector, // bytes4 targetFunction_, 
        placeholder // string[] memory inputParams_ // note: insert empty, below these values are overwritten.
        ) {
        allowedRoles = allowedRoles_;
        inputParams = abi.encode(["uint32 roleId", "address account"]);
    }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: decode the calldata.
        (uint32 roleId, address account) = abi.decode(lawCalldata, (uint32, address));
        
        // step 1: check if the role is allowed.
        bool allowed = false;
        for (uint8 i = 0; i < allowedRoles.length; i++) {
            if (allowedRoles[i] == roleId) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            revert ("Role not allowed."); 
        }

        // step 2: check if the account is nominated.
        if (NominateMe(config.readStateFrom).nominees(account) == 0) {
            revert ("Account not nominated.");
        }
      
        // step 2: call super & return values. 
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }
}
