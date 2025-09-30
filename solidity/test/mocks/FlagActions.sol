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

/// @title FlagActions (standalone)
/// @notice Helper to flag/unflag actionIds with tracking by roleId, account, and lawId
/// @dev Standalone pattern with immutable powers address and onlyPowers modifier
/// @author 7Cedars

pragma solidity 0.8.26;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FlagActions is Ownable {
    // Storage
    mapping(uint256 actionId => bool isFlagged) public flaggedActions;
    
    // Additional tracking mappings
    mapping(uint16 roleId => uint256[]) public flaggedActionsByRole;
    mapping(address account => uint256[]) public flaggedActionsByAccount;
    mapping(uint16 lawId => uint256[]) public flaggedActionsByLaw;
    
    // Global list of all flagged actions
    uint256[] public allFlaggedActions;
    
    // Metadata storage for efficient removal
    struct ActionMetadata {
        uint16 roleId;
        address account;
        uint16 lawId;
        uint256 allFlaggedIndex;      // Index in allFlaggedActions array
        uint256 roleIndex;            // Index in flaggedActionsByRole array
        uint256 accountIndex;         // Index in flaggedActionsByAccount array
        uint256 lawIndex;             // Index in flaggedActionsByLaw array
        bool exists;
    }
    
    mapping(uint256 actionId => ActionMetadata) public actionMetadata;
    
    // Events
    event FlagActions__Flagged(uint256 actionId, uint16 roleId, address account, uint16 lawId);
    event FlagActions__Unflagged(uint256 actionId, uint16 roleId, address account, uint16 lawId);

    constructor() Ownable(msg.sender) { }

    /// @notice Flags an action id with associated metadata. Reverts if already flagged
    /// @param actionId The action ID to flag
    /// @param roleId The role ID associated with the action
    /// @param account The account associated with the action
    /// @param lawId The law ID associated with the action
    function flag(uint256 actionId, uint16 roleId, address account, uint16 lawId) external onlyOwner {
        if (flaggedActions[actionId]) revert("Already true");
        
        flaggedActions[actionId] = true;
        
        // Add to tracking lists and store indices
        uint256 allFlaggedIndex = allFlaggedActions.length;
        uint256 roleIndex = flaggedActionsByRole[roleId].length;
        uint256 accountIndex = flaggedActionsByAccount[account].length;
        uint256 lawIndex = flaggedActionsByLaw[lawId].length;
        
        // Store metadata with indices for efficient removal
        actionMetadata[actionId] = ActionMetadata({
            roleId: roleId,
            account: account,
            lawId: lawId,
            allFlaggedIndex: allFlaggedIndex,
            roleIndex: roleIndex,
            accountIndex: accountIndex,
            lawIndex: lawIndex,
            exists: true
        });
        
        // Add to tracking lists
        flaggedActionsByRole[roleId].push(actionId);
        flaggedActionsByAccount[account].push(actionId);
        flaggedActionsByLaw[lawId].push(actionId);
        allFlaggedActions.push(actionId);
        
        emit FlagActions__Flagged(actionId, roleId, account, lawId);
    }

    /// @notice Unflags an action id. Reverts if not flagged
    /// @param actionId The action ID to unflag
    function unflag(uint256 actionId) external onlyOwner {
        if (!flaggedActions[actionId]) revert("Already false");
        
        // Get metadata for efficient removal
        ActionMetadata memory metadata = actionMetadata[actionId];
        if (!metadata.exists) revert("Metadata not found");
        
        flaggedActions[actionId] = false;
        
        // Remove from all tracking arrays using stored indices (O(1) operation)
        _removeFromArrayByIndex(allFlaggedActions, metadata.allFlaggedIndex);
        _removeFromArrayByIndex(flaggedActionsByRole[metadata.roleId], metadata.roleIndex);
        _removeFromArrayByIndex(flaggedActionsByAccount[metadata.account], metadata.accountIndex);
        _removeFromArrayByIndex(flaggedActionsByLaw[metadata.lawId], metadata.lawIndex);
        
        // Update indices of elements that were swapped
        _updateIndicesAfterRemoval(metadata);
        
        // Clear metadata
        delete actionMetadata[actionId];
        
        emit FlagActions__Unflagged(actionId, metadata.roleId, metadata.account, metadata.lawId);
    }

    /// @notice Internal function to remove an element from an array by index using swap-and-pop
    /// @param array The array to remove from
    /// @param index The index of the element to remove
    function _removeFromArrayByIndex(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "Index out of bounds");
        
        // If removing the last element, just pop
        if (index == array.length - 1) {
            array.pop();
            return;
        }
        
        // Swap with last element and pop
        uint256 lastElement = array[array.length - 1];
        array[index] = lastElement;
        array.pop();
        
        // Return the swapped element so we can update its metadata
        // This will be handled by the caller
    }

    /// @notice Internal function to update indices after removal
    /// @param removedMetadata The metadata of the removed action
    function _updateIndicesAfterRemoval(ActionMetadata memory removedMetadata) internal {
        // Find the action that was swapped to the removed position
        // and update its metadata indices
        
        // Check allFlaggedActions
        if (removedMetadata.allFlaggedIndex < allFlaggedActions.length) {
            uint256 swappedActionId = allFlaggedActions[removedMetadata.allFlaggedIndex];
            if (actionMetadata[swappedActionId].exists) {
                actionMetadata[swappedActionId].allFlaggedIndex = removedMetadata.allFlaggedIndex;
            }
        }
        
        // Check role array
        if (removedMetadata.roleIndex < flaggedActionsByRole[removedMetadata.roleId].length) {
            uint256 swappedActionId = flaggedActionsByRole[removedMetadata.roleId][removedMetadata.roleIndex];
            if (actionMetadata[swappedActionId].exists) {
                actionMetadata[swappedActionId].roleIndex = removedMetadata.roleIndex;
            }
        }
        
        // Check account array
        if (removedMetadata.accountIndex < flaggedActionsByAccount[removedMetadata.account].length) {
            uint256 swappedActionId = flaggedActionsByAccount[removedMetadata.account][removedMetadata.accountIndex];
            if (actionMetadata[swappedActionId].exists) {
                actionMetadata[swappedActionId].accountIndex = removedMetadata.accountIndex;
            }
        }
        
        // Check law array
        if (removedMetadata.lawIndex < flaggedActionsByLaw[removedMetadata.lawId].length) {
            uint256 swappedActionId = flaggedActionsByLaw[removedMetadata.lawId][removedMetadata.lawIndex];
            if (actionMetadata[swappedActionId].exists) {
                actionMetadata[swappedActionId].lawIndex = removedMetadata.lawIndex;
            }
        }
    }

    /// @notice View helper to check if an action is flagged
    function isActionIdFlagged(uint256 actionId) external view returns (bool) {
        return flaggedActions[actionId];
    }

    /// @notice Get all flagged actions for a specific role ID
    /// @param roleId The role ID to query
    /// @return Array of flagged action IDs for the role
    function getFlaggedActionsByRole(uint16 roleId) external view returns (uint256[] memory) {
        return flaggedActionsByRole[roleId];
    }

    /// @notice Get all flagged actions for a specific account
    /// @param account The account to query
    /// @return Array of flagged action IDs for the account
    function getFlaggedActionsByAccount(address account) external view returns (uint256[] memory) {
        return flaggedActionsByAccount[account];
    }

    /// @notice Get all flagged actions for a specific law ID
    /// @param lawId The law ID to query
    /// @return Array of flagged action IDs for the law
    function getFlaggedActionsByLaw(uint16 lawId) external view returns (uint256[] memory) {
        return flaggedActionsByLaw[lawId];
    }

    /// @notice Get all currently flagged actions
    /// @return Array of all flagged action IDs
    function getAllFlaggedActions() external view returns (uint256[] memory) {
        return allFlaggedActions;
    }

    /// @notice Get count of flagged actions for a specific role ID
    /// @param roleId The role ID to query
    /// @return Count of flagged actions for the role
    function getFlaggedActionsCountByRole(uint16 roleId) external view returns (uint256) {
        return flaggedActionsByRole[roleId].length;
    }

    /// @notice Get count of flagged actions for a specific account
    /// @param account The account to query
    /// @return Count of flagged actions for the account
    function getFlaggedActionsCountByAccount(address account) external view returns (uint256) {
        return flaggedActionsByAccount[account].length;
    }

    /// @notice Get count of flagged actions for a specific law ID
    /// @param lawId The law ID to query
    /// @return Count of flagged actions for the law
    function getFlaggedActionsCountByLaw(uint16 lawId) external view returns (uint256) {
        return flaggedActionsByLaw[lawId].length;
    }

    /// @notice Get total count of all flagged actions
    /// @return Total count of flagged actions
    function getTotalFlaggedActionsCount() external view returns (uint256) {
        return allFlaggedActions.length;
    }

    /// @notice Check if a specific action is flagged for a role
    /// @param actionId The action ID to check
    /// @param roleId The role ID to check
    /// @return True if the action is flagged for the role
    function isActionFlaggedForRole(uint256 actionId, uint16 roleId) external view returns (bool) {
        uint256[] memory roleActions = flaggedActionsByRole[roleId];
        for (uint256 i = 0; i < roleActions.length; i++) {
            if (roleActions[i] == actionId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a specific action is flagged for an account
    /// @param actionId The action ID to check
    /// @param account The account to check
    /// @return True if the action is flagged for the account
    function isActionFlaggedForAccount(uint256 actionId, address account) external view returns (bool) {
        uint256[] memory accountActions = flaggedActionsByAccount[account];
        for (uint256 i = 0; i < accountActions.length; i++) {
            if (accountActions[i] == actionId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a specific action is flagged for a law
    /// @param actionId The action ID to check
    /// @param lawId The law ID to check
    /// @return True if the action is flagged for the law
    function isActionFlaggedForLaw(uint256 actionId, uint16 lawId) external view returns (bool) {
        uint256[] memory lawActions = flaggedActionsByLaw[lawId];
        for (uint256 i = 0; i < lawActions.length; i++) {
            if (lawActions[i] == actionId) {
                return true;
            }
        }
        return false;
    }
}
