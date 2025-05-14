// // SPDX-License-Identifier: MIT

// ///////////////////////////////////////////////////////////////////////////////
// /// This program is free software: you can redistribute it and/or modify    ///
// /// it under the terms of the MIT Public License.                           ///
// ///                                                                         ///
// /// This is a Proof Of Concept and is not intended for production use.      ///
// /// Tests are incomplete and it contracts have not been audited.            ///
// ///                                                                         ///
// /// It is distributed in the hope that it will be useful and insightful,    ///
// /// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// /// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
// ///////////////////////////////////////////////////////////////////////////////

// /// @notice A base contract that executes a bespoke action.
// /// TBI: Basic logic sho
// ///
// /// @author 7Cedars,

pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// contract SnapshotCheckVote is Law {
//     /// the targets, values and calldatas to be used in the calls: set at construction.
//     mapping(bytes32 lawHash => string space) public snapshotSpace;

//     /// @notice constructor of the law
//     /// @param name_ the name of the law.
//     constructor(
//         // standard parameters
//         string memory name_
//     ) { 
//         LawUtilities.checkStringLength(name_, 1, 31);
//         name = name_;
//         bytes memory configParams = abi.encode("string Space", "string[] InputParams");

//         emit Law__Deployed(configParams);
//     }

//     function initializeLaw(
//         uint16 index,
//         Conditions memory conditions,
//         bytes memory config,
//         bytes memory inputParams,
//         string memory description
//     ) public override {
//         (address governorContract_, bytes memory inputParams_) =
//             abi.decode(config, (address, bytes));
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

//         governorContracts[lawHash] = governorContract_;
//         inputParams = abi.encode("string ProposalId", inputParams_);

//         super.initializeLaw(index, nameDescription, inputParams, conditions, config);//     }

//     /// @notice execute the law.
//     /// @param lawCalldata the calldata _without function signature_ to send to the function.
//     function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         override
//         returns (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         )
//     {
//         bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

//         string memory description = string.concat(
//             "This is a proposal created in the Powers protocol.\n",  
//             "To see the proposal, please visit: https://powers-protocol.vercel.app/",
//             Strings.toHexString(uint256(uint160(powers))), "/proposals/", Strings.toString(lawId)
//         );

//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(0);

//         uint256 proposalId = Governor(payable(governorContracts[lawHash])).getProposalId(targets, values, calldatas, keccak256(abi.encodePacked(description)));
//         if (proposalId == 0) {
//             revert("Proposal not found");
//         }
//         IGovernor.ProposalState state = Governor(payable(governorContracts[lawHash])).state(proposalId);
//         if (state != IGovernor.ProposalState.Succeeded) {
//             revert("Proposal not succeeded");
//         }

//         // send empty calldata to the Powers contract so that the law will be marked as fulfilled. .
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

//         return (actionId, targets, values, calldatas, "");
//     }
// }
