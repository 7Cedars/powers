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
    /// @notice Emitted when an action has already been initiated.
    error Powers__ActionAlreadyInitiated();

    /// @notice Emitted when an action has been cancelled.
    error Powers__ActionCancelled();

    /// @notice Emitted when an action has not been initiated yet.
    error Powers__ActionNotRequested();

    /// @notice Emitted when a callData is invalid.
    error Powers__InvalidCallData();

    /// @notice Emitted when a law is not active.
    error Powers__LawNotActive();

    /// @notice Emitted when a function is called that does not need a vote.
    error Powers__NoVoteNeeded();

    /// @notice Emitted when a function is called from a contract that is not Powers.
    error Powers__OnlyPowers();

    /// @notice Emitted when an action is in an unexpected state.
    error Powers__UnexpectedActionState();

    /// @notice Emitted when a role is locked.
    error Powers__LockedRole();

    /// @notice Emitted when an incorrect interface is called.
    error Powers__IncorrectInterface();

    /// @notice Emitted when a proposed action is not active.
    error Powers__ProposedActionNotActive();

    /// @notice Emitted when a constitution has already been executed.
    error Powers__ConstitutionAlreadyExecuted();

    /// @notice Emitted when a law is not adopted.
    error Powers__AlreadyCastVote();

    /// @notice Emitted when a vote type is invalid.
    error Powers__InvalidVoteType();

    /// @notice Emitted when a role is locked.
    error Powers__CannotSetPublicRole();

    /// @notice Emitted when a zero address is added.
    error Powers__CannotAddZeroAddress();

    /// @notice Emitted when a name is invalid.
    error Powers__InvalidName();

    /// @notice Emitted when a role has no members.
    error Powers__NoMembersInRole();

    /// @notice Emitted when an action is already fulfilled.
    error Powers__ActionAlreadyFulfilled();

    /// @notice Emitted when a law request fails.
    error Powers__LawRequestFailed();

    /// @notice Emitted when a calldata is too long.
    error Powers__CalldataTooLong();

    /// @notice Emitted when an address is blacklisted.
    error Powers__AddressBlacklisted();

    /// @notice Emitted when an array is too long.
    error Powers__ExecutionArrayTooLong();

    /// @notice Emitted when an action does not exist.
    error Powers__ActionNotProposed();

    /// @notice Emitted when payable is not enabled.
    error Powers__PayableNotEnabled();

    /// @notice Emitted when an account cannot call a law.
    error Powers__CannotCallLaw();

    /// @notice Emitted when the caller is not the target law.
    error Powers__CallerNotTargetLaw();

    /// @notice Emitted when the caller is not the proposer of the action.
    error Powers__NotProposerAction();

    /// @notice Emitted when the caller is not the admin.
    error Powers__NotAdmin();

    /// @notice Emitted when an external contract is blacklisted.
    error Powers__ExternalContractBlacklisted();

    /// @notice Emitted when an external contract is not a contract.
    error Powers__NotAContract();
}
    