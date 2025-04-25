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
    struct StateData {
        uint256 maxBudgetLeft;
        bool checkDuration;
    }

    mapping(bytes32 lawHash => StateData) public stateData;

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
        stateData[LawUtilities.hashLaw(msg.sender, index)] = StateData({
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
        uint16 needCompleted = conditionsLaws[LawUtilities.hashLaw(msg.sender, lawId)].needCompleted;
        if (needCompleted == 0) {
            revert("NeedCompleted condition not set.");
        }
        (address startGrantLaw, , ) = Powers(payable(msg.sender)).getActiveLaw(needCompleted);
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        uint16 grantId = StartGrant(startGrantLaw).getGrantId(lawHash, lawCalldata);
        (address GrantLaw, , ) = Powers(payable(msg.sender)).getActiveLaw(grantId);
        
        if (grantId == 0) {
            revert("Grant not found.");
        }
        if (stateData[lawHash].maxBudgetLeft > 0) {
            uint256 tokensLeft = Grant(GrantLaw).getTokensLeft(LawUtilities.hashLaw(msg.sender, grantId));
            if (tokensLeft > stateData[lawHash].maxBudgetLeft) {
                revert("Grant has not spent all tokens.");
            }
        }
        if (stateData[lawHash].checkDuration) {
            uint48 durationLeft = Grant(GrantLaw).getDurationLeft(LawUtilities.hashLaw(msg.sender, grantId));
            if (durationLeft > 0) {
                revert("Grant has not expired.");
            }
        }

        // if check passed create arrays for the adoption call
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        
        // Set up the call to adoptLaw in Powers
        targets[0] = msg.sender; // Powers contract
        calldatas[0] = abi.encodeWithSelector(
            Powers.revokeLaw.selector,
            grantId
        );

        // Generate action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, targets, values, calldatas, "");
    }
}
