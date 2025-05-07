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

/// @title AdoptLaw - Law for Adopting New Laws in the Powers Protocol
/// @notice This law allows the adoption of new laws into the Powers protocol
/// @dev Handles the dynamic configuration and adoption of new laws
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/console.sol"; // for testing only 

contract StartGrant is Law {
    /// @notice Constructor for the StartGrant contract
    struct Data {
        address grantLaw;
        bytes grantConditions;
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(bytes32 grantHash => uint16)) internal grantIds;

    constructor(string memory name_) {
        LawUtilities.checkStringLength(name_);
        name = name_;

        bytes memory configParams = abi.encode(
            "address grantLaw", // Address of grant law
            "bytes grantConditions" // NB: an bytes encoded ILaw.Conditions struct. Conditions for all subsequent grants are set when the start grant law is adopted.  
        );

        emit Law__Deployed(name_, configParams);
    }

    /// @notice Initializes the law with its configuration
    /// @param index Index of the law
    /// @param conditions Conditions for the law
    /// @param config Configuration data
    /// @param inputParams Additional input parameters
    /// @param description Description of the law
    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        (address grantLaw, bytes memory grantConditions) =
            abi.decode(config, (address, bytes));
        
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].grantLaw = grantLaw;
        data[lawHash].grantConditions = grantConditions;

        super.initializeLaw(
            index, 
            conditions, 
            config, 
            abi.encode("uint48 Duration", "uint256 Budget", "address TokenAddress", "string GrantDescription"), // inputParams
            description
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
        (uint48 duration, uint256 budget, address tokenAddress, string memory grantDescription) = 
            abi.decode(lawCalldata, (uint48, uint256, address, string));
        
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        ILaw.Conditions memory grantConditions = abi.decode(data[lawHash].grantConditions, (ILaw.Conditions));
        
        // Create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        
        // Set up the call to adoptLaw in Powers
        targets[0] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            Powers.adoptLaw.selector,
            PowersTypes.LawInitData({
                targetLaw: data[lawHash].grantLaw,
                config: abi.encode(duration, budget, tokenAddress),
                conditions: grantConditions,
                description: grantDescription
            })
        );

        // Generate action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        uint16 grantsId = Powers(payable(powers)).lawCount();
        stateChange = abi.encode(grantsId, lawCalldata);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint16 grantsId, bytes memory lawCalldata) = abi.decode(stateChange, (uint16, bytes));
        grantIds[lawHash][keccak256(lawCalldata)] = grantsId;
    }

    function getGrantId(bytes32 lawHash, bytes memory lawCalldata) public view returns (uint16) {
        return grantIds[lawHash][keccak256(lawCalldata)];
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }   

}
