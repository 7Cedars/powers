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
 
/// @title GovernorModule
pragma solidity 0.8.26;

import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

// contract GovernorModule is Governor {
//     // constructor(address token) Governor(token) {

//     // }

//     // function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description) public override returns (uint256) {
//     //     return super.propose(targets, values, calldatas, description);
//     // }

//     // function execute(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, uint256 nonce) public override returns (uint256) {
//     //     return super.execute(targets, values, calldatas, nonce);
//     // }

//     // function cancel(bytes32 proposalId) public override returns (bool) {
//     //     return super.cancel(proposalId);
//     // }

//     // function getVotes(address account, uint256 proposalId) public view override returns (uint256) {
//     //     return super.getVotes(account, proposalId);
//     // }

//     // function state(uint256 proposalId) public view override returns (ProposalState) {
//     //     return super.state(proposalId);
//     // }
// }

