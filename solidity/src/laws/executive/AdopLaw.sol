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
import { ILaw } from "../../interfaces/ILaw.sol";

contract AdoptLaw is Law {
    /// @notice constructor of the law
    /// @param name_ the name of the law.

    constructor(
        // standard parameters
        string memory name_
    ) { 
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
        inputParams = abi.encode("address Law, address Law, uint256 AllowedRole, uint16 NeedCompleted, uint48 DelayExecution, uint48 ThrottleExecution, uint16 ReadStateFrom, uint32 VotingPeriod, uint8 Quorum, uint8 SucceedAt, uint16 NeedNotCompleted, bytes Config, string Description");

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        (ILaw.Conditions memory conditionsLaw) = abi.decode(config, (ILaw.Conditions));
        conditionsNewLaw[lawHash] = conditionsLaw;

        super.initializeLaw(index, conditions, config, inputParams, description);
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address, /*caller*/ uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (
            address law, 
            uint256 allowedRole, 

            uint32 votingPeriod, 
            uint8 quorum, 
            uint8 succeedAt, 

            uint16 needCompleted, 
            uint16 needNotCompleted, 
            uint16 readStateFrom,
            uint48 delayExecution, 
            uint48 throttleExecution, 
             
            bytes memory config,  
            string memory description) = abi.decode(lawCalldata, (address, uint256, uint32, uint8, uint8, uint16, uint16, uint16, uint48, uint48, bytes, string));

        ILaw.Conditions memory conditions = ILaw.Conditions({
            allowedRole: allowedRole,
            needCompleted: needCompleted,
            delayExecution: delayExecution,
            throttleExecution: throttleExecution,
            readStateFrom: readStateFrom,
            votingPeriod: votingPeriod,
            quorum: quorum,
            succeedAt: succeedAt,
            needNotCompleted: needNotCompleted
        });

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = law;
        calldatas[0] = abi.encodeWithSelector(IPowers.adoptLaw.selector, law, config, conditions, description);

        return (actionId, targets, values, calldatas, "");
    }
}
