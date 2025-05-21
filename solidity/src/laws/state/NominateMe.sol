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
    struct Data {
        mapping(address nominee => uint48 nominationTime) nominations;
        address[] nomineesSorted;
        uint256 nomineesCount;
    }

    mapping(bytes32 lawHash => Data data) internal data;

    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    constructor() {
        emit Law__Deployed("");
    }

    /// @notice Initializes the law with its configuration
    /// @param index Index of the law
    /// @param nameDescription Name of the law
    /// @param conditions Conditions for the law
    /// @param config Configuration data
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("bool NominateMe");
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);

        // nominating //
        if (nominateMe && data[lawHash].nominations[caller] != 0) {
            revert("Nominee already nominated.");
        }
        // revoke nomination //
        if (!nominateMe && data[lawHash].nominations[caller] == 0) {
            revert("Nominee not nominated.");
        }

        stateChange = abi.encode(caller, nominateMe); // encode the state
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address caller, bool nominateMe) = abi.decode(stateChange, (address, bool));

        if (nominateMe) {
            data[lawHash].nominations[caller] = uint48(block.number);
            data[lawHash].nomineesSorted.push(caller);
            data[lawHash].nomineesCount++;
            emit NominateMe__NominationReceived(caller);
        } else {
            data[lawHash].nominations[caller] = 0;
            for (uint256 i; i < data[lawHash].nomineesSorted.length; i++) {
                if (data[lawHash].nomineesSorted[i] == caller) {
                    data[lawHash].nomineesSorted[i] = data[lawHash].nomineesSorted[data[lawHash].nomineesSorted.length - 1];
                    data[lawHash].nomineesSorted.pop();
                    data[lawHash].nomineesCount--;
                    break;
                }
            }
            emit NominateMe__NominationRevoked(caller);
        }
    }

    function getNominees(bytes32 lawHash) public view returns (address[] memory) {
        return data[lawHash].nomineesSorted;
    }

    function isNominee(bytes32 lawHash, address nominee) public view returns (bool) {
        return data[lawHash].nominations[nominee] != 0;
    }

    function getNomineesCount(bytes32 lawHash) public view returns (uint256) {
        return data[lawHash].nomineesCount;
    }
}
