// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @notice Errors used in the Powers protocol.
/// Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars
pragma solidity 0.8.26;

interface PowersErrors {
    /// @notice Emitted when constitute is called more than once.
    error Powers__ConstitutionAlreadyExecuted();

    /// @notice Emitted when a law is already active, when trying to set a new one.
    error Powers__LawAlreadyActive();

    /// @notice Emitted when a PUBLIC or ADMIN role is attempted to be labelled.
    error Powers__LockedRole(); 

    /// @notice Emitted when a law is not active.
    error Powers__NotActiveLaw();

    /// @notice Emitted when a function is called from a contract that is not Powers.
    error Powers__OnlyPowers();

    /// @notice Emitted when a propose is called on a law that does not require a proposal vote. .
    error Powers__NoVoteNeeded();

    /// @notice Emitted when a function is called by an account that lacks the correct roleId.
    error Powers__AccessDenied();

    /// @notice Emmitted when a law does not need a proposal.
    error Powers__LawDoesNotNeedProposalVote();

    /// @notice Emitted when a execution is attempted on a proposal that is not active.
    error Powers__UnexpectedProposalState();

    // @notice Emitted when a law does not pass checks.
    error Powers__LawDidNotPassChecks();

    /// @notice Emitted when a proposal id is invalid.
    error Powers__InvalidProposalId();

    /// @notice Emitted when a proposal is already completed.
    error Powers__ProposalAlreadyCompleted();

    /// @notice Emitted when a proposal is has been cancelled.
    error Powers__ProposalCancelled();

    /// @notice Emitted when cancelling a proposal that does not reference an active law.
    error Powers__CancelCallNotFromActiveLaw();

    /// @notice Emitted when a proposal is not active.
    error Powers__ProposalNotActive();

    /// @notice Emitted when a law is not active.
    error Powers__LawNotActive();

    /// @notice Emitted when a callData is invalid.
    error Powers__InvalidCallData();

    /// @notice Emitted when a law does not have the correct interface.
    error Powers__IncorrectInterface();

    /// @notice Emitted when an account has already cast a vote for a proposal.
    error Powers__AlreadyCastVote();

    /// @notice Emitted when a vote type is invalid.
    error Powers__InvalidVoteType();
}
