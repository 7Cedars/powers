// // SPDX-License-Identifier: MIT

// //////////////////////////////////////////////////////////////////////////////
// // This program is free software: you can redistribute it and/or modify    ///
// // it under the terms of the MIT Public License.                           ///
// //                                                                         ///
// // This is a Proof Of Concept and is not intended for production use.      ///
// // Tests are incomplete and it contracts have not been audited.            ///
// //                                                                         ///
// // It is distributed in the hope that it will be useful and insightful,    ///
// // but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// //  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                   ///
// //////////////////////////////////////////////////////////////////////////////

// // @notice A base contract that executes a bespoke action.
// // TBI: Basic logic sho
// //
// // @author 7Cedars,

// pragma solidity 0.8.26;

// import { Law } from "../../src/Law.sol";
// import { LawUtilities } from "../../src/LawUtilities.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { SnapshotRegisterProposal } from "../../../src/laws/integrations/SnapshotRegisterProposal.sol";

// contract SnapshotOracleMock {
//     /// the targets, values and calldatas to be used in the calls: set at construction.
//     struct SnapshotProposal {
//         bytes32 proposalId;
//         string forText;
//         string againstText;
//         string abstainText;
//         uint256 forVotes;
//         uint256 againstVotes;
//         uint256 abstainVotes;
//         bool voteClosed;
//         address caller;
//     }

//     mapping(uint256 actionId => SnapshotProposal) public snapshotProposal;

//     SnapshotProposal placeholderProposal = SnapshotProposal(
//         "We will do this", 
//         "We will not do this", 
//         "We will abstain", 
//         500, 
//         300, 
//         200, 
//         true, 
//         address(0)
//         );

//     constructor() {}

//     function request(uint256 actionId) public returns (bool success) {
//         // calling the response function. 
//         snapshotProposal[actionId] = placeholderProposal;
//         snapshotProposal[actionId].caller = msg.sender;
//         (success, actionId) = response(actionId);
        
//         // as this is a fake implementation, we always true; 
//         return true;
//     }

//     function response(uint256 actionId) public returns (bool success, SnapshotProposal memory proposal) {
//         proposal = snapshotProposal[actionId];
//         bool check = false;

//         if (keccak256(abi.encodePacked(proposal.forText)) == keccak256(abi.encodePacked(proposal.forText))) {
//             check = true;
//         }
//         if (check) {
//             SnapshotRegisterProposal(proposal.caller).callBackfromApi(true, actionId, proposal.proposalId, proposal.forText, proposal.againstText, proposal.abstainText, proposal.forVotes, proposal.againstVotes, proposal.abstainVotes, proposal.voteClosed);
//             return (true, proposal);
//         } else {
//             return (false, bytes32(0x0000000000000000000000000000000000000000000000000000000000000000));
//         }
//     }
// }
