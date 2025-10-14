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

/// @notice Allows a caller to claim a specific role if they do not already hold it.
/// @dev The deployer configures a single roleId that can be self-assigned. Intended for
/// open onboarding flows where a base role can be freely claimed.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

contract SelfSelect is Law {
    mapping(bytes32 lawHash => uint256 roleId) public roleIds;

    /// @notice Constructor for SelfSelect law
    constructor() {
        bytes memory configParams = abi.encode("uint256 RoleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        uint256 roleId_ = abi.decode(config, (uint256));
        roleIds[LawUtilities.hashLaw(msg.sender, index)] = roleId_;

        inputParams = abi.encode();
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build a call to assign the configured role to the caller if not already held
    /// @param caller The transaction originator (forwarded to assignment)
    /// @param powers The Powers contract address
    /// @param lawId The law identifier
    /// @param lawCalldata Not used for this law
    /// @param nonce Unique nonce to build the action id
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        if (Powers(payable(powers)).hasRoleSince(caller, roleIds[lawHash]) != 0) {
            revert("Account already has role.");
        }

        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, roleIds[lawHash], caller); // selector = assignRole

        return (actionId, targets, values, calldatas);
    }
}
