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
    struct Executions {
        address powers;
        bytes config;
        uint256[] actionsIds;
        uint48[] executions;
    }

    struct Conditions {
        // Slot 0
        uint256 allowedRole; // 32 bytes
        // Slot 1
        uint16 needCompleted; // 2 bytes - index of law that must be completed before this one
        uint48 delayExecution; // 6 bytes  - Blocks to wait after proposal success before execution
        uint48 throttleExecution; // 6 bytes  - Minimum blocks between executions
        uint16 readStateFrom; // 2 bytes - index of law to read state from (for law dependencies)
        uint32 votingPeriod; // 4 bytes  - Number of blocks for voting period
        uint8 quorum; // 1 byte   - Required participation percentage
        uint8 succeedAt; // 1 byte   - Required success percentage
        uint16 needNotCompleted; // 2 bytes - index of law that must NOT be completed
    }

    //////////////////////////////////////////////////////////////
    //                        EVENTS                            //
    //////////////////////////////////////////////////////////////

    /// @notice Emitted when a law is deployed
    /// @param configParams Configuration parameters for the law
    event Law__Deployed(bytes configParams);

    /// @notice Emitted when a law is initialized
    /// @param powers Address of the Powers protocol
    /// @param index Index of the law
    /// @param nameDescription Name of the law
    /// @param conditions Conditions for the law
    /// @param inputParams Input parameters for the law
    event Law__Initialized(
        address indexed powers, uint16 indexed index, string nameDescription, bytes inputParams, Conditions conditions, bytes config
    );

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////
    /// @notice Initializes the law
    /// @param index Index of the law
    /// @param nameDescription Name of the law
    /// @param inputParams Input parameters for the law
    /// @param conditions Conditions for the law
    /// @param config Configuration parameters for the law
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams, 
        Conditions memory conditions,
        bytes memory config
    ) external;

    /// @notice Executes the law's logic after validation
    /// @dev Called by the Powers protocol during action execution
    /// @param caller Address that initiated the action
    /// @param lawId The id of the law
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return success True if execution succeeded
    function executeLaw(address caller, uint16 lawId, bytes calldata lawCalldata, uint256 nonce)
        external
        returns (bool success);

    /// @notice Simulates the law's execution logic
    /// @dev Must be overridden by implementing contracts
    /// @param caller Address that initiated the action
    /// @param lawId The id of the law
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId The action ID
    /// @return targets Target contract addresses for calls
    /// @return values ETH values to send with calls
    /// @return calldatas Encoded function calls
    /// @return stateChange Encoded state changes to apply
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        external
        view
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        );

    //////////////////////////////////////////////////////////////
    //                     VALIDATION                           //
    //////////////////////////////////////////////////////////////

    /// @notice Validates conditions required to propose an action
    /// @dev Called during both proposal and execution
    /// @param caller Address attempting to propose
    /// @param conditions The conditions for the law
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtPropose(
        address caller,
        Conditions memory conditions,
        bytes memory lawCalldata,
        uint256 nonce,
        address powers
    ) external view;

    /// @notice Validates conditions required to execute an action
    /// @dev Called during execution after proposal checks
    /// @param caller Address attempting to execute
    /// @param conditions The conditions for the law
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtExecute(
        address caller,
        Conditions memory conditions,
        bytes memory lawCalldata,
        uint256 nonce,
        uint48[] memory executions,
        address powers,
        uint16 lawId
    ) external view;

    /// @notice Gets the conditions for a law
    /// @param powers The address of the Powers protocol
    /// @param lawId The id of the law
    /// @return conditions The conditions for the law
    function getConditions(address powers, uint16 lawId) external view returns (Conditions memory conditions);
}
