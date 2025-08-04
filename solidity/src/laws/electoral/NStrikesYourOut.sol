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

/// @notice This contract allows an account to be stripped of all its roles in an organisation after it is linked to N flagged actionIDs.
/// The action of revoking is not logged and can be reused indefinetely. So it equals banishment from the organisation. 

/// logic: 
/// readStateFrom has to be a FlagAction.sol law. 
/// Input: 
/// - account (address)
/// - actionIds (uint256[])
/// 
/// - if the actionIds are indeed 1) from the readStateFrom law, 2) have been flagged, 3) have been passed and 4) the account has the role -> then the role is revoked. 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { FlagActions } from "../state/FlagActions.sol";

// import "forge-std/console2.sol"; // only for testing purposes. Comment out for production. 

contract NStrikesYourOut is Law {
    struct Memory {
        address account;
        uint256 roleId;
        uint256[] actionIds;
        bytes32 lawHash;
        address flagActionsLaw;
        uint16 lawId;
        address caller;
        uint256 revokeCounter;
    }

    struct Data {
        uint256[] roleIds;
        uint256 numberStrikes;
    }
    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        bytes memory configParams = abi.encode("uint256 NumberStrikes", "uint256[] RoleIds");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (uint256 numberStrikes, uint256[] memory roleIds) = abi.decode(config, (uint256, uint256[]));
        data[LawUtilities.hashLaw(msg.sender, index)] = Data({
            roleIds: roleIds,
            numberStrikes: numberStrikes
        });

        inputParams = abi.encode("address Account", "uint256[] ActionIds");
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
        Memory memory mem;
        uint256[] memory actionIds;
        (mem.account, actionIds) = abi.decode(lawCalldata, (address, uint256[]));
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        (mem.flagActionsLaw, , ) = Powers(payable(powers)).getActiveLaw(laws[mem.lawHash].conditions.readStateFrom);
        // check: are actions fulfilled, are they from the readStateFrom law, was the caller the account? 
        for (uint256 i = 0; i < actionIds.length; i++) {
            (, , , mem.lawId, , , , mem.caller, , , , ) = Powers(payable(powers)).getActionData(actionIds[i]);
            if (mem.caller != mem.account) {
                revert("Action is not from account being revoked.");
            }
            if (!FlagActions(mem.flagActionsLaw).isActionIdFlagged(actionIds[i])) {
                revert("Action is not flagged.");
            }
        }
        if (actionIds.length < data[mem.lawHash].numberStrikes) {
            revert("Not enough strikes to revoke role.");
        }
        // we create a slot for every roleId stored in the law, but only send the calldata for the ones that the account has. 
        mem.revokeCounter = data[mem.lawHash].roleIds.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.revokeCounter);
        for (uint256 i = 0; i < mem.revokeCounter; i++) {
            targets[i] = powers;
            if (Powers(payable(powers)).hasRoleSince(mem.account, data[mem.lawHash].roleIds[i]) != 0) {
                calldatas[i] = abi.encodeWithSelector(Powers.revokeRole.selector, data[mem.lawHash].roleIds[i], mem.account);
            }
        }
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, "");
    }

    function getData(bytes32 lawHash) external view returns (Data memory) {
        return data[lawHash];
    }
}
