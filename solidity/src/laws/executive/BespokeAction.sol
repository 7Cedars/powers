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

/// @notice A base contract that executes a bespoke action.
///
/// Note 1: as of now, it only allows for a single function to be called.
/// Note 2: as of now, it does not allow sending of ether values to the target function.
///
/// @author 7Cedars, 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";

contract BespokeAction is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    address private _targetContract;
    bytes4 private _targetFunction;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law.
    /// @param powers_ the address of the core governance protocol
    /// @param allowedRole_ the role that is allowed to execute this law
    /// @param config_ the configuration of the law
    /// @param targetContract_ the address of the target contract
    /// @param targetFunction_ the function of the target contract
    /// @param params_ the parameters of the function
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address targetContract_,
        bytes4 targetFunction_,
        string[] memory params_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        _targetContract = targetContract_;
        _targetFunction = targetFunction_;
        inputParams = abi.encode(params_);
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        // send the calldata to the target function
        targets[0] = _targetContract;
        calldatas[0] = abi.encodePacked(_targetFunction, lawCalldata);
    }
}
