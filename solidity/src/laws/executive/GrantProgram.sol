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

/// @title GrantProgram - Law for managing a grant program in the Powers Protocol
/// @notice This law allows the management of a grant program in the Powers protocol
/// @dev Handles the dynamic configuration and management of a grant program
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/console2.sol"; // for testing only

contract GrantProgram is Law {
    struct Memory {
        string uriProposal;
        address grantee;
        address tokenAddress;
        uint256[] remainingBudgetPerToken;
        uint256[] milestoneDisbursements;
        uint256 totalDisbursements;
        address grantLaw;
        bytes grantConditions;
        bytes32 lawHash;
        uint16 grantsId;
        bytes32 grantHash;
        bytes lawCalldata;
        uint16 lawCount;
    }

    /// @notice Constructor for the GrantProgram contract
    struct Data {
        address grantLaw;
        uint256 granteeRoleId;
        bytes grantConditions;
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping (address allowedToken => uint256)) internal remainingBudgetPerToken;
    mapping(bytes32 lawHash => mapping(bytes32 grantHash => uint16)) internal grantIds;

    constructor() {
        bytes memory configParams = abi.encode(
            "address[] allowedTokens",  // Addresses of ERC20 tokens that can be used to fund grants.
            "uint256[] budgetTokens", // Total funds in the grant program, in each allowed token.
            "address grantLaw", // Address of grant law
            "uint256 granteeRoleId", // Role ID for the grantee
            "bytes grantConditions" // NB: a bytes encoded ILaw.Conditions struct. Conditions for all subsequent grants are set when the grant program law is adopted.
        );
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration
    /// @param index Index of the law
    /// @param nameDescription Name of the law
    /// @param conditions Conditions for the law
    /// @param config Configuration data
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        (
            address[] memory allowedTokens, 
            uint256[] memory totalBudgetPerToken, 
            address grantLaw, 
            uint256 granteeRoleId, 
            bytes memory grantConditions
            ) = abi.decode(config, (address[], uint256[], address, uint256, bytes));

        data[lawHash] = Data({ 
            grantLaw: grantLaw, 
            granteeRoleId: granteeRoleId, 
            grantConditions: grantConditions
            });

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address tokenAddress = allowedTokens[i];
            remainingBudgetPerToken[lawHash][tokenAddress] = totalBudgetPerToken[i];
        }

        inputParams = abi.encode(
            "string uriProposal",
            "address Grantee",
            "address TokenAddress",
            "uint256[] milestoneDisbursements"
        );

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    /// @notice Handles the request to adopt a new law
    /// @param caller Address initiating the request
    /// @param lawId ID of this law
    /// @param lawCalldata Encoded data containing the law to adopt and its configuration
    /// @param nonce Nonce for the action
    /// @return actionId ID of the created action
    /// @return targets Array of target addresses
    /// @return values Array of values to send
    /// @return calldatas Array of calldata for the calls
    /// @return stateChange State changes to apply
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        // Decode the law adoption data
        Memory memory mem;
        (mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursements) =
            abi.decode(lawCalldata, (string, address, address, uint256[]));

        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        Data memory grantProgramData = getData(mem.lawHash);
        ILaw.Conditions memory grantConditions = abi.decode(grantProgramData.grantConditions, (ILaw.Conditions));

        // calculate the total disbursements requested 
        for (uint256 i = 0; i < mem.milestoneDisbursements.length; i++) {
            mem.totalDisbursements += mem.milestoneDisbursements[i];
        }

        // check if requested token is allowed + has sufficient funds
        if (remainingBudgetPerToken[mem.lawHash][mem.tokenAddress] < mem.totalDisbursements) {
            revert("Insufficient funds");
        }

        // Create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);

        // Set up the call to adoptLaw in Powers
        targets[0] = powers; // Powers contract
        targets[1] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            // adopt the grant as a law, with the relevant conditions
            Powers.adoptLaw.selector,
            PowersTypes.LawInitData({
                nameDescription: mem.uriProposal, // we use the uriProposal as the nameDescription.
                targetLaw: data[mem.lawHash].grantLaw,
                config: abi.encode(
                    mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursements
                ),
                conditions: grantConditions
            })
        );
        // assign the grantee role to the grantee
        calldatas[1] = abi.encodeWithSelector(
            Powers.assignRole.selector,
            data[mem.lawHash].granteeRoleId, // grantee role
            mem.grantee // grantee address
        );

        // Generate action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        stateChange = abi.encode(Powers(payable(powers)).lawCount(), lawCalldata);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        Memory memory mem;
        (mem.lawCount, mem.lawCalldata) = abi.decode(stateChange, (uint16, bytes));
        (, , mem.tokenAddress, mem.milestoneDisbursements) = abi.decode(mem.lawCalldata, (string, address, address, uint256[]));

        // update the remaining budget per token
        // NOTE: If the grant is revoked before all its allocated funds are disbursed, the remaining budget will not be updated.
        // this means the grantProgram will not be able to disburse the remaining funds.
        // The funds will not be lost to the overall Powers protocol though. 
        for (uint256 i = 0; i < mem.milestoneDisbursements.length; i++) {
            remainingBudgetPerToken[lawHash][mem.tokenAddress] -= mem.milestoneDisbursements[i];
        }
        mem.grantHash = keccak256(mem.lawCalldata);
        grantIds[lawHash][mem.grantHash] = mem.lawCount;
    }

    function getGrantId(bytes32 lawHash, bytes memory lawCalldata) public view returns (uint16) {
        return grantIds[lawHash][keccak256(lawCalldata)];
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }

    function getRemainingBudgetPerToken(bytes32 lawHash, address tokenAddress) public view returns (uint256) {
        return remainingBudgetPerToken[lawHash][tokenAddress];
    }
}
