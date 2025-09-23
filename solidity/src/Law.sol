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

import { IPowers } from "./interfaces/IPowers.sol";
import { LawUtilities } from "./LawUtilities.sol";
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
        address[] externalContracts; // external contracts that are used by the law.
    }
    mapping(bytes32 lawHash => LawData) public laws;

    //////////////////////////////////////////////////////////////
    //                   LAW EXECUTION                          //
    //////////////////////////////////////////////////////////////
    // note this is an unrestricted function. Anyone can initialize a law.
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config,
        address[] memory externalContracts
    ) public virtual {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        LawUtilities.checkStringLength(nameDescription, 1, 255);

        laws[lawHash] = LawData({
            nameDescription: nameDescription,
            inputParams: inputParams,
            config: config,
            powers: msg.sender,
            externalContracts: externalContracts
        });

        emit Law__Initialized(msg.sender, index, nameDescription, inputParams, config, externalContracts);
    }

    /// @notice Executes the law's logic: validation -> handling request -> changing state -> replying to Powers
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
            revert Law__OnlyPowers();
        }

        // Simulate and execute the law's logic
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = handleRequest(caller, msg.sender, lawId, lawCalldata, nonce);

        // execute the law's logic conditional on data returned by handleRequest
        if (targets.length > 0) {
            IPowers(msg.sender).fulfill(lawId, actionId, targets, values, calldatas);
        }
    
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
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        // Empty implementation - must be overridden
    }

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    // todo? add getConfig function

    function getInputParams(address powers, uint16 lawId) public view returns (bytes memory inputParams) {
        return laws[LawUtilities.hashLaw(powers, lawId)].inputParams;
    }

    function getNameDescription(address powers, uint16 lawId) public view returns (string memory nameDescription) {
        return laws[LawUtilities.hashLaw(powers, lawId)].nameDescription;
    }

    //////////////////////////////////////////////////////////////
    //                      UTILITIES                           //
    //////////////////////////////////////////////////////////////
    /// @notice Checks if contract implements required interfaces
    /// @dev Implements IERC165
    /// @param interfaceId Interface identifier to check
    /// @return True if interface is supported
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }
}
