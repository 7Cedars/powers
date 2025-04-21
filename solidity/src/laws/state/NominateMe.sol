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
    struct Nominees {
        mapping(address nominee => uint48 nominationTime) nominations;
        address[] nomineesSorted;
        uint256 nomineesCount;
    }
    mapping(bytes32 lawHash => Nominees nominees) public nominees;

    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

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
        inputParams = abi.encode("bool NominateMe");
        super.initializeLaw(index, conditions, config, inputParams, description);
    }

    function handleRequest(address caller, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        // decode the calldata.
        (bool nominateMe) = abi.decode(lawCalldata, (bool));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);

        // nominating //
        if (nominateMe && nominees[lawHash].nominations[caller] != 0) {
            revert("Nominee already nominated.");
        }
        // revoke nomination //
        if (!nominateMe && nominees[lawHash].nominations[caller] == 0) {
            revert("Nominee not nominated.");
        }

        stateChange = abi.encode(caller, nominateMe); // encode the state
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address caller, bool nominateMe) = abi.decode(stateChange, (address, bool));

        if (nominateMe) {
            nominees[lawHash].nominations[caller] = uint48(block.number);
            nominees[lawHash].nomineesSorted.push(caller);
            nominees[lawHash].nomineesCount++;
            emit NominateMe__NominationReceived(caller);
        } else {
            nominees[lawHash].nominations[caller] = 0;
            for (uint256 i; i < nominees[lawHash].nomineesSorted.length; i++) {
                if (nominees[lawHash].nomineesSorted[i] == caller) {
                    nominees[lawHash].nomineesSorted[i] = nominees[lawHash].nomineesSorted[nominees[lawHash].nomineesSorted.length - 1];
                    nominees[lawHash].nomineesSorted.pop();
                    nominees[lawHash].nomineesCount--;
                    break;
                }
            }
            emit NominateMe__NominationRevoked(caller);
        }
    }

    function getNominees(bytes32 lawHash) public view returns (address[] memory) {
        return nominees[lawHash].nomineesSorted;
    }

    function isNominee(bytes32 lawHash, address nominee) public view returns (bool) {
        return nominees[lawHash].nominations[nominee] != 0;
    }

    function getNomineesCount(uint16 lawId) public view returns (uint256) {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        return nominees[lawHash].nomineesCount;
    }
}
