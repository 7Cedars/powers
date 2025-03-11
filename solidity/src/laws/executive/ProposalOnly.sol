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
        uint32 allowedRole_,
        LawConfig memory config_,
        string[] memory params_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        /// £todo: this should actually be a separate function 'encodeParams' with a revert if more than 8 params are entered.
        inputParams = abi.encode(params_);
    }

    /// @notice Execute the open action.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (
            // return an empty array.
            address[] memory tar,
            uint256[] memory val,
            bytes[] memory cal,
            bytes memory stateChange
        )
    {
        // at execution, send empty calldata to protocol. -- nothing gets done.
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        tar[0] = address(1); // targets[0] = address(1) is a signal to the protocol that it should not try and execute anything.
    }
}
