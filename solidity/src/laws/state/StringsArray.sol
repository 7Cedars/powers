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

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract StringsArray is Law {
    // the state vars that this law manages: community strings.
    mapping(bytes32 lawHash => string[] strings) public strings;
    mapping(bytes32 lawHash => uint256 numberOfStrings) public numberOfStrings;

    event StringsArray__StringAdded(string str);
    event StringsArray__StringRemoved(string str);

    constructor() { emit Law__Deployed(""); }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("string String", "bool Add");
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
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (string memory str, bool add) = abi.decode(stateChange, (string, bool));

        if (add) {
            strings[lawHash].push(str);
            numberOfStrings[lawHash]++;
            emit StringsArray__StringAdded(str);
        } else if (numberOfStrings[lawHash] == 0) {
            revert("String not found.");
        } else {
            for (uint256 index; index < numberOfStrings[lawHash]; index++) {
                if (keccak256(bytes(strings[lawHash][index])) == keccak256(bytes(str))) {
                    strings[lawHash][index] = strings[lawHash][numberOfStrings[lawHash] - 1];
                    strings[lawHash].pop();
                    numberOfStrings[lawHash]--;
                    break;
                }

                if (index == numberOfStrings[lawHash] - 1) {
                    revert("String not found.");
                }
            }
            emit StringsArray__StringRemoved(str);
        }
    }
}
