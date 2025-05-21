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

/// @title CallElection - Law for calling an election
/// @notice This law allows the calling of an election
/// @dev Handles the dynamic configuration and adoption of new laws
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/console.sol"; // for testing only 

contract StartElection is Law {
    /// @notice Constructor for the CallElection contract
    struct Data {
        address electionLaw; 
        bytes electionConditions;
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(bytes32 electionHash => uint16)) internal lawIds;

    constructor() {
        bytes memory configParams = abi.encode(
            "address ElectionLaw", // Address of VoteOnAccounts law
            "bytes ElectionConditions" // NB: an bytes encoded ILaw.Conditions struct. Conditions for all subsequent elections are set when the call election law is adopted.  
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
        (address electionLaw, bytes memory electionConditions) =
            abi.decode(config, (address, bytes));
        
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].electionLaw = electionLaw;
        data[lawHash].electionConditions = electionConditions;
        inputParams = abi.encode("uint48 startVote", "uint48 endVote", "string Description");

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
    /// @param lawCalldata Encoded data containing the law to call and its configuration
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
        // Decode the law call data
        (uint48 startVote, uint48 endVote, string memory electionDescription) = 
            abi.decode(lawCalldata, (uint48, uint48, string));
        
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        ILaw.Conditions memory electionConditions = abi.decode(data[lawHash].electionConditions, (ILaw.Conditions));
        
        // Create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        
        // Set up the call to adoptLaw in Powers
        targets[0] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            Powers.adoptLaw.selector,
            PowersTypes.LawInitData({
                nameDescription: electionDescription,
                targetLaw: data[lawHash].electionLaw,
                config: abi.encode(startVote, endVote, electionDescription),
                conditions: electionConditions
            })
        );

        // Generate action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        uint16 electionsId = Powers(payable(powers)).lawCount();
        stateChange = abi.encode(electionsId, lawCalldata);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint16 electionsId, bytes memory lawCalldata) = abi.decode(stateChange, (uint16, bytes));
        lawIds[lawHash][keccak256(lawCalldata)] = electionsId;
    }

    function getElectionId(bytes32 lawHash, bytes memory lawCalldata) public view returns (uint16) {
        return lawIds[lawHash][keccak256(lawCalldata)];
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }   

}
