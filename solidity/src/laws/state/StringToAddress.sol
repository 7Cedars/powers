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

/// @title StringToAddress - String to Address Management Contract for Powers Protocol
/// @notice Manages a mapping of strings to addresses for blacklisting or whitelisting purposes
/// @dev Inherits from Law contract to implement role-restricted string to address management
/// @author 7Cedars

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

// import "forge-std/Test.sol"; // only for testing

contract StringToAddress is Law {
    struct Memory {
        string name;
        address account;
        bytes32 lawHash;
        address caller;
        bytes callData;
    }

    mapping(bytes32 lawHash => mapping(string name => address account)) public stringToAddress;

    event StringToAddress__Added(string name, address account); 

    constructor() {
        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
        inputParams = abi.encode("string Name");

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        stateChange = abi.encode(caller, lawCalldata);
        
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        Memory memory mem;
        (mem.caller, mem.callData) = abi.decode(stateChange, (address, bytes));
        (mem.name) = abi.decode(mem.callData, (string));

        stringToAddress[lawHash][mem.name] = mem.caller;
        emit StringToAddress__Added(mem.name, mem.caller);
    }

    function getAddressByString(bytes32 lawHash, string memory name) public view returns (address account) {
        return stringToAddress[lawHash][name];
    }
}
