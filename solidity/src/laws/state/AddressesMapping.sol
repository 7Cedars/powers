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

/// @title AddressesMapping - Address Management Contract for Powers Protocol
/// @notice Manages a mapping of addresses for blacklisting or whitelisting purposes
/// @dev Inherits from Law contract to implement role-restricted address management
/// @author 7Cedars

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

import "forge-std/Test.sol"; // only for testing

contract AddressesMapping is Law {
    mapping(bytes32 lawHash => mapping(address account => bool isAllowed)) public addresses;

    event AddressesMapping__Added(address account);
    event AddressesMapping__Removed(address account);

    constructor(string memory name_) {
        LawUtilities.checkStringLength(name_);
        name = name_;
        
        emit Law__Deployed(name_, "");
    }

    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        inputParams = abi.encode("address Account", "bool Add");

        super.initializeLaw(index, conditions, config, inputParams, description);
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
        console.log("handle request triggered");
        (address account, bool add) = abi.decode(lawCalldata, (address, bool));
        console.log("account: ", account);
        console.log("add: ", add);
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        console.logBytes32(lawHash);

        if (add && addresses[lawHash][account]) {
            revert("Already true.");
        } else if (!add && !addresses[lawHash][account]) {
            revert("Already false.");
        }
        console.log("passed checks");
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        console.log("actionId: ", actionId);
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address account, bool add) = abi.decode(stateChange, (address, bool));

        if (add) {
            addresses[lawHash][account] = true;
            emit AddressesMapping__Added(account);
        } else {
            addresses[lawHash][account] = false;
            emit AddressesMapping__Removed(account);
        }
    }
}
