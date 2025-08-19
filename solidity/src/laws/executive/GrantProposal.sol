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

/// @notice A base to create a grant proposal. 
///
/// The logic:
/// - Creates a grant proposal
/// - If PrevProposalId is set, it checks if the proposal has been executed at the readStateFrom law. - this should be in instance of FlagActions.sol
/// - If not, it reverts.
/// - If it has been executed, it does not revert.
/// 
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { LawUtilities } from "../../LawUtilities.sol";

import { console2 } from "forge-std/console2.sol"; // for debugging purposes -- comment out for production 

contract GrantProposal is Law {
    struct Memory {
        string uriProposal;
        address grantee;
        address token;
        uint256[] milestoneDisbursements;
        uint256 prevActionId;
        bytes32 lawHash;
        bytes prevActionCalldata;
        bytes reconstructedActionCalldata;
    }

    /// @notice Constructor function for Open contract.
    constructor() { 
        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("string uriProposal", "address Grantee", "address Token", "uint256[] milestoneDisbursements", "uint256 PrevActionId");

        // if readStateFrom is not set, we revert. ReadStateFrom should be a law that can flag actions.
        if (conditions.readStateFrom == 0) {
            revert ("ReadStateFrom not set"); 
        }

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    
    }

    // note that we are returning empty arrays as we are not executing any logic.
    // we DO need to return the actionId as it has to be set to 'fulfilled' in the Powers contract.
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
        Memory memory mem; 
        (mem.uriProposal, mem.grantee, mem.token, mem.milestoneDisbursements, mem.prevActionId) = abi.decode(lawCalldata, (string, address, address, uint256[], uint256));
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
    
        // if PrevProposalId is set, we need to check if the proposal has been executed at the readStateFrom law.
        // if not, we revert.
        if (mem.prevActionId != 0) {
            mem.prevActionCalldata = Powers(payable(powers)).getActionCalldata(mem.prevActionId);
            mem.reconstructedActionCalldata = abi.encode(mem.uriProposal, mem.grantee, mem.token, mem.milestoneDisbursements, 0);
            if (keccak256(mem.prevActionCalldata) != keccak256(mem.reconstructedActionCalldata)) {
                revert("Calldata does not match");
            }
            PowersTypes.ActionState prevActionState = Powers(payable(powers)).state(mem.prevActionId);
            if (Powers(payable(powers)).state(mem.prevActionId) != PowersTypes.ActionState.Fulfilled) {
                revert ("PrevActionId is not fulfilled");
            }
        }
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1); // if we send an array of length 0, the actionId will not be set as fulfilled.
        return (actionId, targets, values, calldatas, "");
    }

    // note this law does not need to override handleRequest as it does not execute any logic.
}
