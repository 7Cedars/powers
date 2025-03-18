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
import { LawUtils } from "../LawUtils.sol";

contract DirectSelect is Law { 
    uint32 private immutable ROLE_ID;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawChecks memory config_,
        uint32 roleId_
    ) Law(name_, powers_, allowedRole_, config_) {
        ROLE_ID = roleId_;

        bytes memory params = abi.encode(
            "bool Assign", 
            "address Account"
            );
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address /*initiator*/, bytes memory lawCalldata, uint256 nonce)
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
        // Decode the calldata. Note that validating calldata is not possible at the moment. 
        // See this feature request: https://github.com/ethereum/solidity/issues/10381#issuecomment-1285986476
        // The feature request has been open for almost five years(!) at time of writing.  
        (bool assign, address account) = abi.decode(lawCalldata, (bool, address));

        // step 2: hash the proposal.
        actionId = LawUtils.hashActionId(address(this), lawCalldata, nonce);

        // step 3: create the arrays.
        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);

        // step 4: set the targets, values and calldatas.
        targets[0] = powers;
        if (!assign) {
            if (Powers(payable(powers)).hasRoleSince(account, ROLE_ID) == 0) {
                revert ("Account does not have role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, account); // selector = revokeRole
        } else {
            if (Powers(payable(powers)).hasRoleSince(account, ROLE_ID) != 0) {
                revert ("Account already has role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, account); // selector = assignRole
        }

        return (actionId, targets, values, calldatas, "");
    }
}
