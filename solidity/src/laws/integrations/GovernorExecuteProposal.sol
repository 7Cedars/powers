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
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

contract GovernorExecuteProposal is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    mapping(bytes32 lawHash => address governorContract) public governorContracts;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    constructor(
        // standard parameters
        string memory name_
    ) { 
        LawUtilities.checkStringLength(name_);
        name = name_;
        bytes memory configParams = abi.encode("address GovernorContract");

        emit Law__Deployed(name_, configParams);
    }

    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        (address governorContract_) =
            abi.decode(config, (address));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        governorContracts[lawHash] = governorContract_;
        inputParams = abi.encode(
            "address[] Targets",
            "uint256[] Values",
            "bytes[] Calldatas",
            "string Description"
        );

        super.initializeLaw(index, conditions, config, inputParams, description);
    }

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

        (address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_, string memory description_) = abi.decode(lawCalldata, (address[], uint256[], bytes[], string));

        uint256 proposalId = Governor(governorContracts[lawHash]).getProposalId(
            targets_, 
            values_, 
            calldatas_, 
            keccak256(abi.encodePacked(description_))
        );
        if (proposalId == 0) {
            revert("Proposal not found");
        }
        uint256 state = Governor(governorContracts[lawHash]).state(proposalId);
        if (state != Governor.ProposalState.Succeeded) {
            revert("Proposal not succeeded");
        }

        // send empty calldata to the Powers contract so that the law will be marked as fulfilled. .
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        return (actionId, targets, values, calldatas, "");
    }
}
