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

/// @title Law Interface - Contract Interface for Powers Protocol Laws
/// @notice Defines the interface for implementing role-restricted governance actions
/// @dev Interface for the Law contract, which provides core functionality for governance laws
/// @author 7Cedars
pragma solidity 0.8.26;

import { IERC165 } from "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { LawErrors } from "./LawErrors.sol";

interface ILaw is IERC165, LawErrors {
    //////////////////////////////////////////////////////////////
    //                        TYPES                             //
    //////////////////////////////////////////////////////////////

    struct LawConfig {
        // Slot 1
        address needCompleted;      // 20 bytes - Address of law that must be completed before this one
        uint48 delayExecution;      // 6 bytes  - Blocks to wait after proposal success before execution
        uint48 throttleExecution;   // 6 bytes  - Minimum blocks between executions
        // Slot 2  
        address readStateFrom;      // 20 bytes - Address to read state from (for law dependencies)
        uint32 votingPeriod;       // 4 bytes  - Number of blocks for voting period
        uint8 quorum;              // 1 byte   - Required participation percentage
        uint8 succeedAt;           // 1 byte   - Required success percentage
        // Slot 3
        address needNotCompleted;   // 20 bytes - Address of law that must NOT be completed
    }

    //////////////////////////////////////////////////////////////
    //                        EVENTS                            //
    //////////////////////////////////////////////////////////////

    /// @notice Emitted when a law is initialized
    /// @param law Address of the initialized law contract
    /// @param name Name of the law
    /// @param description Description of the law's purpose
    /// @param powers Address of the Powers protocol contract
    /// @param allowedRole Role ID required to interact with this law
    /// @param config Configuration parameters for the law
    event Law__Initialized(
        address indexed law,
        string name,
        string description,
        address indexed powers,
        uint32 allowedRole,
        LawConfig config,
        bytes params
    );

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
        external
        returns (bool success);

    /// @notice Simulates the law's execution logic
    /// @dev Must be overridden by implementing contracts
    /// @param initiator Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    /// @return actionId The action ID
    /// @return targets Target contract addresses for calls
    /// @return values ETH values to send with calls
    /// @return calldatas Encoded function calls
    /// @return stateChange Encoded state changes to apply
    function handleRequest(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        view 
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange);

    //////////////////////////////////////////////////////////////
    //                     VALIDATION                           //
    //////////////////////////////////////////////////////////////

    /// @notice Validates conditions required to propose an action
    /// @dev Called during both proposal and execution
    /// @param initiator Address attempting to propose
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        view;

    /// @notice Validates conditions required to execute an action
    /// @dev Called during execution after proposal checks
    /// @param initiator Address attempting to execute
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    function checksAtExecute(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        view;
}
