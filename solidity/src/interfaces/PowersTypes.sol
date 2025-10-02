// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and contracts have not been extensively audited.   ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @notice Types used in the Powers protocol.
/// @author 7Cedars
pragma solidity 0.8.26;

interface PowersTypes {
    struct Conditions {
        // Slot 0
        uint256 allowedRole; // 32 bytes
        // Slot 1
        uint16 needCompleted; // 2 bytes - index of law that must be completed before this one
        uint48 delayExecution; // 6 bytes  - Blocks to wait after proposal success before execution
        uint48 throttleExecution; // 6 bytes  - Minimum blocks between executions
        uint32 votingPeriod; // 4 bytes  - Number of blocks for voting period
        uint8 quorum; // 1 byte   - Required participation percentage
        uint8 succeedAt; // 1 byte   - Required success percentage
        uint16 needNotCompleted; // 2 bytes - index of law that must NOT be completed
    }

    struct AdoptedLaw {
        address targetLaw;
        Conditions conditions;
        bool active;
        uint256[] actionIds;
        uint48[] fulfilledAt;
    }

    struct LawInitData {
        string nameDescription; // 32 bytes
        address targetLaw; // 20 bytes
        bytes config; // 32 bytes
        Conditions conditions; // 104 bytes
    }

    /// @notice struct to keep track of a proposal.
    ///
    /// @dev in contrast to other Governance protocols, a proposal in {Powers} always includes a reference to a law.
    /// This enables the role restriction of governance processes in {Powers}.
    ///
    /// @dev in contrast to other Governance protocols, votes are not weighted and can hence be a uint32, not a uint256.
    /// @dev votes are logged at the proposal. In on struct. This is in contrast to other governance protocols where ProposalVote is a separate struct.
    struct Action {
        // slot 1
        uint16 lawId; // 2
        uint48 proposedAt; // 6
        uint48 requestedAt; // 6
        uint48 cancelledAt; // 6
        uint48 fulfilledAt; // 6
        uint48 voteStart; // 6
        // slot 2
        uint32 voteDuration; // 4
        address caller; // 20
        uint32 againstVotes; // 4 as votes are not weighted, uint32 is sufficient to count number of votes.  -- this is a big gas saver. As such, combining the proposalCore and ProposalVote is (I think) okay
        uint32 forVotes; // 4
        // slot 3
        uint32 abstainVotes; // 4
        // ... and more slots.
        mapping(address voter => bool) hasVoted; // 20 ?
        // note: We save lawCalldata ONCHAIN when executed. -- this will be mroe expensive, but it decreases dependence on external services.
        bytes lawCalldata; // 32 ... and more.
        string uri; // 32 bytes ... and more. uri to metadata (description, etc) of action. Markdown file supported by frontend, but in theory can be anything.
        uint256 nonce; // 32 bytes
    }

    /// @notice enum for the state of a proposal.
    ///
    /// @dev that a proposal cannot be set as 'executed' as in Governor.sol. It can only be set as 'completed'.
    /// This is because execution logic in {Powers} is separated from the proposal logic.
    enum ActionState {
        NonExistent,
        Proposed, // - log this
        Cancelled, // - log this
        Active, // - calculate this
        Defeated, // - calculate this
        Succeeded, // - calculate this
        Requested, // - log this
        Fulfilled // - log this

    }

    /// @notice Supported vote types. Matches Governor Bravo ordering.
    enum VoteType {
        Against,
        For,
        Abstain
    }

    /// @notice struct keeping track of a member of a role.
    struct Member {
        address account; // bytes 20
        uint48 since; // bytes 4
    }

    /// @notice struct keeping track of
    /// - an account's access to roleId
    /// - the total amount of members of role (this enables role based voting).
    struct Role {
        mapping(address account => uint256 index) members;
        Member[] membersArray;
        string label;
    }
}
