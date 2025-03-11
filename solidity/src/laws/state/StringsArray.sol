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

contract StringsArray is Law {
    // the state vars that this law manages: community strings.
    string[] public strings;
    uint256 public numberOfStrings;

    event StringsArray__StringAdded(string str);
    event StringsArray__StringRemoved(string str);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "string String", 
            "bool Add"
            );
        stateVars = inputParams;
    }

    function simulateLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // step 1: return data
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);
        tar[0] = address(1); // signals that powers should not execute anything else.

        return (tar, val, cal, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (string memory str, bool add) = abi.decode(stateChange, (string, bool)); // don't know if this is going to work...

        if (add) {
            strings.push(str);
            numberOfStrings++;
            emit StringsArray__StringAdded(str);
        } else if (numberOfStrings == 0) {
            revert ("String not found.");
        } else {
            for (uint256 index; index < numberOfStrings; index++) {
                if (keccak256(bytes(strings[index])) == keccak256(bytes(str))) {
                    strings[index] = strings[numberOfStrings - 1];
                    strings.pop();
                    numberOfStrings--;
                    break;
                }

                if (index == numberOfStrings - 1) {
                    revert ("String not found.");
                }
            }
            emit StringsArray__StringRemoved(str);
        }
    }
}
