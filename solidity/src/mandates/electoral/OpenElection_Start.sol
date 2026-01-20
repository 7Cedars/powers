// SPDX-License-Identifier: MIT

/// @notice Starts an election by calling openElection on the OpenElection contract
/// and deploys an OpenElection_Vote contract for voting.
///
/// This mandate:
/// - Takes electionContract address, roleId, and maxRoleHolders at initialization
/// - Deploys an OpenElection_Vote contract during initialization
/// - Calls openElection on the OpenElection contract when executed
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { OpenElection } from "../../helpers/OpenElection.sol";
import { OpenElection_Vote } from "./OpenElection_Vote.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract OpenElection_Start is Mandate { 
    struct Mem { 
        address electionContract;
        uint256 blockTime;
        uint256 voterRoleId;
        address voteContractAddress;
        uint16 voteContractId;
    }

    mapping (bytes32 mandateHash => uint16 voteContractId) internal voteContractIds;

    /// @notice Constructor for OpenElection_Start mandate
    constructor() {
        bytes memory configParams = abi.encode("address electionContract", "address voteContract", "uint256 blockTime", "uint256 voterRoleId");
        emit Mandate__Deployed(configParams);
    }

    /// @notice Handles the request to start an election and adopt the vote mandate
    /// @dev Calls openElection on the OpenElection contract and adopts the OpenElection_Vote mandate
    // / @param caller The address calling the mandate
    /// @param powers The Powers contract address
    /// @param mandateId The mandate identifier
    /// @param mandateCalldata The calldata for the mandate (empty for this mandate)
    /// @param nonce Unique nonce to build the action id
    function handleRequest(
        address /*caller*/,
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
        actionId = MandateUtilities.computeActionId(mandateId, mandateCalldata, nonce);
        (mem.electionContract, mem.voteContractAddress, mem.blockTime, mem.voterRoleId) = abi.decode(getConfig(powers, mandateId), (address, address, uint256, uint256)); // validate config
        mem.voteContractId = Powers(powers).mandateCounter(); // the ID at which the vote mandate will be adopted 

        // Create two calls: 1) openElection, 2) adoptMandate
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(2);

        // Call 1: Open the election
        targets[0] = mem.electionContract;
        // Note that we set the electionId to the voteContractId for tracking. 
        calldatas[0] = abi.encodeWithSelector(OpenElection.openElection.selector, mem.blockTime, mem.voteContractId);

        // Call 2: Adopt the OpenElection_Vote mandate
        targets[1] = powers;
        
        // Prepare config for OpenElection_Vote: (address openElectionContract, uint256 maxVotes)
        bytes memory voteConfig = abi.encode(mem.electionContract, uint256(1));
        
        // Create MandateInitData for the vote contract
        PowersTypes.MandateInitData memory voteInitData = PowersTypes.MandateInitData({
            nameDescription: "Vote in Open Election",
            targetMandate: mem.voteContractAddress,
            config: voteConfig,
            conditions: PowersTypes.Conditions({
                allowedRole: mem.voterRoleId, // Voters can vote
                votingPeriod: 0, // No voting period needed for direct execution
                timelock: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0,
                quorum: 0, // No quorum, direct execution
                succeedAt: 0
            })
        });
        
        calldatas[1] = abi.encodeWithSelector(IPowers.adoptMandate.selector, voteInitData);

        return (actionId, targets, values, calldatas);
    } 
}
