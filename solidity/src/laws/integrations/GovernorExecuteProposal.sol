// SPDX-License-Identifier: MIT

/// @notice Execute proposals on a configured Governor contract.
///
/// This law allows executing governance proposals by validating their state
/// and then executing the proposal actions directly.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

contract GovernorExecuteProposal is Law {
    /// @notice Mapping from law hash to the governor contract address
    mapping(bytes32 lawHash => address governorContract) public governorContracts;

    /// @notice Constructor for GovernorExecuteProposal law
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

    /// @notice Build a call to execute a Governor proposal after validation
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
        if (governorContract == address(0)) revert("GovernorExecuteProposal: Governor contract not configured");

        // Decode proposal parameters
        (
            address[] memory proposalTargets,
            uint256[] memory proposalValues,
            bytes[] memory proposalCalldatas,
            string memory description
        ) = abi.decode(lawCalldata, (address[], uint256[], bytes[], string));

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
