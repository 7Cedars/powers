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

/// @notice This contract that assigns or revokes a roleId to the person that called the law.
/// - At construction time, the following is set:
///    - the role Id that the contract will be assigned or revoked.
///
/// - The contract is meant to be restricted by a specific role, allowing an outsider to freely claim an (entry) role into a DAO.
///
/// - The logic:
///
/// @dev The contract is an example of a law that
/// - an open role elect law.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract RenounceRole is Law { 
    uint32[] public allowedRoleIds; // role that can be renounced.

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_,
        uint32[] memory allowedRoleIds_
    ) Law(name_, powers_, allowedRole_, config_) {
        allowedRoleIds = allowedRoleIds_;
        bytes memory params = abi.encode("uint256 roleId");

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 1: decode the calldata.
        (uint256 roleId) = abi.decode(lawCalldata, (uint32));
        
        // step2: check if the role is allowed to be renounced.
        bool allowed = false;
        for (uint32 i = 0; i < allowedRoleIds.length; i++) {
            if (roleId == allowedRoleIds[i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            revert ("Role not allowed to be renounced.");
        }

        // step 3: create & send return calldata conditional if it is an assign or revoke action.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(allowedRoleIds.length);
        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);

        targets[0] = powers;
        if (Powers(payable(powers)).hasRoleSince(caller, roleId) == 0) {
            revert ("Account does not have role.");
        }
        calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, roleId, caller); // selector = revokeRole

        return (actionId, targets, values, calldatas, "");
    }

    function _replyPowers(uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
        internal
        override
    {
        Powers(payable(powers)).fulfill(actionId, targets, values, calldatas);
    }
}
