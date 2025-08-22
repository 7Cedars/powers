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
    mapping(bytes32 lawHash => mapping(string name => address account)) public stringToAddress;

    event StringToAddress__Added(string name, address account); 

    constructor(address powers) {
        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
        inputParams = abi.encode("string Name", "address Account");

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
        // retrieve the account that was revoked
        (string memory name, address account) = abi.decode(lawCalldata, (string, address));
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (string memory name, address account) = abi.decode(stateChange, (string, address));
        stringToAddress[lawHash][name] = account;
        emit StringToAddress__Added(name, account);
    }

    function getAddressByString(bytes32 lawHash, string memory name) public view returns (address account) {
        return stringToAddress[lawHash][name];
    }
}
