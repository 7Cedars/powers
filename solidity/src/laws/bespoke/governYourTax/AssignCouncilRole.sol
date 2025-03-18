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

import { Law } from "../../../Law.sol";
import { Powers } from "../../../Powers.sol";
import { NominateMe } from "../../state/NominateMe.sol";
import { LawUtils } from "../../LawUtils.sol";

contract AssignCouncilRole is Law {
    uint32[] public councilRoles;

    constructor(
        // standard
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawChecks memory config_,
        // bespoke 
        uint32[] memory councilRoles_
    )  Law(name_, powers_, allowedRole_, config_) {

        councilRoles = councilRoles_;
        bytes memory params = abi.encode(["uint32 RoleId", "address Account"]);
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address /*initiator*/, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: create actionId & decode the calldata.
        actionId = LawUtils.hashActionId(address(this), lawCalldata, nonce);
        (uint32 roleId, address account) = abi.decode(lawCalldata, (uint32, address));
        
        // step 1: check if the role is allowed.
        bool allowed = false;
        for (uint8 i = 0; i < councilRoles.length; i++) {
            if (councilRoles[i] == roleId) {
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

        // step 2: create the arrays.
        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, roleId, account);

        // step 3: call super & return values. 
        return (actionId, targets, values, calldatas, stateChange);
    }
}
