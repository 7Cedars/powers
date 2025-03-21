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

contract AddressesMapping is Law { 
    mapping(address => bool) public addresses;

    event AddressesMapping__Added(address account);
    event AddressesMapping__Removed(address account);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_
    ) Law(name_, powers_, allowedRole_, config_) {
        bytes memory params = abi.encode(
            "address Account", 
            "bool Add"
        );
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address, /*caller */ bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // retrieve the account that was revoked
        (address account, bool add) = abi.decode(lawCalldata, (address, bool));

        if (add && addresses[account]) {
            revert ("Already true.");
        } else if (!add && !addresses[account]) {
            revert ("Already false.");
        }

        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);
        return (actionId, targets, values, calldatas, lawCalldata);
    }
    
    function _changeState(bytes memory stateChange) internal override {
        (address account, bool add) = abi.decode(stateChange, (address, bool));

        if (add) {
            addresses[account] = true;
            emit AddressesMapping__Added(account);
        } else {
            addresses[account] = false;
            emit AddressesMapping__Removed(account);
        }
    }
} 