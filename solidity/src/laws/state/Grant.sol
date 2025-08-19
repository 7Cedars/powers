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

/// @notice This contract manages a disbursement of grant funds. 

/// Logic: 
/// - The grant should be adopted by those in control of the grant program. 
///     - the grant registers all the data from the proposal at registration time. 
///     - this includes the readStateFrom value, to allow decisions to be challenged. 
///     - it allows the person in control of the grant program to release the funds to the grantee, or not. 
/// - input is 
            /// a blockNumber corresponding to one of the blockMilestones in the proposal 
            /// a uri to support for releasing funds / proof of completion.
            /// optional: PrevActionId
/// - The person in control of this law can decide to release the funds to the grantee, or not. 
/// - if a PrevActionId is provided, it will be checked if the previous submission has been passed by judges, overturning a previous decision. 
/// - it needs a StatementOfIntent law to be linked to it with a NeedCompleted check.  
/// - the grantee needs to be the caller of the statement of intent law. 
/// - the grantee can only claim the funds if the proposal has been executed. 
/// 

/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { FlagActions } from "../state/FlagActions.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "forge-std/console2.sol"; // for testing only 

contract Grant is Law {
    struct Disbursement { 
        uint256 amount; 
        bool released;
    }

    struct Memory {
        string uriProposal;
        address grantee;
        address tokenAddress;
        uint256[] milestoneDisbursement;
        uint256 milestone;
        uint256 prevActionId;
        address flagActionsLaw;
        bytes32 lawHash;
        string supportUri;
        uint256 PrevActionId;
        bytes proposalCalldata;
        bytes reconstructedProposalCalldata;
        Disbursement disbursement;
    }

    struct Data {
        address grantee;
        address tokenAddress;
        string uriProposal; 
        bytes proposalCalldata;
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(uint256 milestone => Disbursement)) internal disbursements;

    // NB: because the configParams are the exact same as the proposal, we can use a simple BespokeAction to deploy the law. 
    constructor() {
        bytes memory configParams = abi.encode("string uriProposal", "address Grantee", "address Token", "uint256[] milestoneDisbursement", "uint256 prevActionId");
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration parameters
    /// @param index The index of the law in the DAO
    /// @param conditions The conditions for the law
    /// @param config The configuration parameters (proposals)
    /// @param nameDescription The description of the law
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        Memory memory mem;
        (mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursement, mem.prevActionId) = abi.decode(config, (string, address, address, uint256[], uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({
            grantee: mem.grantee,
            tokenAddress: mem.tokenAddress,
            uriProposal: mem.uriProposal,
            proposalCalldata: config
        });
        for (uint256 i = 0; i < mem.milestoneDisbursement.length; i++) {
            disbursements[lawHash][i] = Disbursement({
                amount: mem.milestoneDisbursement[i],
                released: false
            });
        }
        
        inputParams = abi.encode("uint256 MilestoneBlock", "string SupportUri");
        
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    /// @notice Handles the request to transfer grant funds
    /// @param caller The address of the caller
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing grant details
    /// @param nonce The nonce for the action
    /// @return actionId The ID of the action
    /// @return targets The target addresses for the action
    /// @return values The values for the action
    /// @return calldatas The calldatas for the action
    /// @return stateChange The state change data
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
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
        // step 0: create actionId & decode law calldata
        Memory memory mem;
        (mem.milestone, mem.supportUri) = abi.decode(lawCalldata, (uint256, string));
        (, mem.lawHash,) = Powers(payable(powers)).getActiveLaw(lawId);
        // note: optional flagging of actions. 
        if (laws[mem.lawHash].conditions.readStateFrom != 0) {
            (mem.flagActionsLaw, , ) = Powers(payable(powers)).getActiveLaw(laws[mem.lawHash].conditions.readStateFrom);
        }
        
        Data memory lawData = data[mem.lawHash];

        // step 1: run additional checks
        if (disbursements[mem.lawHash][mem.milestone].amount == 0) {
            revert ("Milestone amount is 0");
        }
        if (disbursements[mem.lawHash][mem.milestone].released) {
            revert ("Milestone already released");
        }
        if (mem.milestone > 0 && !disbursements[mem.lawHash][mem.milestone - 1].released) {
            revert ("Previous milestone not released yet");
        }
        if (data[mem.lawHash].grantee != caller) {
            revert ("Caller is not the grantee");
        }

        // step 2: create arrays
        // NOTE: normally pushing tokens to an account is not what you want to do. Pulling is better. 
        // but because the grantee address has been extensively vetted, it is safe to do so. I think. 
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = data[mem.lawHash].tokenAddress;
        calldatas[0] = abi.encodeWithSelector(
            ERC20.transfer.selector, 
            data[mem.lawHash].grantee,  // transfer to the grantee
            disbursements[mem.lawHash][mem.milestone].amount // transfer the amount at the milestone
        );
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);    
        stateChange = abi.encode(mem.milestone);

        // step 3: return data  
        return (actionId, targets, values, calldatas, stateChange);
    }

    /// @notice Changes the state of the law
    /// @param lawHash The hash of the law
    /// @param stateChange The state change data
    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        Memory memory mem;
        (mem.milestone) = abi.decode(stateChange, (uint256));
        disbursements[lawHash][mem.milestone].released = true;
    }

    function getDisbursement(bytes32 lawHash, uint256 milestone) external view returns (Disbursement memory) {
        return disbursements[lawHash][milestone];
    }

    function getGrantee(bytes32 lawHash) external view returns (address) {
        return data[lawHash].grantee;
    }

    function getData(bytes32 lawHash) external view returns (Data memory) {
        return data[lawHash];
    }
}
