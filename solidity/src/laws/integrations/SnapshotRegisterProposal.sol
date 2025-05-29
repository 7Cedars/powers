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

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { SnapshotOracleMock } from "../../../test/mocks/SnapshotOracleMock.sol";

// contract SnapshotRegisterProposal is Law {
//     /// the targets, values and calldatas to be used in the calls: set at construction.
//     struct SnapshotProposal {
//         bytes32 proposalId;
//         string forText;
//         string againstText;
//         string abstainText;
//         address[] targetsProposal;
//         uint256[] valuesProposal;
//         bytes[] calldatasProposal;
//         uint16 lawId;
//     }

//     struct Data {
//         string space;
//         address snapshotOracle;
//     }
    
//     mapping(bytes32 lawHash => Data) public data;
//     mapping(uint256 actionId => SnapshotProposal proposal) public snapshotProposal;

//     /// @notice constructor of the law.
//     constructor( ) { 
//         bytes memory configParams = abi.encode("string Space", "address SnapshotOracle");
//         emit Law__Deployed(configParams);
//     }

//     function initializeLaw(
//         uint16 index,
//         Conditions memory conditions,
//         bytes memory config,
//         bytes memory inputParams,
//         string memory description
//     ) public override {
//         (string memory space_, address snapshotOracle_) = abi.decode(config, (string, address));
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
//         data[lawHash] = Data(space_, snapshotOracle_);
        
//         inputParams = abi.encodePacked(
//             abi.encode(
//                 "bytes32 ProposalId", 
//                 "string ForText", 
//                 "string AgainstText", 
//                 "string AbstainText", 
//                 "address[] Targets", 
//                 "uint256[] Values", 
//                 "bytes[] CallDatas"
//                 )
//         );
//         super.initializeLaw(index, description, inputParams, conditions, config);
//     }

//     // @notice execute the law.
//     // @param lawCalldata the calldata _without function signature_ to send to the function.
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
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);

//         // no data is send to the Powers contract. This way the law will not be marked as fulfilled.
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(0);

//         (bytes32 proposalId, string memory forText, string memory againstText, string memory abstainText, address[] memory targetsProposal, uint256[] memory valuesProposal, bytes[] memory calldatasProposal) = abi.decode(lawCalldata, (bytes32, string, string, string, address[], uint256[], bytes[]));
//         // check if arrays are the same length. 
//         if (targetsProposal.length != valuesProposal.length || targetsProposal.length != calldatasProposal.length) {
//             revert("Targets, values and calldatas are not set correctly");
//         }

//         snapshotProposal[actionId] = SnapshotProposal(proposalId, forText, againstText, abstainText, targetsProposal, valuesProposal, calldatasProposal);
//         (bool success) = SnapshotOracleMock(data[lawHash].snapshotOracle).request(actionId, proposalId, forText, againstText, abstainText, targets, values, calldatas);
//         if (!success) {
//             revert("Proposal not found");
//         }
//         return (actionId, targets, values, calldatas, "");
//     }

//     function callBackfromApi(bool success, uint256 actionId, bytes32 proposalId, string[] memory options, bytes[] memory calldatas) public {
//         if (!success) {
//             revert( "Options do not match");
//         }
//         // send empty calldata to the Powers contract so that the law will be marked as fulfilled. .
//         (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = LawUtilities.createEmptyArrays(1);
//         uint16 lawId_ = snapshotProposal[actionId].lawId;

//         // cal the Powers contract to mark the law as fulfilled. 
//         _replyPowers(lawId_, actionId, targets, values, calldatas); // this is where the law's logic is executed. I should check if call is successful. It will revert if not succesful, right?
//     }

//     function getProposalData(uint256 actionId) public view returns (SnapshotProposal memory proposal) {
//         proposal = snapshotProposal[actionId];
//     }

//     function getData(bytes32 lawHash) public view returns (Data memory data_) {
//         data_ = data[lawHash];
//     }
// }
