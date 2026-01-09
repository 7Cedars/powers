// SPDX-License-Identifier: MIT

/// @notice Starts an election by calling openElection on the OpenElection contract
/// and deploys an OpenElectionVote contract for voting.
///
/// This mandate:
/// - Takes electionContract address, roleId, and maxRoleHolders at initialization
/// - Deploys an OpenElectionVote contract during initialization
/// - Calls openElection on the OpenElection contract when executed
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { OpenElection } from "../../helpers/OpenElection.sol";
import { OpenElectionVote } from "./OpenElectionVote.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract OpenElectionStart is Mandate {
    struct Data {
        address electionContract; 
        address voteContract;
        uint256 blockTime;
        uint256 voterRoleId;
        uint16 voteContractId;
    }

    mapping(bytes32 mandateHash => Data) public data;

    /// @notice Constructor for OpenElectionStart mandate
    constructor() {
        bytes memory configParams = abi.encode("address electionContract", "uint256 blockTime", "uint256 voterRoleId");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        (
            data[mandateHash].electionContract, 
            data[mandateHash].blockTime, 
            data[mandateHash].voterRoleId
        ) = abi.decode(config, (address, uint256, uint256));
        
        // Deploy OpenElectionVote contract with electionContract and maxVotes as 1 
        OpenElectionVote voteContract = new OpenElectionVote();
        // Note: The vote contract would need to be initialized separately by Powers
        
        data[mandateHash].voteContract = address(voteContract);
        data[mandateHash].voteContractId = 0; // to be set when election is opened. 

        // No input parameters needed
        inputParams = abi.encode();

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Handles the request to start an election and adopt the vote mandate
    /// @dev Calls openElection on the OpenElection contract and adopts the OpenElectionVote mandate
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
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        Data memory mandateData = data[mandateHash];
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);
        uint16 voteContractId = Powers(powers).mandateCounter(); // the ID at which the vote mandate will be adopted

        // Create two calls: 1) openElection, 2) adoptMandate
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(2);

        // Call 1: Open the election
        targets[0] = mandateData.electionContract;
        // Note that we set the electionId to the voteContractId for tracking. 
        calldatas[0] = abi.encodeWithSelector(OpenElection.openElection.selector, mandateData.blockTime, voteContractId);

        // Call 2: Adopt the OpenElectionVote mandate
        targets[1] = powers;
        
        // Prepare config for OpenElectionVote: (address openElectionContract, uint256 maxVotes)
        bytes memory voteConfig = abi.encode(mandateData.electionContract, uint256(1));
        
        // Create MandateInitData for the vote contract
        PowersTypes.MandateInitData memory voteInitData = PowersTypes.MandateInitData({
            nameDescription: "Vote in Open Election",
            targetMandate: mandateData.voteContract,
            config: voteConfig,
            conditions: PowersTypes.Conditions({
                allowedRole: mandateData.voterRoleId, // Voters can vote
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

    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }

    function getVoteContractId(bytes32 mandateHash) public view returns (uint16) {
        return data[mandateHash].voteContractId;
    }
}
