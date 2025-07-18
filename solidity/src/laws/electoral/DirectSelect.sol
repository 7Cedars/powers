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

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract DirectSelect is Law {
    mapping(bytes32 lawHash => uint256 roleId) public roleId;

    constructor() {
        bytes memory configParams = abi.encode("uint256 roleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (uint256 roleId_) = abi.decode(config, (uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        roleId[lawHash] = roleId_;

        inputParams = abi.encode("address[] Accounts");

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    }

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
        // step 1: decode the calldata & create hashes .
        (address[] memory accounts) = abi.decode(lawCalldata, (address[]));
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 2 :check if addresses already have the role. If not, they will not be added to targets. 
        uint256 target = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (Powers(payable(powers)).hasRoleSince(accounts[i], roleId[lawHash]) == 0) {
                target++;
            }
        }
        // step 3: create empty arrays.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(target);

        // step 4: set the targets, values and calldatas
        target = 1;
        target = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (Powers(payable(powers)).hasRoleSince(account, roleId[lawHash]) == 0) {
                targets[target] = powers;
                values[target] = 0;
                calldatas[target] = abi.encodeWithSelector(Powers.assignRole.selector, roleId[lawHash], account); 
                target++;
            } 
        }

        return (actionId, targets, values, calldatas, "");
    }
}
