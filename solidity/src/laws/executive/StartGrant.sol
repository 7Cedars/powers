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

/// @title StartGrant - Law for Starting Grants in the Powers Protocol
/// @notice This law allows the starting of grants in the Powers protocol
/// @dev Handles the dynamic configuration and starting of grants
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/console2.sol"; // for testing only 

contract StartGrant is Law {

    struct Memory {
        string uriProposal;
        address grantee;
        address tokenAddress;
        uint256[] milestoneDisbursement;
        uint256 prevActionId;
        address grantLaw;
        bytes grantConditions;
        bytes32 lawHash;
        uint16 grantsId;
        bytes32 grantHash;
        bytes lawCalldata;
        uint16 lawCount;
    }

    /// @notice Constructor for the StartGrant contract
    struct Data {
        address grantLaw;
        bytes grantConditions;
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(bytes32 grantHash => uint16)) internal grantIds;

    constructor() {
        bytes memory configParams = abi.encode(
            "address grantLaw", // Address of grant law
            "bytes grantConditions" // NB: an bytes encoded ILaw.Conditions struct. Conditions for all subsequent grants are set when the start grant law is adopted.  
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
        (address grantLaw, bytes memory grantConditions) = abi.decode(config, (address, bytes));
        data[lawHash] = Data({
            grantLaw: grantLaw,
            grantConditions: grantConditions
        });

        inputParams = abi.encode("string uriProposal", "address Grantee", "address Token", "uint256[] milestoneDisbursement", "uint256 prevActionId");

        super.initializeLaw(
            index, 
            nameDescription,
            inputParams,
            conditions, 
            config
        );
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
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
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
        (mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursement, mem.prevActionId) = 
            abi.decode(lawCalldata, (string, address, address, uint256[], uint256));
        
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        ILaw.Conditions memory grantConditions = abi.decode(data[mem.lawHash].grantConditions, (ILaw.Conditions));
        
        // Create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);
        
        // Set up the call to adoptLaw in Powers
        targets[0] = powers; // Powers contract
        targets[1] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            Powers.adoptLaw.selector,
            PowersTypes.LawInitData({
                nameDescription: mem.uriProposal, // we use the uriProposal as the nameDescription. 
                targetLaw: data[mem.lawHash].grantLaw,
                config: abi.encode(mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursement, mem.prevActionId),
                conditions: grantConditions
            })
        );
        calldatas[1] = abi.encodeWithSelector(
            Powers.assignRole.selector,
            6, // grantee role
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
        mem.grantHash = keccak256(mem.lawCalldata);
        grantIds[lawHash][mem.grantHash] = mem.lawCount;
    }

    function getGrantId(bytes32 lawHash, bytes memory lawCalldata) public view returns (uint16) {
        return grantIds[lawHash][keccak256(lawCalldata)];
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }   

}
