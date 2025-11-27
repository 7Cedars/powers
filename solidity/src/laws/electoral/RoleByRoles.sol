// SPDX-License-Identifier: MIT

/// @notice Assign or revoke a role based on whether an account holds any of a set of prerequisite roles.
/// @dev Useful for composing "grouped" roles (e.g., anyone with a specific contributor role can be granted a generic contributor role).
/// Also revokes the target role if the account no longer holds any prerequisite roles.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract RoleByRoles is Law {
    struct Data {
        uint256 newRoleId;
        uint256[] roleIdsNeeded;
    }

    mapping(bytes32 lawHash => Data data) public data;

    /// @notice Constructor for RoleByRoles law
    constructor() {
        bytes memory configParams = abi.encode("uint256 newRoleId", "uint256[] roleIdsNeeded");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (uint256 newRoleId_, uint256[] memory roleIdsNeeded_) = abi.decode(config, (uint256, uint256[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({ newRoleId: newRoleId_, roleIdsNeeded: roleIdsNeeded_ });

        inputParams = abi.encode("address Account");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    function handleRequest(address, /* caller */ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata & create hashes
        (address account) = abi.decode(lawCalldata, (address));
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 2: check if the account has any of the needed roles, and if it already has the new role
        Data memory data_ = data[lawHash];
        bool hasAnyOfNeededRoles = false;
        for (uint256 i = 0; i < data_.roleIdsNeeded.length; i++) {
            if (Powers(payable(powers)).hasRoleSince(account, data_.roleIdsNeeded[i]) > 0) {
                hasAnyOfNeededRoles = true;
                break;
            }
        }
        bool alreadyHasNewRole = Powers(payable(powers)).hasRoleSince(account, data_.newRoleId) > 0;

        // step 3: create empty arrays
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        // step 4: set the targets, values and calldatas according to the outcomes at step 2
        if (hasAnyOfNeededRoles && !alreadyHasNewRole) {
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data_.newRoleId, account);
        }
        if (!hasAnyOfNeededRoles && alreadyHasNewRole) {
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, data_.newRoleId, account);
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
