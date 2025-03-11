// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and its contracts have not been audited.           ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Law - Base Implementation for Powers Protocol Laws
/// @notice Abstract base contract for implementing role-restricted governance actions
/// @dev Provides core functionality for creating governance laws in the Powers protocol
///
/// Laws serve five key functions:
/// 1. Role restriction of community actions
/// 2. Transformation of input data into executable calls
/// 3. State management for the community
/// 4. Validation of proposal and execution conditions
/// 5. Execution of governance actions
///
/// Laws can be customized through:
/// - Inheriting and implementing the {simulateLaw} {_replyPowers} and {_changeState} functions
/// - Configuring parameters in the constructor
/// - Adding custom state variables and logic
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { Powers } from "./Powers.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
 
contract Law is ERC165, ILaw {
    using ShortStrings for *;

    //////////////////////////////////////////////////////////////
    //                        STORAGE                           //
    //////////////////////////////////////////////////////////////

    /// @notice Name of the law
    ShortString public immutable name;

    /// @notice Role ID required to interact with this law
    uint32 public allowedRole;

    /// @notice Address of the Powers protocol contract
    address payable public powers;

    /// @notice Configuration parameters for the law
    LawConfig public config;

    /// @notice History of law executions (block numbers)
    /// @dev First element is always 0
    uint48[] public executions = [0];

    //////////////////////////////////////////////////////////////
    //                     CONSTRUCTOR                          //
    //////////////////////////////////////////////////////////////

    /// @notice Initializes a new law contract
    /// @param name_ Name of the law
    /// @param description_ Description of the law's purpose
    /// @param powers_ Address of the Powers protocol contract
    /// @param allowedRole_ Role ID required to interact with this law
    /// @param config_ Configuration parameters for the law
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) {
        name = name_.toShortString();
        allowedRole = allowedRole_;
        powers = powers_;
        config = config_;

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_);
    }

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////

    /// @notice Executes the law's logic after validation
    /// @dev Called by the Powers protocol during action execution
    /// @param initiator Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    /// @return success True if execution succeeded
    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        returns (bool success)
    {
        if (msg.sender != powers) {
            revert Law__OnlyPowers();
        }

        // Run all validation checks
        checksAtPropose(initiator, lawCalldata, descriptionHash);
        checksAtExecute(initiator, lawCalldata, descriptionHash);

        // Simulate and execute the law's logic
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange) = 
            simulateLaw(initiator, lawCalldata, descriptionHash);
        
        _replyPowers(targets, values, calldatas);
        _changeState(stateChange);
        
        executions.push(uint48(block.number));
        return true;
    }

    /// @notice Simulates the law's execution logic
    /// @dev Must be overridden by implementing contracts
    /// @param initiator Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    /// @return targets Target contract addresses for calls
    /// @return values ETH values to send with calls
    /// @return calldatas Encoded function calls
    /// @return stateChange Encoded state changes to apply
    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // Empty implementation - must be overridden
    }

    /// @notice Applies state changes from law execution
    /// @dev Must be overridden by implementing contracts
    /// @param stateChange Encoded state changes to apply
    function _changeState(bytes memory stateChange) internal virtual {
        // Empty implementation - must be overridden
    }

    /// @notice Sends execution data back to Powers protocol
    /// @dev Must be overridden by implementing contracts
    /// @param targets Target contract addresses for calls
    /// @param values ETH values to send with calls
    /// @param calldatas Encoded function calls
    function _replyPowers(address[] memory targets, uint256[] memory values, bytes[] memory calldatas) internal virtual {
        // Empty implementation - must be overridden
    }

    //////////////////////////////////////////////////////////////
    //                     VALIDATION                           //
    //////////////////////////////////////////////////////////////

    /// @notice Validates conditions required to propose an action
    /// @dev Called during both proposal and execution
    /// @param initiator Address attempting to propose
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
    {
        // Check if parent law completion is required
        if (config.needCompleted != address(0)) {
            uint256 parentActionId = _hashProposal(config.needCompleted, lawCalldata, descriptionHash);
            if (Powers(payable(powers)).state(parentActionId) != PowersTypes.ActionState.Completed) {
                revert Law__ParentNotCompleted();
            }
        }

        // Check if parent law must not be completed
        if (config.needNotCompleted != address(0)) {
            uint256 parentActionId = _hashProposal(config.needNotCompleted, lawCalldata, descriptionHash);
            if (Powers(payable(powers)).state(parentActionId) == PowersTypes.ActionState.Completed) {
                revert Law__ParentBlocksCompletion();
            }
        }
    }

    /// @notice Validates conditions required to execute an action
    /// @dev Called during execution after proposal checks
    /// @param initiator Address attempting to execute
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    function checksAtExecute(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
    {
        // Check execution throttling
        if (config.throttleExecution != 0) {
            uint256 numberOfExecutions = executions.length - 1;
            if (executions[numberOfExecutions] != 0 && 
                block.number - executions[numberOfExecutions] < config.throttleExecution) {
                revert Law__ExecutionGapTooSmall();
            }
        }

        // Check if proposal vote succeeded
        if (config.quorum != 0) {
            uint256 actionId = _hashProposal(address(this), lawCalldata, descriptionHash);
            if (Powers(payable(powers)).state(actionId) != PowersTypes.ActionState.Succeeded) {
                revert Law__ProposalNotSucceeded();
            }
        }

        // Check execution delay after proposal
        if (config.delayExecution != 0) {
            uint256 actionId = _hashProposal(address(this), lawCalldata, descriptionHash);
            uint256 deadline = Powers(payable(powers)).getProposalDeadline(actionId);
            if (deadline + config.delayExecution > block.number) {
                revert Law__DeadlineNotPassed();
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //                      UTILITIES                           //
    //////////////////////////////////////////////////////////////

    /// @notice Checks if contract implements required interfaces
    /// @dev Implements IERC165
    /// @param interfaceId Interface identifier to check
    /// @return True if interface is supported
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Creates a unique identifier for a proposal
    /// @param targetLaw Law contract being called
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the proposal description
    /// @return Unique proposal identifier
    function _hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }
}
