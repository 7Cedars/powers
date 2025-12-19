// SPDX-License-Identifier: MIT

/// @notice Allows a caller to renounce specific roles they currently hold.
/// @dev The deployer configures which roleIds are allowed to be renounced. The mandate validates
/// the caller holds the role and that it is eligible for renouncement, then emits a revoke call.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { Powers } from "../../Powers.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

contract RenounceRole is Mandate {
    mapping(bytes32 mandateHash => uint256[] allowedRoleIds) public allowedRoleIds; // role that can be renounced.

    /// @notice Constructor for RenounceRole mandate
    constructor() {
        bytes memory configParams = abi.encode("uint256[] allowedRoleIds");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        uint256[] memory allowedRoleIds_ = abi.decode(config, (uint256[]));
        allowedRoleIds[MandateUtilities.hashMandate(msg.sender, index)] = allowedRoleIds_;

        inputParams = abi.encode("uint256 roleId");
        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    function handleRequest(address caller, address powers, uint16 mandateId, bytes memory mandateCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata
        (uint256 roleId) = abi.decode(mandateCalldata, (uint256));
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);

        // step 2: check if the account has the role
        if (Powers(payable(powers)).hasRoleSince(caller, roleId) == 0) {
            revert("Account does not have role.");
        }

        // step 3: check if the role is allowed to be renounced
        bool allowed = false;
        for (uint256 i = 0; i < allowedRoleIds[mandateHash].length; i++) {
            if (roleId == allowedRoleIds[mandateHash][i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            revert("Role not allowed to be renounced.");
        }

        // step 4: create & send return calldata (revoke action)
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, roleId, caller); // selector = revokeRole

        return (actionId, targets, values, calldatas);
    }

    function getAllowedRoleIds(bytes32 mandateHash) public view returns (uint256[] memory) {
        return allowedRoleIds[mandateHash];
    }
}
