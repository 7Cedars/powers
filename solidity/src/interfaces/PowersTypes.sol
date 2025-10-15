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
        uint256 allowedRole; // Takes its own slot
        // --- All of the following can be packed into a single slot (144 bits total) ---
        uint32 votingPeriod;
        uint32 delayExecution;
        uint32 throttleExecution;
        uint16 needFulfilled;
        uint16 needNotFulfilled;
        uint8 quorum;
        uint8 succeedAt;
    }

    struct AdoptedLaw {
        address targetLaw;
        Conditions conditions;
        bool active;
        uint256[] actionIds;
        uint48 latestFulfillment;
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
        // --- Packed Slot 1 (248 bits used) ---
        uint48 proposedAt;
        uint48 requestedAt;
        uint48 fulfilledAt;
        uint48 cancelledAt;
        uint48 voteStart;
        uint16 lawId;
        // --- Packed Slot 2 (128 bits used) ---
        uint32 voteDuration;
        uint32 againstVotes;
        uint32 forVotes;
        uint32 abstainVotes;
        // --- Separate Slots ---
        address caller;
        uint256 nonce;
        // --- Dynamic/Mapping Types (do not take up static slots) ---
        bytes lawCalldata;
        string uri;
        mapping(address => bool) hasVoted;
    }

    /// @notice enum for the state of a proposal.
    ///
    /// @dev that a proposal cannot be set as 'executed' as in Governor.sol. It can only be set as 'completed'.
    /// This is because execution logic in {Powers} is separated from the proposal logic.
    enum ActionState {
        NonExistent, // - 0: log this
        Proposed, // - 1: log this
        Cancelled, // - 2: log this
        Active, // - 3: calculate this -- wait what is difference between this and Proposed? CHECK! 
        Defeated, // - 4: calculate this
        Succeeded, // - 5: calculate this
        Requested, // - 6: log this
        Fulfilled // - 7: log this
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
