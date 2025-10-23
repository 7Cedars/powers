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

/// @title Powers Protocol Interface
/// @notice Interface for Powers, a protocol implementing Institutional Governance.
/// @dev Derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
/// @author 7Cedars
pragma solidity 0.8.26;

import { PowersErrors } from "./PowersErrors.sol";
import { PowersEvents } from "./PowersEvents.sol";
import { PowersTypes } from "./PowersTypes.sol";
import { ILaw } from "./ILaw.sol";

interface IPowers is PowersErrors, PowersEvents, PowersTypes {
    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Initiates an action to be executed through a law
    /// @dev This is the entry point for all actions in the protocol, whether they require voting or not
    /// @param lawId The id of the law
    /// @param lawCalldata The encoded function call data for the law
    /// @param uriDescription A human-readable description of the action
    /// @param nonce The nonce for the action
    function request(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriDescription)
        external
        payable
        returns (uint256 actionId);

    /// @notice Completes an action by executing the actual calls
    /// @dev Can only be called by an active law contract
    /// @param lawId The id of the law
    /// @param actionId The unique identifier of the action
    /// @param targets The list of contract addresses to call
    /// @param values The list of ETH values to send with each call
    /// @param calldatas The list of encoded function calls
    function fulfill(
        uint16 lawId,
        uint256 actionId,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external payable;

    /// @notice Creates a new proposal for an action that requires voting
    /// @dev Only callable if the law requires voting (quorum > 0)
    /// @param lawId The id of the law
    /// @param lawCalldata The encoded function call data for the law
    /// @param nonce The nonce for the action
    /// @param uriDescription A human-readable description of the proposal
    /// @return actionId The unique identifier of the created proposal
    function propose(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriDescription)
        external
        returns (uint256 actionId);

    /// @notice Cancels an existing proposal
    /// @dev Can only be called by the original proposer
    /// @param lawId The id of the law
    /// @param lawCalldata The original encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId The unique identifier of the cancelled proposal
    function cancel(uint16 lawId, bytes calldata lawCalldata, uint256 nonce) external returns (uint256 actionId);

    /// @notice Casts a vote on an active proposal
    /// @dev Vote types: 0=Against, 1=For, 2=Abstain
    /// @param actionId The unique identifier of the proposal
    /// @param support The type of vote to cast
    function castVote(uint256 actionId, uint8 support) external;

    /// @notice Casts a vote on an active proposal with an explanation
    /// @dev Same as castVote but includes a reason string
    /// @param actionId The unique identifier of the proposal
    /// @param support The type of vote to cast
    /// @param reason A human-readable explanation for the vote
    function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) external;

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                       //
    //////////////////////////////////////////////////////////////

    /// @notice Initializes the DAO by activating its founding laws
    /// @dev Can only be called once by an admin account
    /// @param laws The list of law contracts to activate
    function constitute(LawInitData[] calldata laws) external;

    /// @notice Activates a new law in the protocol
    /// @dev Can only be called through the protocol itself
    /// @param lawInitData The data of the law
    function adoptLaw(LawInitData calldata lawInitData) external returns (uint256 lawId);

    /// @notice Deactivates an existing law
    /// @dev Can only be called through the protocol itself
    /// @param lawId The id of the law
    function revokeLaw(uint16 lawId) external;

    /// @notice Grants a role to an account
    /// @dev Can only be called through the protocol itself
    /// @param roleId The identifier of the role to assign
    /// @param account The address to grant the role to
    function assignRole(uint256 roleId, address account) external;

    /// @notice Removes a role from an account
    /// @dev Can only be called through the protocol itself
    /// @param roleId The identifier of the role to remove
    /// @param account The address to remove the role from
    function revokeRole(uint256 roleId, address account) external;

    /// @notice Assigns a human-readable label to a role
    /// @dev Optional. Can only be called through the protocol itself
    /// @param roleId The identifier of the role to label
    /// @param label The human-readable label for the role
    function labelRole(uint256 roleId, string calldata label) external;

    /// @notice Updates the protocol's metadata URI
    /// @dev Can only be called through the protocol itself
    /// @param newUri The new URI string
    function setUri(string memory newUri) external;

    /// @notice Blacklists an account
    /// @dev Can only be called through the protocol itself
    /// @param account The address to blacklist
    /// @param blacklisted The blacklisted status of the account
    function blacklistAddress(address account, bool blacklisted) external;

    /// @notice Sets the payable enabled status
    /// @dev IMPORTANT: When payable is enabled, ether can be sent to the protocol. If there is no law to retrieve the funds - and no law to adopt new laws - the funds will be locked in the protocol for ever.
    /// @param payableEnabled The payable enabled status
    function setPayableEnabled(bool payableEnabled) external;

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                       //
    //////////////////////////////////////////////////////////////
    /// @notice Gets the quantity of actions of a law
    /// @param lawId The id of the law
    /// @return quantityLawActions The quantity of actions of the law
    function getQuantityLawActions(uint16 lawId) external view returns (uint256 quantityLawActions);

    /// @notice Gets the current state of a proposal
    /// @param actionId The unique identifier of the proposal
    /// @return state the current state of the proposal
    function getActionState(uint256 actionId) external view returns (ActionState state);

    /// @notice Checks if an account has voted on a specific proposal
    /// @param actionId The unique identifier of the proposal
    /// @param account The address to check
    /// @return hasVoted True if the account has voted, false otherwise
    function hasVoted(uint256 actionId, address account) external view returns (bool hasVoted);

    /// @notice gets the data of an actionId that are not an array.
    /// @param actionId The unique identifier of the proposal
    /// @return lawId - the id of the law that the action is associated with
    /// @return proposedAt - the block number at which the action was proposed
    /// @return requestedAt - the block number at which the action was requested
    /// @return fulfilledAt - the block number at which the action was fulfilled
    /// @return cancelledAt - the block number at which the action was cancelled
    /// @return caller - the address of the caller
    /// @return nonce - the nonce of the action
    function getActionData(uint256 actionId)
        external
        view
        returns (
            uint16 lawId,
            uint48 proposedAt,
            uint48 requestedAt,
            uint48 fulfilledAt,
            uint48 cancelledAt,
            address caller,
            uint256 nonce
        );

    /// @notice gets the vote data of an actionId that are not an array.
    /// @param actionId The unique identifier of the proposal
    /// @return voteStart - the block number at which voting starts
    /// @return voteDuration - the duration of the voting period
    /// @return voteEnd - the block number at which voting ends
    /// @return againstVotes - the number of votes against the action
    /// @return forVotes - the number of votes for the action
    /// @return abstainVotes - the number of abstain votes
    function getActionVoteData(uint256 actionId)
        external
        view
        returns (
            uint48 voteStart,
            uint32 voteDuration,
            uint256 voteEnd,
            uint32 againstVotes,
            uint32 forVotes,
            uint32 abstainVotes
        );

    /// @notice Gets the calldata for a specific action
    /// @param actionId The unique identifier of the action
    /// @return callData The calldata for the action
    function getActionCalldata(uint256 actionId) external view returns (bytes memory callData);

    /// @notice Gets the return data for a specific action
    /// @param actionId The unique identifier of the action
    /// @param index The index of the return data
    /// @return returnData The return data for the action
    function getActionReturnData(uint256 actionId, uint256 index) external view returns (bytes memory returnData);

    /// @notice Gets the URI for a specific action
    /// @param actionId The unique identifier of the action
    /// @return _uri The URI for the action
    function getActionUri(uint256 actionId) external view returns (string memory _uri);

    /// @notice Gets the block number since which an account has held a role
    /// @param account The address to check
    /// @param roleId The identifier of the role
    /// @return since the block number since holding the role, 0 if never held
    function hasRoleSince(address account, uint256 roleId) external view returns (uint48 since);

    /// @notice Gets the total number of accounts holding a specific role
    /// @param roleId The identifier of the role
    /// @return amountMembers the number of role holders
    function getAmountRoleHolders(uint256 roleId) external view returns (uint256 amountMembers);

    /// @notice Gets the holder of a role at a specific index
    /// @param roleId The identifier of the role
    /// @param index The index of the role holder
    /// @return account The address of the role holder
    function getRoleHolderAtIndex(uint256 roleId, uint256 index) external view returns (address account);

    /// @notice Gets the label of a role
    /// @param roleId The identifier of the role
    /// @return label The label of the role
    function getRoleLabel(uint256 roleId) external view returns (string memory label);

    /// @notice Checks if a law is currently active
    /// @param lawId The id of the law
    /// @return law The address of the law
    /// @return lawHash The hash of the law
    /// @return active The active status of the law
    function getAdoptedLaw(uint16 lawId) external view returns (address law, bytes32 lawHash, bool active);

    /// @notice Gets the latest fulfillment of a law
    /// @param lawId The id of the law
    /// @return latestFulfillment The latest fulfillment of the law
    function getLatestFulfillment(uint16 lawId) external view returns (uint48 latestFulfillment);

    /// @notice Gets the actions of a law
    /// @param lawId The id of the law
    /// @param index The index of the action
    /// @return actionId The action at the index
    function getLawActionAtIndex(uint16 lawId, uint256 index) external view returns (uint256 actionId);

    /// @notice Gets the conditions of a law
    /// @param lawId The id of the law
    /// @return conditions The conditions of the law
    function getConditions(uint16 lawId) external view returns (Conditions memory conditions);

    /// @notice Checks if an account has permission to call a law
    /// @param caller The address attempting to call the law
    /// @param lawId The law id to check
    /// @return canCall True if the caller has permission, false otherwise
    function canCallLaw(address caller, uint16 lawId) external view returns (bool canCall);

    /// @notice Gets the protocol version
    /// @return version the version string
    function version() external pure returns (string memory version);

    /// @notice Checks if an account is blacklisted
    /// @param account The address to check
    /// @return blacklisted The blacklisted status of the account
    function isBlacklisted(address account) external view returns (bool blacklisted);

    //////////////////////////////////////////////////////////////
    //                      TOKEN HANDLING                      //
    //////////////////////////////////////////////////////////////

    /// @notice Handles the receipt of a single ERC721 token
    /// @dev Implements IERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);

    /// @notice Handles the receipt of a single ERC1155 token
    /// @dev Implements IERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);

    /// @notice Handles the receipt of multiple ERC1155 tokens
    /// @dev Implements IERC1155Receiver
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        returns (bytes4);
}
