// SPDX-License-Identifier: MIT

//////////////////////////////////////////////////////////////////////////////
// This program is free software: you can redistribute it and/or modify    ///
// it under the terms of the MIT Public License.                           ///
//                                                                         ///
// This is a Proof Of Concept and is not intended for production use.      ///
// Tests are incomplete and it contracts have not been audited.            ///
//                                                                         ///
// It is distributed in the hope that it will be useful and insightful,    ///
// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                   ///
//////////////////////////////////////////////////////////////////////////////

// @notice A base contract that executes a bespoke action.
// TBI: Basic logic sho
//
// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { SnapshotRegisterProposal } from "../../../src/laws/integrations/SnapshotRegisterProposal.sol";

contract ChainlinkSnapshotApiMock {
    // /// the targets, values and calldatas to be used in the calls: set at construction.
    // mapping(bytes32 proposalId => string[] options) public snapshotProposal;

    // constructor() {
    //     snapshotProposal[bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)] = ["Option 1", "Option 2"];
    // }

    // function request(bytes32 proposalId, string[] memory options) public returns (bool success, bytes memory proposalId) {
    //     string[] memory proposal_ = snapshotProposal[proposalId];
    //     bool check = false;
    //     for (uint256 i = 0; i < proposal_.length; i++) {
    //         if (keccak256(abi.encodePacked(proposal_[i])) == keccak256(abi.encodePacked(options[i]))) {
    //             check = true;
    //         }
    //     }
    //     if (check) {
    //         return (true, proposalId);
    //     } else {
    //         return (false, bytes32(0x0000000000000000000000000000000000000000000000000000000000000000));
    //     }
    // }

    // function response(bytes32 proposalId, string[] memory options) public returns (bool success, bytes memory proposalId) {
    //     string[] memory proposal_ = snapshotProposal[proposalId];
    //     bool check = false;
    //     for (uint256 i = 0; i < proposal_.length; i++) {
    //         if (keccak256(abi.encodePacked(proposal_[i])) == keccak256(abi.encodePacked(options[i]))) {
    //             check = true;
    //         }
    //     }
    //     if (check) {
    //         return (true, proposalId);
    //     } else {
    //         return (false, bytes32(0x0000000000000000000000000000000000000000000000000000000000000000));
    //     }
    // }
}
