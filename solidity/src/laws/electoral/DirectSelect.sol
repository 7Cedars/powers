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

contract DirectSelect is Law {
    mapping(bytes32 lawHash => uint256 roleId) public roleId;

    constructor(string memory name_) Law(name_) {
        bytes memory configParams = abi.encode("uint256 roleId");
        emit Law__Deployed(name_, configParams);
    }

    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        (uint256 roleId_) = abi.decode(config, (uint256));
        roleId[LawUtilities.hashLaw(msg.sender, index)] = roleId_;

        inputParams = abi.encode("bool Assign", "address Account");

        super.initializeLaw(index, conditions, config, inputParams, description);
    }

    function handleRequest(address, /*caller*/ uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);

        // Decode the calldata. Note that validating calldata is not possible at the moment.
        // See this feature request: https://github.com/ethereum/solidity/issues/10381#issuecomment-1285986476
        // The feature request has been open for almost five years(!) at time of writing.
        (bool assign, address account) = abi.decode(lawCalldata, (bool, address));

        // step 2: hash the proposal.
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 3: create the arrays.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        // step 4: set the targets, values and calldatas.
        targets[0] = msg.sender;
        if (!assign) {
            if (Powers(payable(msg.sender)).hasRoleSince(account, roleId[lawHash]) == 0) {
                revert("Account does not have role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, roleId[lawHash], account); // selector = revokeRole
        } else {
            if (Powers(payable(msg.sender)).hasRoleSince(account, roleId[lawHash]) != 0) {
                revert("Account already has role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, roleId[lawHash], account); // selector = assignRole
        }

        return (actionId, targets, values, calldatas, "");
    }
}
