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

/// @title Law - Base Implementation for Powers Protocol Laws. v0.4.
/// @notice Base contract for implementing role-restricted governance actions
/// @dev Provides core functionality for creating institutional laws in the Powers protocol
///
/// Laws serve four key functions:
/// 1. Giving roles powers to transform input data into executable calldata.
/// 2. Validation of input and execution data.
/// 3. Calling external contracts and validating return data.
/// 4. Returning of data to the Powers protocol
///
/// Laws can be customized through:
/// - Inheriting and implementing bespoke logic in the {handleRequest} {_replyPowers} and {_externalCall} functions.
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { IPowers } from "./interfaces/IPowers.sol";
import { LawUtilities } from "./libraries/LawUtilities.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying

abstract contract Law is ERC165, ILaw {
    //////////////////////////////////////////////////////////////
    //                        STORAGE                           //
    //////////////////////////////////////////////////////////////
    struct LawData {
        string nameDescription;
        bytes inputParams;
        bytes config;
        address powers;
    }

    mapping(bytes32 lawHash => LawData) public laws;

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////
    // note this is an unrestricted function. Anyone can initialize a law.
    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        virtual
    {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        LawUtilities.checkStringLength(nameDescription, 1, 255);

        laws[lawHash] =
            LawData({ nameDescription: nameDescription, inputParams: inputParams, config: config, powers: msg.sender });

        emit Law__Initialized(msg.sender, index, nameDescription, inputParams, config);
    }

    /// @notice Executes the law's logic: validation -> handling request -> call external -> replying to Powers
    /// @dev Called by the Powers protocol during action execution
    /// @param caller Address that initiated the action
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return success True if execution succeeded
    function executeLaw(address caller, uint16 lawId, bytes calldata lawCalldata, uint256 nonce)
        public
        virtual
        returns (bool success)
    {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        if (laws[lawHash].powers != msg.sender) {
            revert("Only Powers");
        }

        // Simulate and execute the law's logic. This might include additional conditional checks.
        (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            handleRequest(caller, msg.sender, lawId, lawCalldata, nonce);

        _externalCall(lawId, actionId, targets, values, calldatas);

        _replyPowers(lawId, actionId, targets, values, calldatas);

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
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // Empty implementation - must be overridden
        revert("HandleRequest not implemented");
    }

    /// @notice Meant to be used to call an external contract. Especially usefull in the case of async laws.
    /// @dev Can be overridden by implementing contracts.
    /// @param lawId The id of the law
    /// @param actionId The action ID
    /// @param targets Target contract addresses for calls
    /// @param values ETH values to send with calls
    /// @param calldatas Encoded function calls
    function _externalCall(
        uint16 lawId,
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal virtual {
        // optional override by implementing contracts
    }

    /// @notice Meant to be used to reply to the Powers protocol. Can be overridden by implementing contracts.
    /// @dev Can be overridden by implementing contracts.
    /// @param lawId The id of the law
    /// @param actionId The action ID
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
        // NB Important for async calls! Leave the targets array empty in the replyPowers function and thereby disallow _replyPowers returning data to Powers. 
        // If data is send to Powers, the actionId will be set to fulfilled and the callback function will fail.  
        if (targets.length > 0) {
            IPowers(msg.sender).fulfill(lawId, actionId, targets, values, calldatas);
        }
    }

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    function getNameDescription(address powers, uint16 lawId) public view returns (string memory nameDescription) {
        return laws[LawUtilities.hashLaw(powers, lawId)].nameDescription;
    }

    function getInputParams(address powers, uint16 lawId) public view returns (bytes memory inputParams) {
        return laws[LawUtilities.hashLaw(powers, lawId)].inputParams;
    }

    function getConfig(address powers, uint16 lawId) public view returns (bytes memory config) {
        return laws[LawUtilities.hashLaw(powers, lawId)].config;
    }

    //////////////////////////////////////////////////////////////
    //                      UTILITIES                           //
    //////////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }
}
