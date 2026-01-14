// SPDX-License-Identifier: MIT

/// @notice End open elections and assign roles based on election results.
///
/// This mandate:
/// - Checks if the election is closed (reverts if still open)
/// - Fetches current role holders from Powers
/// - Retrieves election results from OpenElection contract
/// - Revokes the OpenElectionVote mandate
/// - Revokes roles from all current holders
/// - Assigns roles to newly elected accounts
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Powers } from "../../Powers.sol";
import { OpenElection } from "../../helpers/OpenElection.sol";

contract OpenElectionEnd is Mandate {
    struct Mem {
        uint16 voteContractId;
        uint256 amountRoleHolders;
        address[] currentRoleHolders;
        address[] rankedNominees;
        uint256 numNominees;
        uint256 maxN;
        uint256 numToElect;
        address[] elected;
        uint256 totalOperations;
        uint256 operationIndex;
        uint256 i;
        address electionContract;
        uint256 roleId;
        uint256 maxRoleHolders;
    }

    /// @notice Constructor for OpenElectionEnd mandate
    constructor() {
        bytes memory configParams = abi.encode("address electionContract", "uint256 RoleId", "uint256 MaxRoleHolders");
        emit Mandate__Deployed(configParams);
    }

    /// @notice Execute the mandate by ending the election, revoking the vote mandate, 
    /// revoking current role holders, and assigning newly elected accounts
    /// @param mandateCalldata The calldata (empty for this mandate)
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        (mem.electionContract, mem.roleId, mem.maxRoleHolders) = abi.decode(getConfig(powers, mandateId), (address, uint256, uint256));

        actionId = MandateUtilities.computeActionId(mandateId, mandateCalldata, nonce);

        // Step 1: Check if election is closed - revert if still open
        if (OpenElection(mem.electionContract).isElectionOpen()) {
            revert("Election is still open");
        }

        // Step 2: Read the electionId (which is the ID where the vote mandate was deployed)
        mem.voteContractId = uint16(OpenElection(mem.electionContract).currentElectionId());

        // Step 3: Get amount of current role holders
        mem.amountRoleHolders = Powers(payable(powers)).getAmountRoleHolders(mem.roleId);

        // Get current role holders from Powers
        mem.currentRoleHolders = new address[](mem.amountRoleHolders);
        for (mem.i = 0; mem.i < mem.amountRoleHolders; mem.i++) {
            mem.currentRoleHolders[mem.i] = Powers(payable(powers)).getRoleHolderAtIndex(mem.roleId, mem.i);
        }

        // Step 4: Get nominee ranking and select top candidates
        (mem.rankedNominees,) = OpenElection(mem.electionContract).getNomineeRanking();
        // Select top candidates based on maxRoleHolders
        mem.numNominees = mem.rankedNominees.length;
        mem.maxN = mem.maxRoleHolders;
        mem.numToElect = mem.numNominees <= mem.maxN ? mem.numNominees : mem.maxN;

        mem.elected = new address[](mem.numToElect);
        for (mem.i = 0; mem.i < mem.numToElect; mem.i++) {
            mem.elected[mem.i] = mem.rankedNominees[mem.i];
        }

        // Calculate total number of operations needed:
        // - Revoke the vote mandate (1 operation)
        // - Revoke all current role holders
        // - Assign role to all newly elected accounts
        mem.totalOperations = 1 + mem.amountRoleHolders + mem.elected.length;

        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(mem.totalOperations);

        mem.operationIndex = 0;

        // Step 5: Revoke the OpenElectionVote mandate
        targets[mem.operationIndex] = powers;
        calldatas[mem.operationIndex] = abi.encodeWithSelector(Powers.revokeMandate.selector, mem.voteContractId);
        mem.operationIndex++;

        // Step 6: Revoke roles from all current holders
        for (mem.i = 0; mem.i < mem.currentRoleHolders.length; mem.i++) {
            targets[mem.operationIndex] = powers;
            calldatas[mem.operationIndex] =
                abi.encodeWithSelector(Powers.revokeRole.selector, mem.roleId, mem.currentRoleHolders[mem.i]);
            mem.operationIndex++;
        }

        // Step 7: Assign roles to newly elected accounts
        for (mem.i = 0; mem.i < mem.elected.length; mem.i++) {
            targets[mem.operationIndex] = powers;
            calldatas[mem.operationIndex] = abi.encodeWithSelector(Powers.assignRole.selector, mem.roleId, mem.elected[mem.i]);
            mem.operationIndex++;
        }

        return (actionId, targets, values, calldatas);
    }
}
