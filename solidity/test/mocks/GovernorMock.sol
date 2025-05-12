// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract GovernorMock is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    constructor()
        Governor("MyGovernor")
        GovernorSettings(7200 /* 1 day */, 50400 /* 1 week */, 0)
        GovernorVotes(IVotes(0x868a458887F98729F154532512F5bE4CB26c6B88)) // Erc20votesMock
        GovernorVotesQuorumFraction(4)
    {}

    // The following functions are overrides required by Solidity.

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}