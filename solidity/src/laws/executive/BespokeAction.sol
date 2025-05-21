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

/// @notice A base contract that executes a bespoke action.
///
/// Note 1: as of now, it only allows for a single function to be called.
/// Note 2: as of now, it does not allow sending of ether values to the target function.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";

contract BespokeAction is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    mapping(bytes32 lawHash => address targetContract) public targetContract;
    mapping(bytes32 lawHash => bytes4 targetFunction) public targetFunction;

    /// @notice constructor of the law
    constructor() { 
        bytes memory configParams = abi.encode("address TargetContract", "bytes4 TargetFunction", "string[] Params");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (address targetContract_, bytes4 targetFunction_, string[] memory params_) =
            abi.decode(config, (address, bytes4, string[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        targetContract[lawHash] = targetContract_;
        targetFunction[lawHash] = targetFunction_;
        inputParams = abi.encode(params_);

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
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
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = targetContract[lawHash];
        calldatas[0] = abi.encodePacked(targetFunction[lawHash], lawCalldata);

        return (actionId, targets, values, calldatas, "");
    }
}
