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
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract SnapToGov_CancelGov is Law {
    struct MemProposal {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
    }

    /// the targets, values and calldatas to be used in the calls: set at construction.
    mapping(bytes32 lawHash => address governorContract) public governorContracts;

    /// @notice constructor of the law
    constructor() {
        bytes memory configParams = abi.encode("address GovernorContract");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (address governorContract_) =
            abi.decode(config, (address));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        
        inputParams = abi.encode(
                "string ProposalId", 
                "string Choice", 
                "address[] Targets", 
                "uint256[] Values", 
                "bytes[] CallDatas",
                "string GovDescription"
        );

        governorContracts[lawHash] = governorContract_;
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
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
        MemProposal memory proposal;
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (   , 
            ,
            proposal.targets,
            proposal.values,
            proposal.calldatas,
            proposal.description
        ) = abi.decode(lawCalldata, (string, string, address[], uint256[], bytes[], string));

        uint256 proposalId = Governor(payable(governorContracts[lawHash])).getProposalId(
            proposal.targets, 
            proposal.values, 
            proposal.calldatas, 
            keccak256(bytes(proposal.description))
            );
        if (proposalId == 0) {    
            revert("Proposal not found");
        }

        IGovernor.ProposalState state = Governor(payable(governorContracts[lawHash])).state(proposalId);
        if (state == IGovernor.ProposalState.Succeeded || state == IGovernor.ProposalState.Expired || state == IGovernor.ProposalState.Canceled || state == IGovernor.ProposalState.Defeated || state == IGovernor.ProposalState.Executed) {
            revert("Proposal already succeeded, expired, canceled, defeated or executed");
        }

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = governorContracts[lawHash];
        calldatas[0] = abi.encodeWithSelector(Governor.cancel.selector, proposal.targets, proposal.values, proposal.calldatas, keccak256(bytes(proposal.description)));
        
        return (actionId, targets, values, calldatas, "");
    }
}
