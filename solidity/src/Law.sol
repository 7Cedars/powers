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
/// - Inheriting and implementing the {handleRequest} {_replyPowers} and {_changeState} functions
/// - Configuring parameters in the constructor
/// - Adding custom state variables and logic
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { Powers } from "./Powers.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
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
    LawChecks public config;

    /// @notice History of law executions (block numbers)
    /// @dev First element is always 0
    uint48[] public executions = [0];

    //////////////////////////////////////////////////////////////
    //                   CONSTRUCTOR                            //
    //////////////////////////////////////////////////////////////

    /// @notice Constructor for the Law contract
    /// @param name_ The name of the law
    /// @param powers_ The address of the Powers protocol
    /// @param allowedRole_ The role ID required to interact with this law
    /// @param config_ The configuration parameters for the law 
    constructor(
        string memory name_,
        address payable powers_,
        uint32 allowedRole_,
        LawChecks memory config_
    ) { 
        if (powers_ == address(0)) {
            revert Law__InvalidPowersContractAddress();
        }
        if (bytes(name_).length < 1) {
            revert Law__EmptyNameNotAllowed();
        }
        name = name_.toShortString();
        powers = powers_;
        allowedRole = allowedRole_;
        config = config_;
    }

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////

    /// @notice Executes the law's logic after validation
    /// @dev Called by the Powers protocol during action execution
    /// @param caller Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return success True if execution succeeded
    function executeLaw(address caller, bytes calldata lawCalldata, uint256 nonce)
        public
        returns (bool success)
    {
        if (msg.sender != powers) {
            revert Law__OnlyPowers();
        }

        // Run all validation checks
        checksAtPropose(caller, lawCalldata, nonce);
        checksAtExecute(caller, lawCalldata, nonce);

        // Simulate and execute the law's logic
        (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange) = 
            handleRequest(caller, lawCalldata, nonce);
        
        // execute the law's logic conditional on data returned by handleRequest
        if (stateChange.length > 0) {
            _changeState(stateChange);
        }
        if (targets.length > 0) {
            _replyPowers(actionId, targets, values, calldatas); // this is where the law's logic is executed. I should check if call is successful. It will revert if not succesful, right? 
        }
        executions.push(uint48(block.number));
        return true;
    }

    /// @notice Simulates the law's execution logic
    /// @dev Must be overridden by implementing contracts
    /// @param caller Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId The action ID
    /// @return targets Target contract addresses for calls
    /// @return values ETH values to send with calls
    /// @return calldatas Encoded function calls
    /// @return stateChange Encoded state changes to apply
    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view 
        virtual
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
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
    /// @param actionId The action id of the proposal
    /// @param targets Target contract addresses for calls
    /// @param values ETH values to send with calls
    /// @param calldatas Encoded function calls
    function _replyPowers(uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) internal virtual {
        // Base implementation: send data back to Powers protocol
        // this implementation can be overwritten with any kind of bespoke logic. 
        Powers(payable(powers)).fulfill(actionId, targets, values, calldatas);
    }




    //////////////////////////////////////////////////////////////
    //                     VALIDATION                           //
    //////////////////////////////////////////////////////////////

    /// @notice Validates conditions required to propose an action
    /// @dev Called during both proposal and execution
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtPropose(address /*caller*/, bytes calldata lawCalldata, uint256 nonce)
        public
        view
        virtual
    {
        // Check if parent law completion is required
        if (config.needCompleted != address(0)) {
            uint256 parentActionId = _hashActionId(config.needCompleted, lawCalldata, nonce);

            if (Powers(payable(powers)).state(parentActionId) != PowersTypes.ActionState.Fulfilled) {
                revert Law__ParentNotCompleted();
            }
        }

        // Check if parent law must not be completed
        if (config.needNotCompleted != address(0)) {
            uint256 parentActionId = _hashActionId(config.needNotCompleted, lawCalldata, nonce);

            if (Powers(payable(powers)).state(parentActionId) == PowersTypes.ActionState.Fulfilled) {
                revert Law__ParentBlocksCompletion();
            }
        }
    }

    /// @notice Validates conditions required to execute an action
    /// @dev Called during execution after proposal checks
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtExecute(address /*caller*/, bytes calldata lawCalldata, uint256 nonce)
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
            uint256 actionId = _hashActionId(address(this), lawCalldata, nonce);
            if (Powers(payable(powers)).state(actionId) != PowersTypes.ActionState.Succeeded) {
                revert Law__ProposalNotSucceeded();
            }
        }

        // Check execution delay after proposal
        if (config.delayExecution != 0) {
            uint256 actionId = _hashActionId(address(this), lawCalldata, nonce);
            uint256 deadline = Powers(payable(powers)).getProposedActionDeadline(actionId);
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

    function _hashActionId(address targetLaw, bytes memory lawCalldata, uint256 nonce)
        internal
        pure
        returns (uint256 actionId)
    {
       actionId = uint256(keccak256(abi.encode(targetLaw, lawCalldata, nonce)));
    }
}
