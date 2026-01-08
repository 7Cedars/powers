// SPDX-License-Identifier: MIT

/// @notice Create proposals on a configured Governor contract.
///
/// This mandate allows creating governance proposals by calling the propose function
/// on a configured Governor contract (e.g., SimpleGovernor).
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

contract GovernorCreateProposal is Mandate {
    /// @notice Mapping from mandate hash to the governor contract address
    mapping(bytes32 mandateHash => address governorContract) public governorContracts;

    /// @notice Constructor for GovernorCreateProposal mandate
    constructor() {
        bytes memory configParams = abi.encode("address GovernorContract");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        (governorContracts[mandateHash]) = abi.decode(config, (address));

        // Set UI-exposed input parameters: targets, values, calldatas, description
        inputParams = abi.encode("address[] targets", "uint256[] values", "bytes[] calldatas", "string description");
        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Build a call to the Governor.propose function
    /// @param mandateCalldata Encoded (address[] targets, uint256[] values, bytes[] calldatas, string description)
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Validate that governor contract is configured
        address payable governorContract = payable(governorContracts[mandateHash]);
        if (governorContract == address(0)) revert("GovernorCreateProposal: Governor contract not configured");

        // Decode proposal parameters
        (
            address[] memory proposalTargets,
            uint256[] memory proposalValues,
            bytes[] memory proposalCalldatas,
            string memory description
        ) = abi.decode(mandateCalldata, (address[], uint256[], bytes[], string));

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
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = governorContract;
        calldatas[0] = abi.encodeWithSelector(
            Governor.propose.selector, proposalTargets, proposalValues, proposalCalldatas, description
        );

        return (actionId, targets, values, calldatas);
    }
}
