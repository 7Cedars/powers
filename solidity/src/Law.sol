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

/// @title Law - Base Implementation for Powers Protocol Laws. v0.3.
/// @notice Base contract for implementing role-restricted governance actions
/// @dev Provides core functionality for creating governance laws in the Powers protocol
///
/// Laws serve five key functions:
/// 1. Role restriction of community actions
/// 2. Transformation of input data into executable calls
/// 3. State management for the community
/// 4. Validation of proposal and execution conditions
/// 5. Returning of data to the Powers protocol
///
/// Laws can be customized through:
/// - conditionsuring checks in the constructor
/// - Inheriting and implementing bespoke logic in the {handleRequest} {_replyPowers} and {_changeState} functions.
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { Powers } from "./Powers.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";
import { LawUtilities } from "./LawUtilities.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying

contract Law is ERC165, ILaw {
    //////////////////////////////////////////////////////////////
    //                        STORAGE                           //
    //////////////////////////////////////////////////////////////
    /// @notice Name of the law
    string public name;
    mapping(bytes32 lawHash => Conditions) public conditionsLaws;
    mapping(bytes32 lawHash => Executions) public executionsLaws;

    //////////////////////////////////////////////////////////////
    //                   CONSTRUCTOR                            //
    //////////////////////////////////////////////////////////////
    /// @notice Constructor for the Law contract
    /// @param name_ The name of the law. It has to fit in one storage slot. (this way it will be saved as a short string)
    constructor(string memory name_) {
        if (bytes(name_).length < 1) {
            revert Law__EmptyNameNotAllowed();
        }
        if (bytes(name_).length > 31) {
            revert Law__StringTooLong();
        }
        name = name_;
    }

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////

    // note this is an unrestricted function. Anyone can initialize a law. 
    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public virtual {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        conditionsLaws[lawHash] = conditions;
        executionsLaws[lawHash] = Executions({ powers: msg.sender, config: config, executions: new uint48[](1) });
        executionsLaws[lawHash].executions[0] = uint48(block.number); // we save initiation block number as first execution. 

        emit Law__Initialized(msg.sender, index, conditions, inputParams, description);
    }

    /// @notice Executes the law's logic: validation -> handling request -> changing state -> replying to Powers
    /// @dev Called by the Powers protocol during action execution
    /// @param caller Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return success True if execution succeeded
    function executeLaw(address caller, uint16 lawId, bytes calldata lawCalldata, uint256 nonce)
        public
        returns (bool success)
    {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        // console2.logBytes32(lawHash);
        // console2.log(executionsLaws[lawHash].powers);
        // console2.log(msg.sender);
        if (executionsLaws[lawHash].powers != msg.sender) {
            revert Law__OnlyPowers();
        }

        // Run all validation checks
        checksAtPropose(caller, conditionsLaws[lawHash], lawCalldata, nonce, msg.sender);
        checksAtExecute(
            caller, conditionsLaws[lawHash], lawCalldata, nonce, executionsLaws[lawHash].executions, msg.sender, lawId
        );

        // Simulate and execute the law's logic
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        ) = handleRequest(caller, lawId, lawCalldata, nonce);

        // execute the law's logic conditional on data returned by handleRequest
        if (stateChange.length > 0) {
            _changeState(lawHash, stateChange);
        }
        if (targets.length > 0) {
            _replyPowers(lawId, actionId, targets, values, calldatas); // this is where the law's logic is executed. I should check if call is successful. It will revert if not succesful, right?
        }
        executionsLaws[lawHash].executions.push(uint48(block.number));
        return true;
    }

    /// @notice Handles requests from the Powers protocol and returns data _replyPowers and _changeState can use.
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
    function handleRequest(address caller, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        // Empty implementation - must be overridden
    }

    /// @notice Applies state changes from law execution
    /// @dev Must be overridden by implementing contracts
    /// @param stateChange Encoded state changes to apply
    function _changeState(bytes32 lawHash, bytes memory stateChange) internal virtual {
        // Empty implementation - must be overridden
    }

    /// @notice Sends execution data back to Powers protocol
    /// @dev Must be overridden by implementing contracts
    /// @param lawId The law id of the proposal
    /// @param actionId The action id of the proposal
    /// @param targets Target contract addresses for calls
    /// @param values ETH values to send with calls
    /// @param calldatas Encoded function calls
    function _replyPowers(
        uint16 lawId,
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal virtual {
        // Base implementation: send data back to Powers protocol
        // this implementation can be overwritten with any kind of bespoke logic.
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        Powers(payable(executionsLaws[lawHash].powers)).fulfill(lawId, actionId, targets, values, calldatas);
    }

    //////////////////////////////////////////////////////////////
    //                     VALIDATION                           //
    //////////////////////////////////////////////////////////////
    /// @notice Validates conditions required to propose an action
    /// @dev Called during both proposal and execution
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtPropose(
        address, /*caller*/
        Conditions memory conditions,
        bytes memory lawCalldata,
        uint256 nonce,
        address powers
    ) public view virtual {
        // console2.log("checksAtPropose");
        // console2.log(conditions.allowedRole);
        // console2.logBytes(lawCalldata);
        // console2.log(nonce);
        // console2.log(powers);
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, powers, nonce);
    }

    /// @notice Validates conditions required to execute an action
    /// @dev Called during execution after proposal checks
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    function checksAtExecute(
        address, /*caller*/
        Conditions memory conditions,
        bytes memory lawCalldata,
        uint256 nonce,
        uint48[] memory executions,
        address powers,
        uint16 lawId
    ) public view virtual {
        // console2.log("checksAtExecute");
        // console2.log(lawId);
        // console2.log(conditions.allowedRole);
        // console2.logBytes(lawCalldata);
        // console2.log(nonce);
        // console2.log(powers);

        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, powers, nonce, executions, lawId);
    }

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @notice Creates a unique identifier for an action
    /// @dev Hashes the combination of law address, calldata, and nonce
    /// @param lawId Address of the law contract being called
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId Unique identifier for the action
    function hashActionId(uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        pure
        returns (uint256 actionId)
    {
        actionId = uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)));
    }

    /// @notice Creates a unique identifier for a law, used for sandboxing executions of laws.
    /// @dev Hashes the combination of law address and index
    /// @param powers Address of the Powers contract
    /// @param index Index of the law
    /// @return lawHash Unique identifier for the law
    function hashLaw(address powers, uint16 index) public pure returns (bytes32 lawHash) {
        lawHash = keccak256(abi.encode(powers, index));
    }

    /// @notice Creates empty arrays for storing transaction data
    /// @dev Initializes three arrays of the same length for targets, values, and calldata
    /// @param length The desired length of the arrays
    /// @return targets Array of target addresses
    /// @return values Array of ETH values
    /// @return calldatas Array of encoded function calls
    function createEmptyArrays(uint256 length)
        public
        pure
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](length);
        values = new uint256[](length);
        calldatas = new bytes[](length);
    }

    function getConditions(uint16 lawId) public view returns (Conditions memory conditions) {
        return conditionsLaws[hashLaw(msg.sender, lawId)];
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
}
