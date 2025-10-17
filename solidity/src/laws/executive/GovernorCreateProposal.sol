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

/// @notice Create proposals on a configured Governor contract.
///
/// This law allows creating governance proposals by calling the propose function
/// on a configured Governor contract (e.g., SimpleGovernor).
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

contract GovernorCreateProposal is Law {
    /// @notice Mapping from law hash to the governor contract address
    mapping(bytes32 lawHash => address governorContract) public governorContracts;

    /// @notice Constructor for GovernorCreateProposal law
    constructor() {
        bytes memory configParams = abi.encode("address GovernorContract");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address governorContract_) = abi.decode(config, (address));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        governorContracts[lawHash] = governorContract_;

        // Set UI-exposed input parameters: targets, values, calldatas, description
        inputParams = abi.encode("address[] targets", "uint256[] values", "bytes[] calldatas", "string description");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build a call to the Governor.propose function
    /// @param lawCalldata Encoded (address[] targets, uint256[] values, bytes[] calldatas, string description)
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Validate that governor contract is configured
        address payable governorContract = payable(governorContracts[lawHash]);
        if (governorContract == address(0)) revert("GovernorCreateProposal: Governor contract not configured");

        // Decode proposal parameters
        (
            address[] memory proposalTargets,
            uint256[] memory proposalValues,
            bytes[] memory proposalCalldatas,
            string memory description
        ) = abi.decode(lawCalldata, (address[], uint256[], bytes[], string));

        // Validate proposal parameters
        if (proposalTargets.length == 0) revert("GovernorCreateProposal: No targets provided");
        if (proposalTargets.length != proposalValues.length) {
            revert("GovernorCreateProposal: Targets and values length mismatch");
        }
        if (proposalTargets.length != proposalCalldatas.length) {
            revert("GovernorCreateProposal: Targets and calldatas length mismatch");
        }
        if (bytes(description).length == 0) revert("GovernorCreateProposal: Description cannot be empty");

        // Create arrays for the call to propose
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = governorContract;
        calldatas[0] = abi.encodeWithSelector(
            Governor.propose.selector, proposalTargets, proposalValues, proposalCalldatas, description
        );

        return (actionId, targets, values, calldatas);
    }
}
