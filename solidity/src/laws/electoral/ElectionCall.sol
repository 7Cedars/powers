// // TODO
// // link to nominateMe + ElectionVotes.
// //
// // - start election: input: token, startDate + duration. tole to designated + allowedRole are preset. It creates a ElectionVotes contract + assigns to Dao.
// // - end election: read from peerVote Law + nominateMe to assign roles. First deleting roles first assigned. (very close to delegateSelect logic) + delete peerVote law from Dao.
// // - NB, gotcha: only assign roles for people that nominated themselves at time of call the PeerElect law!
// //

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

// /// @notice Natspecs are tbi. 
// ///
// /// @author 7Cedars
// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { Powers} from "../../Powers.sol";
// import { PowersTypes } from "../../interfaces/PowersTypes.sol";
// import { ElectionVotes } from "../state/ElectionVotes.sol";
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { LawUtilities } from "../../LawUtilities.sol";

// contract ElectionCall is Law { 
//     mapping(bytes32 lawHash => uint32 voterRoleId) public  voterRoleId; 
//     mapping(bytes32 lawHash => address electionVotes) public electionVotes;
//     mapping(bytes32 lawHash => uint256 maxRoleHolders) public maxRoleHolders;
//     mapping(bytes32 lawHash => uint32 electedRoleId) public electedRoleId;
//     constructor(
//         string memory name_,
//         string memory description_
//     ) Law(name_) {
//         bytes memory configParams = abi.encode(
//             "address electionVotes",
//             "uint32 voterRoleId",
//             "uint256 maxRoleHolders",
//             "uint32 electedRoleId"
//         );
//         emit Law__Deployed(name_, description_, configParams);
//     }

//     function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
//         (address electionVotes_, uint32 voterRoleId_, uint256 maxRoleHolders_, uint32 electedRoleId_) = abi.decode(config, (address, uint32, uint256, uint32));
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
//         electionVotes[lawHash] = electionVotes_;
//         voterRoleId[lawHash] = voterRoleId_;
//         maxRoleHolders[lawHash] = maxRoleHolders_;
//         electedRoleId[lawHash] = electedRoleId_;

//         inputParams = abi.encode(
//             "uint48 StartVote", // startVote = the start date of the election.
//             "uint48 EndVote" // endVote = the end date of the election.
//         );

//         super.initializeLaw(index, conditions, config, inputParams);
//     }

//     /// @notice execute the law.
//     /// @param lawCalldata the calldata _without function signature_ to send to the function.
//     function handleRequest(address /*caller*/, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {        
//         // step 0: get data.
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         (uint48 startVote, uint48 endVote) =
//             abi.decode(lawCalldata, (uint48, uint48));

//         // step 1: calculate address at which grant will be created.
//         address nominees = conditionsLaws[lawHash].readStateFrom;
//         if (nominees == address(0)) {
//             revert("Nominees contract not set at `conditions.readStateFrom`.");
//         }

//         // step 3: create arrays
//         Conditions memory conditionsLocal;
//         conditionsLocal.readStateFrom = nominees;
//         conditionsLocal.allowedRole = voterRoleId[lawHash];
        
//         PowersTypes.LawInitData memory lawInitData;
//         lawInitData.targetLaw = electionVotes[lawHash];
//         lawInitData.conditions = conditionsLocal;
//         lawInitData.config = abi.encode(startVote, endVote);
    
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
//         // step 4: fill out arrays with data
//         targets[0] = msg.sender;
//         calldatas[0] = abi.encodeWithSelector(Powers.adoptLaw.selector, lawInitData);
//         stateChange = abi.encode(startVote, endVote);

//         // step 5: return data
//         return (actionId, targets, values, calldatas, stateChange);
//     }

//     function getElectionVotes(bytes32 lawHash) public view returns (address) {
//         return electionVotes[lawHash];
//     }



// }
