// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// Base contracts
import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

import { ClaimRoleWithGitSig } from "./ClaimRoleWithGitSig.sol";

/**
 * @title AssignRoleWithGitSig
 * @notice to do
 *
 */

contract AssignRoleWithGitSig is Law {
    // --- Mem struct for handleRequest ---
    // (This is just to avoid "stack too deep" errors)

    struct Mem {
        bytes32 lawHash;
        bytes32 lawHashClaimRole;
        address addressClaimRole;
        bool active;
        bytes errorMessage;
        uint256 roleId;
    }

    // --- Constructor ---
    constructor() {
        // Define the parameters required to configure this law
        bytes memory configParams = abi.encode();
        emit Law__Deployed(configParams);
    }

    // --- Law Initialization ---
    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        // Set input parameters for UI: same as ClaimRoleWithGitSig.
        inputParams = abi.encode("uint256 roleId", "string commitHash");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    // --- Law Execution (Request) ---
    function handleRequest(
        address caller, // The user requesting the role
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;

        (mem.roleId,) = abi.decode(lawCalldata, (uint256, string));

        // Hash the action
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        PowersTypes.Conditions memory conditions = Powers(payable(powers)).getConditions(lawId);
        if (conditions.needFulfilled == 0) {
            revert("Need fulfilled condition not set");
        }
        // step 2: retrieve address of ClaimRoleByGitCommit
        (mem.addressClaimRole, mem.lawHashClaimRole, mem.active) =
            Powers(payable(powers)).getAdoptedLaw(conditions.needFulfilled);
        if (!mem.active) {
            revert("Claim role law not active");
        }

        // step 3: retrieve data from chainlink reply - and reset data in the process.
        (mem.errorMessage, mem.roleId) =
            ClaimRoleWithGitSig(mem.addressClaimRole).getLatestReply(mem.lawHashClaimRole, caller);
        if (mem.errorMessage.length > 0) {
            revert("error in claiming role.");
        }

        // Note: we reset the reply so it cannot be used twice. Then we assign the role.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);
        targets[0] = mem.addressClaimRole;
        targets[1] = powers;
        calldatas[0] = abi.encodeWithSelector(ClaimRoleWithGitSig.resetReply.selector, powers, lawId, caller);
        calldatas[1] = abi.encodeWithSelector(Powers.assignRole.selector, mem.roleId, caller);

        return (actionId, targets, values, calldatas);
    }
}
