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
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract RenounceRole is Law {
    mapping(bytes32 lawHash => uint256[] allowedRoleIds) public allowedRoleIds; // role that can be renounced.

    constructor() {
        bytes memory configParams = abi.encode("uint256[] allowedRoleIds");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        uint256[] memory allowedRoleIds_ = abi.decode(config, (uint256[]));
        allowedRoleIds[LawUtilities.hashLaw(msg.sender, index)] = allowedRoleIds_;
        
        inputParams = abi.encode("uint256 roleId");
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        // step 1: decode the calldata.
        (uint256 roleId) = abi.decode(lawCalldata, (uint256));
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);

        // step2: check if the role is allowed to be renounced.
        bool allowed = false;
        for (uint256 i = 0; i < allowedRoleIds[lawHash].length; i++) {
            if (roleId == allowedRoleIds[lawHash][i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            revert("Role not allowed to be renounced.");
        }

        // step 3: create & send return calldata conditional if it is an assign or revoke action.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        targets[0] = powers;
        if (Powers(payable(powers)).hasRoleSince(caller, roleId) == 0) {
            revert("Account does not have role.");
        }
        calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, roleId, caller); // selector = revokeRole

        return (actionId, targets, values, calldatas, "");
    }

    function getAllowedRoleIds(bytes32 lawHash) public view returns (uint256[] memory) {
        return allowedRoleIds[lawHash];
    }
}
