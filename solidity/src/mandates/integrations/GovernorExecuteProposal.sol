// SPDX-License-Identifier: MIT

/// @notice Execute proposals on a configured Governor contract.
///
/// This mandate allows executing governance proposals by validating their state
/// and then executing the proposal actions directly.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

contract GovernorExecuteProposal is Mandate {
    /// @notice Mapping from mandate hash to the governor contract address
    mapping(bytes32 mandateHash => address governorContract) public governorContracts;

    /// @notice Constructor for GovernorExecuteProposal mandate
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

    /// @notice Build a call to execute a Governor proposal after validation
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
        if (governorContract == address(0)) revert("GovernorExecuteProposal: Governor contract not configured");

        // Decode proposal parameters
        (
            address[] memory proposalTargets,
            uint256[] memory proposalValues,
            bytes[] memory proposalCalldatas,
            string memory description
        ) = abi.decode(mandateCalldata, (address[], uint256[], bytes[], string));

        // Validate proposal parameters
        if (proposalTargets.length == 0) revert("GovernorExecuteProposal: No targets provided");
        if (proposalTargets.length != proposalValues.length) {
            revert("GovernorExecuteProposal: Targets and values length mismatch");
        }
        if (proposalTargets.length != proposalCalldatas.length) {
            revert("GovernorExecuteProposal: Targets and calldatas length mismatch");
        }
        if (bytes(description).length == 0) revert("GovernorExecuteProposal: Description cannot be empty");

        // NB, todo: DEBUG
        // Get proposal ID from governor contract
        // uint256 proposalId = Governor(governorContract).getProposalId(
        //     proposalTargets, proposalValues, proposalCalldatas, keccak256(bytes(description))
        // );

        uint256 proposalId = 0;

        // Validate proposal exists
        if (proposalId == 0) revert("GovernorExecuteProposal: Proposal not found");

        // Check proposal state
        IGovernor.ProposalState state = Governor(governorContract).state(proposalId);
        if (state != IGovernor.ProposalState.Succeeded) {
            revert("GovernorExecuteProposal: Proposal not succeeded");
        }

        // Return the proposal actions for execution
        return (actionId, proposalTargets, proposalValues, proposalCalldatas);
    }
}
