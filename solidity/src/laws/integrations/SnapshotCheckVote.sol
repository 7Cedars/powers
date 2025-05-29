// // // SPDX-License-Identifier: MIT

// // ///////////////////////////////////////////////////////////////////////////////
// // /// This program is free software: you can redistribute it and/or modify    ///
// // /// it under the terms of the MIT Public License.                           ///
// // ///                                                                         ///
// // /// This is a Proof Of Concept and is not intended for production use.      ///
// // /// Tests are incomplete and it contracts have not been audited.            ///
// // ///                                                                         ///
// // /// It is distributed in the hope that it will be useful and insightful,    ///
// // /// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// // /// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
// // ///////////////////////////////////////////////////////////////////////////////

// // /// @notice A base contract that executes a bespoke action.
// // ///
// // /// Note 1: as of now, it only allows for a single function to be called.
// // /// Note 2: as of now, it does not allow sending of ether values to the target function.
// // ///
// // /// @author 7Cedars,

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { SnapshotOracleMock } from "../../../test/mocks/SnapshotOracleMock.sol";
// import { SnapshotRegisterProposal } from "./SnapshotRegisterProposal.sol";

// contract SnapshotCheckVote is Law {
//     struct SnapshotProposal {
//         bytes32 proposalId;
//         string forText;
//         string againstText;
//         string abstainText;
//         address[] targetsProposal;
//         uint256[] valuesProposal;
//         bytes[] calldatasProposal;
//     }

//     struct Mem {
//         uint16 snapshotRegisterProposalIndex;
//         address snapshotRegisterProposalAddress;
//     }

//     /// @notice constructor of the law
//     constructor() { 
//         // No config params, but NB! The SnapshotRegisterProposal should be set as readStateFrom. 
//         emit Law__Deployed("");
//     }

//     function initializeLaw(
//         uint16 index,
//         Conditions memory conditions,
//         bytes memory config,
//         bytes memory inputParams,
//         string memory description
//     ) public override {
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
//         inputParams = abi.encode("address[] Targets", "uint256[] Values", "bytes[] CallDatas");

//         super.initializeLaw(index, description, inputParams, conditions, config);
//     }

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

//         Mem memory mem_;

//         // Loading the data from the SnapshotRegisterProposal. 
//         ( , , , , address readStateFrom, , , , ) = laws[lawHash].conditions.readStateFrom;

//         if (readStateFrom != address(0)) {
//             revert("SnapshotRegisterProposal should be set as readStateFrom");
//         }
//         mem_.snapshotRegisterProposalIndex =  readStateFrom;
//         ( , , , , address[] memory targetsProposal, uint256[] memory valuesProposal, bytes[] memory calldatasProposal) = abi.decode(lawCalldata, (address[], uint256[], bytes[]));
//         (address snapshotRegisterProposalAddress, bytes32 snapshotRegisterProposalHash, ) =  Powers(powers).getActiveLaw(readStateFrom);
//         mem_.snapshotRegisterProposalAddress = snapshotRegisterProposalAddress;
//         mem_.snapshotRegisterProposalHash = snapshotRegisterProposalHash;

//         // call SnapshotRegisterProposal to check if the targets, values and calldatas are the same as in the proposal. 
//         (SnapshotProposal memory proposal) = SnapshotRegisterProposal(mem_.snapshotRegisterProposalAddress).getProposalData(actionId);

//         // check if the targets, values and calldatas are the same as in the proposal. 
//         for (uint256 i = 0; i < proposal.targetsProposal.length; i++) {
//             if (proposal.targetsProposal[i] != targetsProposal[i]) {
//                 revert("Targets are not the same");
//             }
//             if (proposal.valuesProposal[i] != valuesProposal[i]) {
//                 revert("Values are not the same");
//             }
//             if (proposal.calldatasProposal[i] != calldatasProposal[i]) {
//                 revert("Calldatas are not the same");
//             }
//         }
        
//         address snapshotVotesOracleAddress = SnapshotRegisterProposal(mem_.snapshotRegisterProposalAddress).getData(lawHash).snapshotOracle;
//         // if this check passes, we can proceed to check if the vote was successful. 
//         (bool success) = SnapshotOracleMock(snapshotVotesOracleAddress).request(proposal.proposalId);
//         if (!success) {
//             revert("Proposal not found");
//         }

//         // send empty calldata to the Powers contract so that the law will not be marked as fulfilled.
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(0);
//         return (actionId, targets, values, calldatas, "");
//     }

//     function callBackfromApi(bool success, uint256 actionId, SnapshotProposal memory proposal) public {
//         if (!success) {
//             revert( "Votes fetch not successful");
//         }
//         if (!proposal.voteClosed) {
//             revert("Vote still open");
//         }
//         if (proposal.forVotes > proposal.againstVotes && proposal.forVotes > proposal.abstainVotes) {
//             // send empty calldata to the Powers contract so that the law will be marked as fulfilled. .
//             (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = LawUtilities.createEmptyArrays(1);
//              _replyPowers(proposal.lawId, actionId, targets, values, calldatas); // this is where the law's logic is executed. I should check if call is successful. It will revert if not succesful, right?
//         } else {
//             revert("Proposal not successful");
//         }
//     }
// }
