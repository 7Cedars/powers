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
    struct MemoryData {
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
    }

    struct Data {
        address powersContract;
        address electionContract;
        uint256 roleId;
        uint256 maxRoleHolders;
    }

    mapping(bytes32 mandateHash => Data data) internal _data;

    /// @notice Constructor for OpenElectionEnd mandate
    constructor() {
        bytes memory configParams = abi.encode("address electionContract", "uint256 RoleId", "uint256 MaxRoleHolders");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address electionContract_, uint256 roleId_, uint256 maxRoleHolders_) =
            abi.decode(config, (address, uint256, uint256));

        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        _data[mandateHash] = Data({
            powersContract: msg.sender,
            electionContract: electionContract_,
            roleId: roleId_,
            maxRoleHolders: maxRoleHolders_
        });

        // No input parameters needed for this mandate
        inputParams = abi.encode();

        super.initializeMandate(index, nameDescription, inputParams, config);
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
        MemoryData memory mem;
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        Data memory data = _data[mandateHash];

        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Step 1: Check if election is closed - revert if still open
        if (OpenElection(data.electionContract).isElectionOpen()) {
            revert("Election is still open");
        }

        // Step 2: Read the electionId (which is the ID where the vote mandate was deployed)
        mem.voteContractId = uint16(OpenElection(data.electionContract).currentElectionId());

        // Step 3: Get amount of current role holders
        mem.amountRoleHolders = Powers(payable(data.powersContract)).getAmountRoleHolders(data.roleId);

        // Get current role holders from Powers
        mem.currentRoleHolders = new address[](mem.amountRoleHolders);
        for (mem.i = 0; mem.i < mem.amountRoleHolders; mem.i++) {
            mem.currentRoleHolders[mem.i] = Powers(payable(data.powersContract)).getRoleHolderAtIndex(data.roleId, mem.i);
        }

        // Step 4: Get nominee ranking and select top candidates
        (mem.rankedNominees,) = OpenElection(data.electionContract).getNomineeRanking();

        // Select top candidates based on maxRoleHolders
        mem.numNominees = mem.rankedNominees.length;
        mem.maxN = data.maxRoleHolders;
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
        targets[mem.operationIndex] = data.powersContract;
        calldatas[mem.operationIndex] = abi.encodeWithSelector(Powers.revokeMandate.selector, mem.voteContractId);
        mem.operationIndex++;

        // Step 6: Revoke roles from all current holders
        for (mem.i = 0; mem.i < mem.currentRoleHolders.length; mem.i++) {
            targets[mem.operationIndex] = data.powersContract;
            calldatas[mem.operationIndex] =
                abi.encodeWithSelector(Powers.revokeRole.selector, data.roleId, mem.currentRoleHolders[mem.i]);
            mem.operationIndex++;
        }

        // Step 7: Assign roles to newly elected accounts
        for (mem.i = 0; mem.i < mem.elected.length; mem.i++) {
            targets[mem.operationIndex] = data.powersContract;
            calldatas[mem.operationIndex] = abi.encodeWithSelector(Powers.assignRole.selector, data.roleId, mem.elected[mem.i]);
            mem.operationIndex++;
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a mandate
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return _data[mandateHash];
    }
}
