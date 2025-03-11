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

///
/// @notice Events used in the Powers protocol.
/// Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars
pragma solidity 0.8.26;

interface PowersEvents {
    /// @notice Emitted when protocol is initialized.
    /// @param contractAddress the address of the contract
    event Powers__Initialized(address contractAddress, string name);

    /// @notice Emitted when protocol receives funds/
    /// @param value the amount of funds received
    event FundsReceived(uint256 value);

    /// @notice Emitted when a proposal is created.
    /// @param proposalId the id of the proposal
    /// @param initiator the address of the initiator
    /// @param targetLaw the address of the target law
    /// @param signature the signature of the proposal
    /// @param executeCalldata the calldata to be passed to the law
    /// @param voteStart the start of the voting period
    /// @param voteEnd the end of the voting period
    /// @param description the description of the proposal
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed initiator,
        address targetLaw,
        string signature,
        bytes executeCalldata,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /// @notice Emitted when executive action is completed.
    /// @param initiator the address of the initiator
    /// @param targetLaw the address of the target law
    /// @param lawCalldata the calldata of the law
    /// @param description the description of the law action
    event ProposalCompleted(
        address indexed initiator, address indexed targetLaw, bytes lawCalldata, string description
    );

    /// @notice Emitted when a proposal for an executive action is cancelled.
    /// @param proposalId the id of the proposal
    event ProposalCancelled(uint256 indexed proposalId);

    // @notice Emitted when an executive action has been executed.
    /// @param targets the targets of the action
    /// @param values the values of the action
    /// @param calldatas the calldatas of the action
    event ProposalExecuted(address[] targets, uint256[] values, bytes[] calldatas);

    /// @notice Emitted when a vote is cast.
    /// @param account the address of the account that cast the vote
    /// @param proposalId the id of the proposal
    /// @param support support of the vote: Against, For or Abstain.
    /// @param reason the reason for the vote
    event VoteCast(address indexed account, uint256 indexed proposalId, uint8 indexed support, string reason);

    /// @notice Emitted when a role is set.
    /// @param roleId the id of the role
    /// @param account the address of the account that has the role
    event RoleSet(uint32 indexed roleId, address indexed account, bool indexed access);

    /// @notice Emitted when a role is labelled.
    /// @param roleId the id of the role. 
    /// @param label the label assigned to the role.
    event RoleLabel(uint32 indexed roleId, string label);  

    /// @notice Emitted when a law is set.
    /// @param law the address of the law
    event LawAdopted(address indexed law);

    /// @notice Emitted when a law is revoked.
    /// @param law the address of the law
    event LawRevoked(address indexed law);
}
