// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { Nominees } from "./Nominees.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying.

/// @title OpenElection (standalone)
/// @notice Simple, standalone contract for direct voting on nominees.
/// - Accounts can nominate or revoke themselves as candidates.
/// - Users can vote directly on nominees (one vote per election).
/// - Elections run for a specified number of blocks.
/// - Provides ranking of nominees by vote count.
/// - No Powers/Mandate integration. Pure storage and helper utilities.
contract OpenElection is Nominees {
    struct Data {
        bool isOpen;
        uint256 startBlock;
        uint256 durationBlocks;
        uint256 endBlock;
    }

    Data public currentElection;

    // Voting storage
    mapping(uint256 electionId => mapping(address voter => bool hasVoted)) public hasVoted;
    mapping(uint256 electionId => mapping(address nominee => uint256 voteCount)) public voteCounts;
    mapping(uint256 electionId => address[]) public nomineesByElection;
    uint256 public currentElectionId;

    // Events
    event VoteCast(address indexed voter, address indexed nominee, uint256 electionId);
    event ElectionOpened(uint256 indexed electionId, uint256 startBlock, uint256 endBlock);
    event ElectionClosed(uint256 indexed electionId);
    event ElectionTallied(address[] rankedNominees, uint256[] votes);

    constructor() { }

    // --- Nomination API (override from Nominees) ---

    function nominate(address nominee, bool shouldNominate) public override onlyOwner {
        if (currentElection.isOpen) revert("cannot nominate during active election");
        super.nominate(nominee, shouldNominate);
    }

    // --- Voting API ---

    function vote(address caller, bool[] calldata votes) external onlyOwner {
        if (!currentElection.isOpen) revert("election not open");
        if (block.number > currentElection.endBlock) revert("election closed");
        if (hasVoted[currentElectionId][caller]) revert("already voted");

        address[] memory nomineesForElection = nomineesByElection[currentElectionId];
        if (votes.length != nomineesForElection.length) revert("votes array length mismatch");

        hasVoted[currentElectionId][caller] = true;

        // Cast votes for each nominee where the corresponding boolean is true
        for (uint256 i; i < votes.length; i++) {
            if (votes[i]) {
                address nominee = nomineesForElection[i];
                voteCounts[currentElectionId][nominee] += 1;
                emit VoteCast(caller, nominee, currentElectionId);
            }
        }
    }

    // --- Nominees Management ---
    
    /// Start a new election
    /// @param durationBlocks Number of blocks the election will be open
    /// @param electionId Unique identifier for the election. In this case this should be the ID at which the ElectionVote mandate will be deployed. 
    function openElection(uint256 durationBlocks, uint16 electionId) external onlyOwner {
        if (currentElection.isOpen) revert("election already open");
        if (durationBlocks == 0) revert("duration must be > 0");

        // Reset all votes for new election
        currentElectionId = electionId;

        // Copy current nominees to this election
        nomineesByElection[currentElectionId] = new address[](nomineesSorted.length);
        for (uint256 i; i < nomineesSorted.length; i++) {
            nomineesByElection[currentElectionId][i] = nomineesSorted[i];
        }

        currentElection = Data({
            isOpen: true,
            startBlock: block.number,
            durationBlocks: durationBlocks,
            endBlock: block.number + durationBlocks
        });

        emit ElectionOpened(currentElectionId, currentElection.startBlock, currentElection.endBlock);
    }

    function closeElection() external onlyOwner {
        if (!currentElection.isOpen) revert("election not open");
        if (block.number <= currentElection.endBlock) revert("election still active");

        currentElection.isOpen = false;
        emit ElectionClosed(currentElectionId);
    }

    // --- View helpers ---
    function isElectionOpen() external view returns (bool) {
        return currentElection.isOpen && block.number <= currentElection.endBlock;
    }

    function getElectionInfo() external view returns (Data memory) {
        return currentElection;
    }

    function getNomineesForElection(uint256 electionId) external view returns (address[] memory) {
        return nomineesByElection[electionId];
    }

    function getVoteCount(address nominee, uint256 electionId) external view returns (uint256) {
        return voteCounts[electionId][nominee];
    }

    function hasUserVoted(address voter, uint256 electionId) external view returns (bool) {
        return hasVoted[electionId][voter];
    }

    function getNomineeRanking() public view returns (address[] memory nominees, uint256[] memory votes) {
        if (currentElection.isOpen && block.number <= currentElection.endBlock) {
            revert("election still active");
        }

        (nominees, votes) = getRankingAnyTime(currentElectionId);
    }

    function getRankingAnyTime(uint256 electionId)
        public
        view
        returns (address[] memory nominees, uint256[] memory votes)
    {
        address[] memory nomineesForElection = nomineesByElection[electionId];
        uint256 numNominees = nomineesForElection.length;
        if (numNominees == 0) return (new address[](0), new uint256[](0));

        nominees = new address[](numNominees);
        votes = new uint256[](numNominees);

        // Copy nominees and their votes
        for (uint256 i; i < numNominees; i++) {
            nominees[i] = nomineesForElection[i];
            votes[i] = voteCounts[electionId][nomineesForElection[i]];
        }

        // Simple bubble sort by vote count (descending)
        for (uint256 i; i < numNominees - 1; i++) {
            for (uint256 j; j < numNominees - i - 1; j++) {
                if (votes[j] < votes[j + 1]) {
                    // Swap votes
                    uint256 tempVotes = votes[j];
                    votes[j] = votes[j + 1];
                    votes[j + 1] = tempVotes;

                    // Swap nominees
                    address tempNominee = nominees[j];
                    nominees[j] = nominees[j + 1];
                    nominees[j + 1] = tempNominee;
                }
            }
        }

        return (nominees, votes);
    }
}
