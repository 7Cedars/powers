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

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ChainlinkSnapshotApiMock } from "../../../test/mocks/chainlinkSnapshotApiMock.sol";

contract SnapshotRegisterProposal is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    // struct SnapshotProposal {
    //     string[] options;
    //     bytes[] calldatas;
    // }

    // struct Data {
    //     string space;
    //     address snapshotOracle;
    // }
    
    // mapping(bytes32 lawHash => Data) public data;
    // mapping(bytes32 proposalId => SnapshotProposal proposal) public snapshotProposal;

    // /// @notice constructor of the law.
    // constructor( ) { 
    //     bytes memory configParams = abi.encode("string Space, address SnapshotOracle");
    //     emit Law__Deployed(configParams);
    // }

    // function initializeLaw(
    //     uint16 index,
    //     Conditions memory conditions,
    //     bytes memory config,
    //     bytes memory inputParams,
    //     string memory description
    // ) public override {
    //     (string memory space_, address snapshotOracle_) = abi.decode(config, (string, address));
    //     bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
    //     data[lawHash] = Data(space_, snapshotOracle_);
        
    //     inputParams = abi.encode("bytes32 ProposalId, string[] Options, bytes[] Calldatas");
    //     super.initializeLaw(index, description, inputParams, conditions, config);
    // }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    // function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
    //     public
    //     view
    //     override
    //     returns (
    //         uint256 actionId,
    //         address[] memory targets,
    //         uint256[] memory values,
    //         bytes[] memory calldatas,
    //         bytes memory stateChange
    //     )
    // {
    //     actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

    //     (targets, values, calldatas) = LawUtilities.createEmptyArrays(0);

    //     (bytes32 proposalId, string[] memory options, bytes[] memory calldatas) = abi.decode(lawCalldata, (bytes32, string[], bytes[]));
        
    //     (bool success) = ChainlinkSnapshotApiMock(data[lawHash].snapshotOracle).fakeApiCall(actionId, proposalId, options, calldatas);
    //     if (!success) {
    //         revert("Proposal not found");
    //     }
    //     return (actionId, targets, values, calldatas, "");
    // }

    // function callBackfromApi(bool success, uint256 actionId, bytes32 proposalId, string[] memory options, bytes[] memory calldatas) public {
    //     if (success) {
            
    //         if (proposalId == 0) {
    //             revert("Proposal not found");
    //         }
    //         IGovernor.ProposalState state = Governor(payable(governorContracts[lawHash])).state(proposalId);
    //         if (state != IGovernor.ProposalState.Succeeded) {
    //             revert("Proposal not succeeded");
    //         }

    //         // send empty calldata to the Powers contract so that the law will be marked as fulfilled. .
    //         (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = LawUtilities.createEmptyArrays(1);

    //         /// cal the Powers contract to mark the law as fulfilled. 
    //         Powers(payable(powers)).fulfill(lawId, actionId, targets, values, calldatas);
    //     }
    // }

}
