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

/// @notice This contract assigns a role Id based on an account having another role already. 
/// It is usefule to create 'grouped' roles. (as in, everyone with a specific contrib role, can apply to a generic contrib role as well.)
/// It works both ways: it also revokes a role if the account does not have any of the necessary roles anymore. 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract RoleByRoles is Law {
    struct Data {
        uint256 newRoleId;
        uint256[] roleIdsNeeded;
    }
    mapping(bytes32 lawHash => Data data) public data;

    constructor() {
        bytes memory configParams = abi.encode("uint256 newRoleId", "uint256[] roleIdsNeeded");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        (uint256 newRoleId_, uint256[] memory roleIdsNeeded_) = abi.decode(config, (uint256, uint256[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({
            newRoleId: newRoleId_,
            roleIdsNeeded: roleIdsNeeded_
        });

        inputParams = abi.encode("address Account");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    function handleRequest(address /* caller */, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        // step 1: decode the calldata & create hashes .
        (address account) = abi.decode(lawCalldata, (address));
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 2: check if the account has any of the needed roles, and if it already has the new role. 
        Data memory data_ = data[lawHash];
        bool hasAnyOfNeededRoles = false; 
        for (uint256 i = 0; i < data_.roleIdsNeeded.length; i++) {
            if (Powers(payable(powers)).hasRoleSince(account, data_.roleIdsNeeded[i]) > 0) {
                hasAnyOfNeededRoles = true;
                break;
            }
        }
        bool alreadyHasNewRole = Powers(payable(powers)).hasRoleSince(account, data_.newRoleId) > 0;

        // step 3: create empty arrays.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        // step 4: set the targets, values and calldatas according to the outcomes at step 2. 
        if (hasAnyOfNeededRoles && !alreadyHasNewRole) {
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data_.newRoleId, account);
        } 
        if (!hasAnyOfNeededRoles && alreadyHasNewRole) {
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, data_.newRoleId, account);
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
