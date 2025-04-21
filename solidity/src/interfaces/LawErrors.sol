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

/// @notice Errors used in {Law.sol}.
///
/// @dev Errors in implementations of law.sol have to use strings (as in revert("this is an error") instead of using custom function, to allow errors to bubble up.)
/// @author 7Cedars
///
pragma solidity 0.8.26;

interface LawErrors {
    /// @notice Emitted when a law is called by a non-powers account.
    error Law__OnlyPowers();

    /// @notice Emitted when a zero address is used.
    error Law__NoZeroAddress();

    /// @notice Emitted when a proposal is not succeeded.
    error Law__ProposalNotSucceeded();

    /// @notice Emitted when a parent law is not set.
    error Law__ParentLawNotSet();

    /// @notice Emitted when a deadline is not set.
    error Law__NoDeadlineSet();

    /// @notice Emitted when a powers contract address is invalid.
    error Law__InvalidPowersContractAddress();

    /// @notice Emitted when a parent law is not completed.
    error Law__ParentNotCompleted();

    /// @notice Emitted when a parent law is not completed.
    error Law__ParentBlocksCompletion();

    /// @notice Emitted when a execution gap is too small.
    error Law__ExecutionGapTooSmall();

    /// @notice Emitted when a deadline is not passed.
    error Law__DeadlineNotPassed();
}
