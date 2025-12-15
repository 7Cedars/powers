// SPDX-License-Identifier: MIT

/// @notice Revoke roles from all accounts when the number of flagged actions exceeds a threshold.
///
/// The logic:
/// - Counts flagged actions for a specific roleId from FlagActions contract.
/// - If the count exceeds numberOfStrikes, revokes the role from all current holders.
/// - Resets the flagged actions after revocation.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { Powers } from "../../Powers.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { FlagActions } from "../../helpers/FlagActions.sol";

// import "forge-std/console2.sol"; // only for testing purposes. Comment out for production.

contract NStrikesRevokesRoles is Mandate {
    struct MemoryData {
        bytes32 mandateHash;
        uint256[] flaggedActionIds;
        address[] roleHolders;
        uint256 i;
        uint256 j;
        uint256 flaggedCount;
        uint256 amountRoleHolders;
    }

    struct Data {
        uint256 roleId;
        uint256 numberOfStrikes;
        address flagActionsAddress;
    }

    mapping(bytes32 mandateHash => Data) public data;

    /// @notice Constructor for NStrikesRevokesRoles mandate
    constructor() {
        bytes memory configParams =
            abi.encode("uint256 roleId", "uint256 numberOfStrikes", "address flagActionsAddress");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        MemoryData memory mem;
        (uint256 roleId_, uint256 numberOfStrikes_, address flagActionsAddress_) =
            abi.decode(config, (uint256, uint256, address));

        // Save data to state
        mem.mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        data[mem.mandateHash].roleId = roleId_;
        data[mem.mandateHash].numberOfStrikes = numberOfStrikes_;
        data[mem.mandateHash].flagActionsAddress = flagActionsAddress_;

        // Set input parameters for the revokeRoles function
        inputParams = abi.encode("No input parameters required");
        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to revoke roles from all holders if strike threshold met
    /// @param powers The Powers contract address
    /// @param mandateId The mandate identifier
    /// @param mandateCalldata Not used for this mandate
    /// @param nonce Unique nonce to build the action id
    function handleRequest(
        address,
        /* caller */
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        MemoryData memory mem;
        mem.mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Get flagged actions for the specific roleId from FlagActions contract
        mem.flaggedActionIds =
            FlagActions(data[mem.mandateHash].flagActionsAddress).getFlaggedActionsByRole(uint16(data[mem.mandateHash].roleId));

        // Check if we have enough strikes
        if (mem.flaggedActionIds.length < data[mem.mandateHash].numberOfStrikes) {
            revert("Not enough strikes to revoke roles.");
        }

        // Get all current role holders
        mem.amountRoleHolders = Powers(payable(powers)).getAmountRoleHolders(data[mem.mandateHash].roleId);
        mem.roleHolders = new address[](mem.amountRoleHolders);
        for (uint256 i = 0; i < mem.amountRoleHolders; i++) {
            mem.roleHolders[i] = Powers(payable(powers)).getRoleHolderAtIndex(data[mem.mandateHash].roleId, i);
        }

        // Set up calls to revoke roles from all holders
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(mem.amountRoleHolders);

        for (mem.i = 0; mem.i < mem.amountRoleHolders; mem.i++) {
            targets[mem.i] = powers;
            calldatas[mem.i] =
                abi.encodeWithSelector(Powers.revokeRole.selector, data[mem.mandateHash].roleId, mem.roleHolders[mem.i]);
            mem.i++;
        }
        mem.i = 0;

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a mandate instance
    function getData(bytes32 mandateHash) external view returns (Data memory) {
        return data[mandateHash];
    }

    /// @notice Check if the role should be revoked based on current flagged actions
    /// @param mandateHash The mandate hash to check
    /// @return shouldRevoke True if the role should be revoked (enough strikes)
    function shouldRevokeRole(bytes32 mandateHash) external view returns (bool shouldRevoke) {
        uint256 flaggedCount =
            FlagActions(data[mandateHash].flagActionsAddress).getFlaggedActionsCountByRole(uint16(data[mandateHash].roleId));
        return flaggedCount >= data[mandateHash].numberOfStrikes;
    }
}
