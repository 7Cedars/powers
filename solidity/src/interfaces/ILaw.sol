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

/// @notice Events used in the Powers protocol.
/// Code derived from OpenActionZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { LawErrors } from "./LawErrors.sol";

pragma solidity 0.8.26;

interface ILaw is IERC165, LawErrors {
    // £todo not yet optimised for memory slots.
    struct LawConfig {
        uint8 quorum;
        uint8 succeedAt;
        uint32 votingPeriod;
        address needCompleted;
        address needNotCompleted;
        uint48 delayExecution;
        uint48 throttleExecution;
        address readStateFrom; 
    }

    // @notice emitted when the law is initialized
    event Law__Initialized(
        address indexed law,
        address indexed powers,
        string name,
        string description,
        uint48 allowedRole,
        LawConfig config
    );

    /// @notice function to execute a law.
    /// @param initiator the address of the account that proposed execution of the law.
    /// @param lawCallData call data to be executed.
    /// @param descriptionHash the descriptionHash of the proposal
    ///
    /// note that this function is called by {Powers::execute}.
    /// note it calls the simulateLaw function and adds checks to ensure that the law is valid before execution.
    /// note that this function cannot be overwritten: powers will _always_ run checks before executing legal logic included in simulate law.
    ///
    /// @dev the output arrays of targets, values and calldatas must have the same length.
    function executeLaw(address initiator, bytes memory lawCallData, bytes32 descriptionHash)
        external
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas);

    /// @notice function to include logic of a law. It can be called by anyone, allowing for third parties to simulate input -> output of a law before execution.
    /// @param initiator the address of the account that proposed execution of the law.
    /// @param lawCalldata call data to be executed.
    /// @param descriptionHash the descriptionHash of the proposal
    ///
    /// note that this function should be overridden by law implementations to add logic of the law.
    ///
    /// @dev the arrays of targets, values and calldatas must have the same length.
    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange);

    /// @notice a public view function to check that the law is valid before creating a proposal or executing it.
    /// @dev Optional checks can be added by overriding this function.
    ///
    /// @param initiator the address of the proposer.
    /// @param lawCalldata the calldata for the law.
    /// @param descriptionHash the hash of the description of the law.
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) external view;

    /// @notice a public view function to check that the law is valid before execution.
    /// @dev Optional checks can be added by overriding this function.
    ///
    /// @param initiator the address of the proposer.
    /// @param lawCalldata the calldata for the law.
    /// @param descriptionHash the hash of the description of the law.
    function checksAtExecute(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) external view;
}
