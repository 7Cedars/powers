// SPDX-License-Identifier: MIT

/// @notice Allows voters to vote on nominees from a standalone OpenElection contract.
///
/// The logic:
/// - The inputParams are dynamic - as many bool options will appear as there are nominees.
/// - When a voter selects more than one nominee, the law will revert.
/// - When a vote is cast, the law calls the vote function in OpenElection contract.
/// - Only one vote per voter is allowed per election.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { OpenElection } from "../../helpers/OpenElection.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract VoteInOpenElection is Law {
    struct MemoryData {
        address caller;
        bytes32 lawHash;
        address[] nominees;
        string[] nomineeList;
        bool[] vote;
        uint256 numVotes;
        uint256 i;
    }

    struct Data {
        address[] nominees;
        address openElectionContract;
        uint256 electionId;
        uint256 maxVotes;
    }

    mapping(bytes32 lawHash => Data) public data;

    /// @notice Constructor for VoteInOpenElection law
    constructor() {
        bytes memory configParams = abi.encode("address OpenElectionContract", "uint256 maxVotes");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        MemoryData memory mem;
        (address openElectionContract, uint256 maxVotes) = abi.decode(config, (address, uint256));

        // Get nominees from the OpenElection contract
        mem.nominees = OpenElection(openElectionContract).getNominees();

        // Save data to state
        mem.lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[mem.lawHash].nominees = mem.nominees;
        data[mem.lawHash].openElectionContract = openElectionContract;
        data[mem.lawHash].electionId = OpenElection(openElectionContract).currentElectionId();
        data[mem.lawHash].maxVotes = maxVotes;

        // Create dynamic inputParams based on nominees
        mem.nomineeList = new string[](mem.nominees.length);
        for (uint256 i = 0; i < mem.nominees.length; i++) {
            mem.nomineeList[i] = string.concat("bool ", Strings.toHexString(mem.nominees[i]));
        }
        inputParams = abi.encode(mem.nomineeList);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build a call to cast a vote in the OpenElection contract
    /// @param caller The voter address
    /// @param powers The Powers contract address (unused here, forwarded in action context)
    /// @param lawId The law identifier
    /// @param lawCalldata Encoded bool[] where each index corresponds to a nominee
    /// @param nonce Unique nonce to build the action id
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        MemoryData memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);

        // Decode the vote data
        (mem.vote) = abi.decode(lawCalldata, (bool[]));
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Check if election is open
        if (!OpenElection(data[mem.lawHash].openElectionContract).isElectionOpen()) {
            revert("Election is not open.");
        }

        // Validate vote length matches nominees length
        if (mem.vote.length != data[mem.lawHash].nominees.length) {
            revert("Invalid vote length.");
        }

        // Check if the voter has voted for more than one nominee
        mem.numVotes = 0;
        for (mem.i = 0; mem.i < mem.vote.length; mem.i++) {
            if (mem.vote[mem.i]) {
                mem.numVotes++;
                if (mem.numVotes > data[mem.lawHash].maxVotes) {
                    revert("Voter tries to vote for more than maxVotes nominees.");
                }
            }
        }

        // create call for
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = data[mem.lawHash].openElectionContract;
        calldatas[0] = abi.encodeWithSelector(OpenElection.vote.selector, caller, mem.vote);

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
