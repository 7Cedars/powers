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

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - the lawCalldata includes an array of arrays of descriptions, targets, values and calldatas to be used in the calls.
/// - the lawCalldata is decoded into an array of arrays of descriptions, targets, values and calldatas.
/// - the law shows an array of bool and their descriptions. Which ever one is set to true, will be executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract PresetMultipleActions is Law {
    struct Data {
        string[] descriptions;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
    }
    /// the targets, values and calldatas to be used in the calls: set at construction.

    mapping(bytes32 lawHash => Data data) internal data;

    /// @notice constructor of the law 
    constructor() {
        bytes memory configParams = abi.encode("string[] descriptions", "address[] targets", "uint256[] values", "bytes[] calldatas");
        emit Law__Deployed(configParams); // empty params
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        (
            string[] memory descriptions_, 
            address[] memory targets_, 
            uint256[] memory values_, 
            bytes[] memory calldatas_
            ) = abi.decode(config, (string[], address[], uint256[], bytes[]));

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({ descriptions: descriptions_, targets: targets_, values: values_, calldatas: calldatas_ });

        string[] memory parameters = new string[](descriptions_.length);

        for (uint256 i = 0; i < descriptions_.length; i++) {
            parameters[i] = string.concat("bool ", descriptions_[i]);
        }

        inputParams = abi.encode(parameters);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice execute the law.
    function handleRequest(address /*caller*/, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        
        bool[] memory bools = abi.decode(lawCalldata, (bool[]));
        uint256 length = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                length++;
            }
        }
        if (length == 0) {
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
            return (actionId, targets, values, calldatas);
        }
        
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);
        uint256 j = 0;
        for (uint256 i = 0; i < bools.length; i++) {
            if (bools[i]) {
                targets[j] = data[lawHash].targets[i];
                values[j] = data[lawHash].values[i];
                calldatas[j] = data[lawHash].calldatas[i];
                j++;
            }
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
