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

/// @notice This law revokes roles from all accounts when the number of flagged actions exceeds a threshold.
///
/// The logic:
/// - Counts flagged actions for a specific roleId from FlagActions contract.
/// - If the count exceeds numberOfStrikes, revokes the role from all current holders.
/// - Resets the flagged actions after revocation.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { FlagActions } from "@mocks/FlagActions.sol";

// import "forge-std/console2.sol"; // only for testing purposes. Comment out for production.

contract NStrikesRevokesRoles is Law {
    struct MemoryData {
        bytes32 lawHash;
        uint256[] flaggedActionIds;
        address[] roleHolders;
        uint256 i;
        uint256 j;
        uint256 flaggedCount;
    }

    struct Data {
        uint256 roleId;
        uint256 numberOfStrikes;
        address flagActionsAddress;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        bytes memory configParams = abi.encode("uint256 roleId", "uint256 numberOfStrikes", "address flagActionsAddress");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        MemoryData memory mem;
        (uint256 roleId_, uint256 numberOfStrikes_, address flagActionsAddress_) = abi.decode(config, (uint256, uint256, address));
        
        // Save data to state
        mem.lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[mem.lawHash].roleId = roleId_;
        data[mem.lawHash].numberOfStrikes = numberOfStrikes_;
        data[mem.lawHash].flagActionsAddress = flagActionsAddress_;

        // Set input parameters for the revokeRoles function
        inputParams = abi.encode("No input parameters required");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    function handleRequest(address /* caller */, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        MemoryData memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Get flagged actions for the specific roleId from FlagActions contract
        mem.flaggedActionIds = FlagActions(data[mem.lawHash].flagActionsAddress).getFlaggedActionsByRole(uint16(data[mem.lawHash].roleId));
        
        // Check if we have enough strikes
        if (mem.flaggedActionIds.length < data[mem.lawHash].numberOfStrikes) {
            revert("Not enough strikes to revoke roles.");
        }
        
        // Get all current role holders
        mem.roleHolders = Powers(payable(powers)).getRoleHolders(data[mem.lawHash].roleId);
        
        // Set up calls to revoke roles from all holders
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.roleHolders.length);
        
        for (mem.i = 0; mem.i < mem.roleHolders.length; mem.i++) {
            targets[mem.i] = powers;
            calldatas[mem.i] = abi.encodeWithSelector(Powers.revokeRole.selector, data[mem.lawHash].roleId, mem.roleHolders[mem.i]);
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) external view returns (Data memory) {
        return data[lawHash];
    }

    /// @notice Check if the role should be revoked based on current flagged actions
    /// @param lawHash The law hash to check
    /// @return True if the role should be revoked (enough strikes)
    function shouldRevokeRole(bytes32 lawHash) external view returns (bool) {
        uint256 flaggedCount = FlagActions(data[lawHash].flagActionsAddress).getFlaggedActionsCountByRole(uint16(data[lawHash].roleId));
        return flaggedCount >= data[lawHash].numberOfStrikes;
    }
}
