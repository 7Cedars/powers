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
/// - anythe lawCalldata includes a single bool. If the bool is set to true, it will aend the present calldatas to the execute function of the Powers protocol.
///
/// @author 7Cedars, 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract PresetAction is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    mapping(bytes32 lawHash => address[] targets) public targets;
    mapping(bytes32 lawHash => uint256[] values) public values;
    mapping(bytes32 lawHash => bytes[] calldatas) public calldatas;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law. 
    constructor(
        // inherited from Law
        string memory name_,
        string memory description_
    ) Law(name_) {
        bytes memory configParams = abi.encode(
            "address[] targets",
            "uint256[] values",
            "bytes[] calldatas"
        ); 

        emit Law__Deployed(name_, description_, configParams); // empty params
    }

    function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
        (address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_) = abi.decode(inputParams, (address[], uint256[], bytes[]));
        
        bytes32 lawHash = hashLaw(msg.sender, index);
        targets[lawHash] = targets_;
        values[lawHash] = values_;
        calldatas[lawHash] = calldatas_;

        super.initializeLaw(index, conditions, config, inputParams);
    }

    /// @notice execute the law.
    function handleRequest(address /*caller*/, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory, uint256[] memory, bytes[] memory, bytes memory)
    {
        bytes32 lawHash = hashLaw(msg.sender, lawId);
        actionId = hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets[lawHash], values[lawHash], calldatas[lawHash], "");  
    }
}
