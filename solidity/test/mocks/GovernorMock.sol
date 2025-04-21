// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { GovernorSettings } from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import { GovernorCountingSimple } from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import { GovernorVotes } from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import { GovernorVotesQuorumFraction } from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernorMock is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    error GovernorMock__InvalidProposal();
    error GovernorMock__ProposalAlreadyExecuted();
    error GovernorMock__ProposalNotSuccessful();

    struct Proposal {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    constructor(
        IVotes _token,
        uint48 _votingDelay,
        uint32 _votingPeriod,
        uint256 _quorumNumerator
    )
        Governor("GovernorMock")
        GovernorSettings(_votingDelay, _votingPeriod, 0) // 0 for proposal threshold
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumNumerator)
    {}

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        if (proposals[proposalId].targets.length > 0) {
            revert GovernorMock__InvalidProposal();
        }

        proposals[proposalId] = Proposal({
            targets: targets,
            values: values,
            calldatas: calldatas,
            description: description,
            executed: false
        });

        proposalCount++;

        return proposalId;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) {
            revert GovernorMock__ProposalAlreadyExecuted();
        }

        if (state(proposalId) != ProposalState.Succeeded) {
            revert GovernorMock__ProposalNotSuccessful();
        }

        proposal.executed = true;

        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            require(success, "GovernorMock: execution failed");
        }
    }

    // The following functions are overrides required by Solidity
    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor)
        returns (ProposalState)
    {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.targets.length == 0) {
            return ProposalState.Pending;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        uint256 snapshot = proposalSnapshot(proposalId);
        if (block.number < snapshot) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);
        if (block.number <= deadline) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}
