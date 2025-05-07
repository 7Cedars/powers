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
import { StartGrant } from "./StartGrant.sol";
import { Grant } from "../state/Grant.sol";

contract StopGrant is Law {
    /// @notice Constructor for the StopGrant contract
    /// @param name_ Name of the law
    struct Data {
        uint256 maxBudgetLeft;
        bool checkDuration;
    }

    struct Mem {
        bytes32 lawHash;
        uint16 needCompleted;
        uint16 grantId;
        address startGrantLaw;
        address grantLaw;
        uint256 tokensLeft;
        uint48 durationLeft;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor(string memory name_) {
        LawUtilities.checkStringLength(name_);
        name = name_; 

        bytes memory configParams = abi.encode(
            "uint256 maxBudgetLeft",
            "bool checkDuration"
        );

        emit Law__Deployed(name_, configParams);
    }

    /// @notice Initializes the law with its configuration
    /// @param index Index of the law
    /// @param conditions Conditions for the law. NOTE: in this case the 'NeedCompleted' condition needs to be the 'StartGrant' law.
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
        (uint256 maxBudgetLeft, bool checkDuration) = abi.decode(config, (uint256, bool));
        data[LawUtilities.hashLaw(msg.sender, index)] = Data({
            maxBudgetLeft: maxBudgetLeft,
            checkDuration: checkDuration
        });

        inputParams = abi.encode(
            "uint48 Duration",
            "uint256 Budget",
            "address TokenAddress", 
            "string GrantDescription"
        );
        super.initializeLaw(index, conditions, config, inputParams, description);
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
        Mem memory mem;

        // load data to memory
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.needCompleted = conditionsLaws[mem.lawHash].needCompleted;
        if (mem.needCompleted == 0) {
            revert("NeedCompleted condition not set.");
        }
        (mem.startGrantLaw, , ) = Powers(payable(powers)).getActiveLaw(mem.needCompleted);
        mem.grantId = StartGrant(mem.startGrantLaw).getGrantId(mem.lawHash, lawCalldata);
        (mem.grantLaw, , ) = Powers(payable(powers)).getActiveLaw(mem.grantId);
        
        // check if grant exists
        if (mem.grantId == 0) {
            revert("Grant not found.");
        }

        // check if grant has spent all tokens
        if (data[mem.lawHash].maxBudgetLeft > 0) {
            mem.tokensLeft = Grant(mem.grantLaw).getTokensLeft(LawUtilities.hashLaw(powers, mem.grantId));
            if (mem.tokensLeft > data[mem.lawHash].maxBudgetLeft) {
                revert("Grant has not spent all tokens.");
            }
        }

        // check if grant has expired
        if (data[mem.lawHash].checkDuration) {
            mem.durationLeft = Grant(mem.grantLaw).getDurationLeft(LawUtilities.hashLaw(powers, mem.grantId));
            if (mem.durationLeft > 0) {
                revert("Grant has not expired.");
            }
        }

        // if check passed create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        
        // Set up the call to revokeLaw in Powers
        targets[0] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            Powers.revokeLaw.selector,
            mem.grantId
        );

        // Generate action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, targets, values, calldatas, "");
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
