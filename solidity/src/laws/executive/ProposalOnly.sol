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

/// @notice A base contract that executes a open action.
///
/// Note As the contract allows for any action to be executed, it severely limits the functionality of the Powers protocol.
/// - any role that has access to this law, can execute any function. It has full power of the DAO.
/// - if this law is restricted by PUBLIC_ROLE, it means that anyone has access to it. Which means that anyone is given the right to do anything through the DAO.
/// - The contract should always be used in combination with modifiers from {PowerModiifiers}.
///
/// The logic:
/// - any the lawCalldata includes targets[], values[], calldatas[] - that are send straight to the Powers protocol. without any checks.
///
/// @author 7Cedars, 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract ProposalOnly is Law {
    /// @notice Constructor function for Open contract.
    /// @param name_ name of the law
    /// @param description_ description of the law
    /// @param powers_ the address of the core governance protocol
    /// @param allowedRole_ the role that is allowed to execute this law
    /// @param config_ the configuration of the law
    /// @param params_ the parameters of the function
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_,
        string[] memory params_
    ) Law(name_, powers_, allowedRole_, config_) {
        bytes memory params = abi.encode(params_);
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    // note that we are returning empty arrays as we are not executing any logic. 
    // we DO need to return the actionId as it has to be set to 'fulfilled' in the Powers contract.
    function handleRequest(address /*caller*/, bytes memory lawCalldata, uint256 nonce) public override view returns (
        uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange
        ) {
        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        return (actionId, targets, values, calldatas, "");
    }

    // note this law does not need to override handleRequest as it does not execute any logic.
}
