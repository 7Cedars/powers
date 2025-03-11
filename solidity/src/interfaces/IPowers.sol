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
/// @notice Interface for the Powers protocol.
/// Code derived from OpenZeppelin's Governor.sol contract.
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { PowersErrors } from "./PowersErrors.sol";
import { PowersEvents } from "./PowersEvents.sol";
import { PowersTypes } from "./PowersTypes.sol";
import { ILaw } from "./ILaw.sol";

interface IPowers is PowersErrors, PowersEvents, PowersTypes {
    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @notice the external function to call when a new proposal is created.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param description : the description of the proposal
    function propose(address targetLaw, bytes memory lawCalldata, string memory description)
        external
        returns (uint256);

    /// @notice external function to call to execute a proposal.
    /// The function can only be called from a whitelisted Law contract.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param description : the description of the proposal
    ///
    /// @dev note: the arrays of targets, values and calldatas must have the same length.
    ///
    /// Note any references to proposals (as in OpenZeppelin's {Governor} contract are removed.
    /// The mechanism of Powers detaches proposals from execution logic.
    /// Instead, proposal checks are placed in the {Law::executeLaw} function.
    function execute(address targetLaw, bytes memory lawCalldata, string memory description) external payable;

    /// @dev external function to call to cancel a proposal.
    /// Note The function can only be called by the account that proposed the proposal.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param descriptionHash : the descriptionHash of the proposal
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external returns (uint256);

    /// @dev external function to call to cast a vote.
    ///
    /// @param proposalId : the id of the proposal
    /// @param support : the support of the vote
    ///
    /// @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
    function castVote(uint256 proposalId, uint8 support) external;

    /// @dev external function to call to cast a vote with a reason.
    ///Has the exact same functionality as {castVote}, except that it adds a reason to the vote.
    ///
    /// @param proposalId : the id of the proposal
    /// @param support : the support of the vote
    /// @param reason : the reason for the vote
    ///
    /// @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external;

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @dev  external function to batch activate laws and roles in a DAO. Can only be called once, and only by Admin.
    ///
    /// @param laws : the addresses of the laws to be activated.
    ///
    /// emits a {LawAdopted} event for each law set.
    function constitute(address[] memory laws) external;

    /// @notice set a law to active or inactive.
    ///
    /// @param law address of the law.
    ///
    /// @dev this function can only be called from the execute function of SeperatedPowers.sol.
    ///
    /// emits a {LawAdopted} event
    function adoptLaw(address law) external;

    /// @notice set a law to inactive.
    ///
    /// @param law address of the law to deactivate.
    ///
    /// @dev this function can only be called from the execute function of SeperatedPowers.sol.
    ///
    /// emits a {LawRevoked} event
    function revokeLaw(address law) external;

    /// @notice assigns account to role
    ///
    /// @param roleId role identifier
    /// @param account account address
    ///
    /// @dev this function can only be called from within {SeperatedPowers}.
    function assignRole(uint32 roleId, address account) external;

    /// @notice revokes role access.
    ///
    /// @param roleId role identifier
    /// @param account account address
    ///
    /// @dev this function can only be called from within {SeperatedPowers}.
    function revokeRole(uint32 roleId, address account) external;

    /// @notice allows labelling of roles. Completely optional. 
    ///
    /// @param roleId role identifier
    /// @param label label of role.  
    ///
    /// @dev this function can only be called from within {SeperatedPowers}.
    /// @dev almost exact copy from OpenZeppelin's AccessManager.sol
    function labelRole(uint32 roleId, string calldata label) external;

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @dev returns the State of a proposal.
    ///
    /// @param proposalId : the id of the proposal
    ///
    /// @dev returns the State of a proposal
    function state(uint256 proposalId) external returns (ProposalState);

    /// @notice Checks if account has voted for a proposal.
    ///
    /// @dev Returns true if the role has been voted for a proposal.
    ///
    /// @param proposalId id of the proposal.
    /// @param account address of the account to check.
    function hasVoted(uint256 proposalId, address account) external returns (bool);

    /// @notice Returns the number of against, for, and abstain votes for a proposal.
    ///
    /// @param proposalId id of the proposal.
    function getProposalVotes(uint256 proposalId)
        external
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);

    /// @dev Retreives the deadline of a proposal.
    ///
    /// @param proposalId : the id of the proposal
    ///
    /// @dev returns the deadline of a proposal.
    function proposalDeadline(uint256 proposalId) external returns (uint256);

    /// @notice returns the block number since the account has held the role. Returns 0 if account does not currently hold the role.
    /// @param account account address
    /// @param roleId role identifier
    function hasRoleSince(address account, uint32 roleId) external returns (uint48 since);

    /// @notice returns the number of role holders.
    /// @param roleId role identifier
    function getAmountRoleHolders(uint32 roleId) external returns (uint256);

    /// @notice returns bool if law is set as active or not. (true = active, false = inactive).
    /// @param law address of the law.
    function getActiveLaw(address law) external returns (bool active);

    /// @dev checks if an account can call a law.
    ///
    /// @param caller caller address
    /// @param targetLaw law address to check.
    ///
    /// returns true if the caller can call the law.
    function canCallLaw(address caller, address targetLaw) external returns (bool);

    /// @dev returns the name of the protocol. This is the name of the Dao that inherits the {Powers} contract.
    function name() external returns (string memory);

    /// @dev returns the version of the protocol.
    /// Set at 1 for the current version. Cannot be changed in inherited contracts.
    function version() external returns (string memory);

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @dev Helper function to create a ProposalId on the basis of targetLaw, lawCalldata and descriptionHash.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param descriptionHash : the descriptionHash of the proposal
    ///
    /// Note the difference with the original at Governor.sol
    /// In Powersproposals are always aimed at a single Laws, with a single slot of calldata.
    /// This callData can have any kind of data.
    ///
    /// The call that is executed at the Law has the traditional layout of targets[], values[], calldatas[].
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        returns (uint256);

    /// @dev allows to reset the URI of the protocol.
    ///
    /// @param uri new uri
    ///
    /// @dev this function can only be called from within the {SeperatedPowers} protocol.
    function setUri(string memory uri) external;
}
