// TODO
// link to nominateMe + ElectionVotes.
//
// - start election: input: token, startDate + duration. tole to designated + allowedRole are preset. It creates a ElectionVotes contract + assigns to Dao.
// - end election: read from peerVote Law + nominateMe to assign roles. First deleting roles first assigned. (very close to delegateSelect logic) + delete peerVote law from Dao.
// - NB, gotcha: only assign roles for people that nominated themselves at time of call the PeerElect law!
//

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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars
pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { Powers} from "../../Powers.sol";
// import { ElectionVotes } from "../state/ElectionVotes.sol";
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// contract ElectionCall is Law { 
//     uint32 public immutable VOTER_ROLE_ID;
//     uint32 public immutable ELECTED_ROLE_ID;
//     uint256 public immutable MAX_ROLE_HOLDERS;
//     address public electionVotes; 

//     event ElectionCall__ElectionDeployed(address electionVotes);

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint32 allowedRole_,
//         LawConfig memory config_,
//         // bespoke params
//         uint32 voterRoleId_, // who can vote in the election.
//         uint32 electedRoleId_, // what role Id is assigned through the elections 
//         uint256 maxElectedRoleHolders_ // how many people can be elected.
//     )  {
//         inputParams = abi.encode(
//             "string Description", // description = a description of the election.
//             "uint48 StartVote", // startVote = the start date of the election.
//             "uint48 EndVote" // endVote = the end date of the election.
//         );
//         stateVars = inputParams; // Note: stateVars == inputParams.
//         VOTER_ROLE_ID = voterRoleId_;
//         MAX_ROLE_HOLDERS = maxElectedRoleHolders_;
//         ELECTED_ROLE_ID = electedRoleId_;
//     }

//     /// @notice execute the law.
//     /// @param lawCalldata the calldata _without function signature_ to send to the function.
//     function handleRequest(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {        
//         // step 1: decode the law calldata.
//         (string memory description, uint48 startVote, uint48 endVote) =
//             abi.decode(lawCalldata, (string, uint48, uint48));

//         // step 2: calculate address at which grant will be created.
//         address nominees = config.readStateFrom;
//         if (nominees == address(0)) {
//             revert("Nominees contract not set at `config.readStateFrom`.");
//         }
//         address electionVotesAddress =
//             getElectionVotesAddress(VOTER_ROLE_ID, nominees, startVote, endVote, description);

//         // step 2: if address is already in use, revert.
//         uint256 codeSize = electionVotesAddress.code.length;
//         if (codeSize > 0) {
//             revert("Election Votes address already exists.");
//         }

//         // step 3: create arrays
//         targets = new address[](1);
//         values = new uint256[](1);
//         calldatas = new bytes[](1);
//         stateChange = abi.encode("");

//         // step 4: fill out arrays with data
//         targets[0] = powers;
//         calldatas[0] = abi.encodeWithSelector(Powers.adoptLaw.selector, electionVotesAddress);
//         stateChange = abi.encode(description, startVote, endVote, electionVotesAddress);

//         // step 5: return data
//         return (targets, values, calldatas, stateChange);
//     }

//     function _changeState(bytes memory stateChange) internal override {
//         // step 0: decode data from stateChange
//         (string memory description, uint48 startVote, uint48 endVote, address electionVotesAddress) =
//             abi.decode(stateChange, (string, uint48, uint48, address));

//         // stp 1: deploy new grant
//         electionVotes = electionVotesAddress;
//         _deployElectionVotes(VOTER_ROLE_ID, config.readStateFrom, startVote, endVote, description);
       
//     }

//     /**
//      * calculate the counterfactual address of this account as it would be returned by createAccount()
//      * exact copy from SimpleAccountFactory.sol
//      */
//     function getElectionVotesAddress(
//         uint32 allowedRole,
//         address nominees,
//         uint48 startVote,
//         uint48 endVote,
//         string memory description
//     ) public view returns (address) {
//         LawConfig memory config;
//         config.readStateFrom = nominees;

//         address electionVotesAddress = Create2.computeAddress(
//             bytes32(keccak256(abi.encodePacked(description))),
//             keccak256(
//                 abi.encodePacked(
//                     type(ElectionVotes).creationCode,
//                     abi.encode(
//                         // standard params
//                         "Election",
//                         description,
//                         powers,
//                         allowedRole,
//                         config,
//                         // remaining params
//                         startVote,
//                         endVote
//                     )
//                 )
//             )
//         );

//         return electionVotesAddress;
//     }

//     function _deployElectionVotes(
//         uint32 allowedRole,
//         address nominateMe,
//         uint48 startVote,
//         uint48 endVote,
//         string memory description
//     ) internal {
//         LawConfig memory config;
//         config.readStateFrom = nominateMe;

//         ElectionVotes newElectionVotes = new ElectionVotes{ salt: bytes32(keccak256(abi.encodePacked(description))) }(
//             // standard params
//             "Election",
//             description,
//             powers,
//             allowedRole,
//             config,
//             // remaining params
//             startVote,
//             endVote
//         );

//         emit ElectionCall__ElectionDeployed(address(newElectionVotes));
//     }
// }
