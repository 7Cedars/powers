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

/// @notice This contract allows account holders to log themselves as nominated. The nomination can subsequently be used for an election process: see {DelegateSelect}, {RandomSelect} and {TokenSelect} for examples.
///
/// - The contract is meant to be open (using PUBLIC_ROLE) but can also be role restricted.
///    - anyone can nominate themselves for a role.
///
/// note: the private state var that stores nominees is exposed by calling the executeLaw function.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract NominateMe is Law { 
    mapping(address => uint48) public nominees;
    address[] public nomineesSorted;
    uint256 public nomineesCount;

    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_
    ) Law(name_, powers_, allowedRole_, config_) {
        bytes memory params = abi.encode("bool NominateMe");
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // decode the calldata.
        (bool nominateMe) = abi.decode(lawCalldata, (bool));

        // nominating //
        if (nominateMe && nominees[caller] != 0) {
            revert ("Nominee already nominated.");
        }
        // revoke nomination //
        if (!nominateMe && nominees[caller] == 0) {
            revert ("Nominee not nominated.");
        }

        stateChange = abi.encode(caller, nominateMe); // encode the state
        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes memory stateChange) internal override {
        (address caller, bool nominateMe) = abi.decode(stateChange, (address, bool));

        if (nominateMe) {
            nominees[caller] = uint48(block.number);
            nomineesSorted.push(caller);
            nomineesCount++;
            emit NominateMe__NominationReceived(caller);
        } else {
            nominees[caller] = 0;
            for (uint256 i; i < nomineesSorted.length; i++) {
                if (nomineesSorted[i] == caller) {
                    nomineesSorted[i] = nomineesSorted[nomineesSorted.length - 1];
                    nomineesSorted.pop();
                    nomineesCount--;
                    break;
                }
            }
            emit NominateMe__NominationRevoked(caller);
        }
    }
}
