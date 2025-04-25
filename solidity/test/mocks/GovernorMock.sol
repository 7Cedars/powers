// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { GovernorSettings } from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import { GovernorCountingSimple } from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";

contract GovernorMock is Governor, GovernorSettings, GovernorCountingSimple {
    error GovernorMock__InvalidProposal();
    error GovernorMock__ProposalAlreadyExecuted();
    error GovernorMock__ProposalNotSuccessful();

    struct Proposal {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    constructor()
        Governor("GovernorMock")

        GovernorSettings(
            30, // voting delay
            60, // voting period
            0 // quorum
        )
    {}

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override
        returns (uint256)
    {
        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        if (proposals[proposalId].targets.length > 0) revert GovernorMock__InvalidProposal();
        
        proposals[proposalId] = Proposal(targets, values, calldatas, false);
        proposalCount++;
        return proposalId;
    }

    function execute(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        public
        payable
        override
        returns (uint256)
    {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) revert GovernorMock__ProposalAlreadyExecuted();
        if (state(proposalId) != ProposalState.Succeeded) revert GovernorMock__ProposalNotSuccessful();

        proposal.executed = true;
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            require(success, "GovernorMock: execution failed");
        }
        return proposalId;
    }

    function state(uint256 proposalId) public view override returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.targets.length == 0) return ProposalState.Pending;
        if (proposal.executed) return ProposalState.Executed;
        
        uint256 snapshot = proposalSnapshot(proposalId);
        if (block.number < snapshot) return ProposalState.Pending;
        
        uint256 deadline = proposalDeadline(proposalId);
        if (block.number <= deadline) return ProposalState.Active;
        
        return (_quorumReached(proposalId) && _voteSucceeded(proposalId)) ? ProposalState.Succeeded : ProposalState.Defeated;
    }

    // Required overrides
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) { return super.votingDelay(); }
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) { return super.votingPeriod(); }
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) { return super.proposalThreshold(); }

    // Simplified voting functions
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, "");
    }

    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public virtual override returns (uint256) {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, reason);
    }

    function _castVote(uint256 proposalId, address account, uint8 support, string memory reason) internal virtual override returns (uint256) {
        if (state(proposalId) != ProposalState.Active) revert("GovernorMock: vote not currently active");
        _countVote(proposalId, account, support, 1, "");
        emit VoteCast(account, proposalId, support, 1, reason);
        return 1; // Return 1 to indicate success
    }

    // Dummy implementations for required abstract functions
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    function _getVotes(address account, uint256 timepoint, bytes memory params) internal view override returns (uint256) {
        return 1; // Each account gets 1 vote
    }

    function clock() public view override returns (uint48) {
        return uint48(block.number);
    }

    function quorum(uint256 timepoint) public view virtual override returns (uint256) {
        return 1; // Simple quorum of 1 vote
    }
}
