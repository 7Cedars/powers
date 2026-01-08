// SPDX-License-Identifier: MIT

/// @notice Assign or revoke a role based on whether an account holds any of a set of prerequisite roles.
/// @dev Useful for composing "grouped" roles (e.g., anyone with a specific contributor role can be granted a generic contributor role).
/// Also revokes the target role if the account no longer holds any prerequisite roles.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { Powers } from "../../Powers.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract RoleByRoles is Mandate {
    struct Data {
        uint256 newRoleId;
        uint256[] roleIdsNeeded;
    }

    struct Mem {
        address account; 
        bool hasAnyOfNeededRoles; 
        bool alreadyHasNewRole;
    }

    mapping(bytes32 mandateHash => Data data) public data;

    /// @notice Constructor for RoleByRoles mandate
    constructor() {
        bytes memory configParams = abi.encode("uint256 newRoleId", "uint256[] roleIdsNeeded");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        (
            data[mandateHash].newRoleId, 
            data[mandateHash].roleIdsNeeded
        ) = abi.decode(config, (uint256, uint256[]));

        inputParams = abi.encode("address Account");

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

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
        Mem memory mem;

        // step 1: decode the calldata & create hashes
        (mem.account) = abi.decode(mandateCalldata, (address)); 
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // step 2: check if the account has any of the needed roles, and if it already has the new role
        Data memory data_ = data[MandateUtilities.hashMandate(powers, mandateId)];
        mem.hasAnyOfNeededRoles = false;
        for (uint256 i = 0; i < data_.roleIdsNeeded.length; i++) {
            if (Powers(payable(powers)).hasRoleSince(mem.account, data_.roleIdsNeeded[i]) > 0) {
                mem.hasAnyOfNeededRoles = true;
                break;
            }
        }
        mem.alreadyHasNewRole = Powers(payable(powers)).hasRoleSince(mem.account, data_.newRoleId) > 0;

        // step 3: create empty arrays
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);

        // step 4: set the targets, values and calldatas according to the outcomes at step 2
        if (mem.hasAnyOfNeededRoles && !mem.alreadyHasNewRole) {
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data_.newRoleId, mem.account);
        }
        if (!mem.hasAnyOfNeededRoles && mem.alreadyHasNewRole) {
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, data_.newRoleId, mem.account);
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
