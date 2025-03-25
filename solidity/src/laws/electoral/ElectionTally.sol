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

// /// @notice This contract assigns accounts to roles by the tokens that have been delegated to them.
// /// - At construction time, the following is set:
// ///    - the maximum amount of accounts that can be assigned the role
// ///    - the roleId to be assigned
// ///    - the ERC20 token address to be assessed.
// ///    - the address from which to retrieve nominees.
// ///
// /// - The logic:
// ///    - The calldata holds the accounts that need to be _revoked_ from the role prior to the election.
// ///    - If fewer than N accounts are nominated, all will be assigne roleId R.
// ///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
// ///
// /// @dev The contract is an example of a law that
// /// - has does not need a proposal to be voted through. It can be called directly.
// /// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
// /// - doess not have to role restricted.
// /// - translates a simple token based voting system to separated powers.
// /// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { Powers} from "../../Powers.sol";
// import { ElectionVotes } from "../state/ElectionVotes.sol";
// import { NominateMe } from "../state/NominateMe.sol";
// import { ElectionVotes } from "../state/ElectionVotes.sol";
// import { ElectionCall } from "./ElectionCall.sol";
// import { LawUtilities } from "../../LawUtilities.sol";

// contract ElectionTally is Law { 
//     struct Data {
//         string description;
//         uint48 startVote;
//         uint48 endVote;
//         address electionVotes;
//         uint256 maxRoleHolders;
//         address nominees;
//         uint32 electedRoleId;
//     } 

//     mapping(bytes32 lawHash => address[] electedAccounts) public electedAccounts;
    
//     constructor(
//         string memory name_,
//         string memory description_
//     ) Law(name_) {

//         emit Law__Deployed(name_, description_, "");
//     }

//     function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
//         inputParams = abi.encode(
//             "uint48 StartVote", // startVote = the start date of the election.
//             "uint48 EndVote" // endVote = the end date of the election.
//         );

//         super.initializeLaw(index, conditions, config, inputParams);
//     }

//     function handleRequest(address /*caller*/, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {   
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        
//         address electionCall = Powers(payable(msg.sender)).getActiveLawAddress(conditionsLaws[lawHash].needCompleted);
//         bytes32 electionCallHash = LawUtilities.hashLaw(msg.sender, conditionsLaws[lawHash].needCompleted);

//         // saving the following in state vars to a struct avoid 'stack too deep' errors.
//         Data memory data;
        
//         // step 0a: unpacking calldata
//         (data.startVote, data.endVote) = abi.decode(lawCalldata, (uint48, uint48));
//         // step 0b: retrieving data from ElectionCall contract. 
//         data.electionVotes = ElectionCall(electionCall).electionVotes(electionCallHash);
//         data.maxRoleHolders = ElectionCall(electionCall).maxRoleHolders(electionCallHash);
//         data.electedRoleId = ElectionCall(electionCall).electedRoleId(electionCallHash);
//         ( , , , Conditions memory conditions) = ElectionCall(electionCall).initialisedLaws(electionCallHash);
//         data.nominees = conditionsLaws[lawHash].readStateFrom;
        
//         // step 1: run additional checks
//         if (!Powers(msg.sender).getActiveLaw(data.electionVotes)) {
//             revert ("ElectionVotes contract not recognised.");
//         }
//         if (NominateMe(data.nominees).nomineesCount(lawHash) == 0) {
//             revert ("No nominees.");
//         }
//         if (ElectionVotes(data.electionVotes).endVote(electionCallHash) > block.number) {
//             revert ("Election still active.");
//         }

//         // step 2: setting up array for revoking & assigning roles.
//         address[] memory accountElects;
//         uint256 numberNominees = NominateMe(data.nominees).nomineesCount(lawHash);
//         uint256 numberRevokees = electedAccounts[lawHash].length;
//         uint256 arrayLength =
//             numberNominees < data.maxRoleHolders ? numberRevokees + numberNominees + 1 : numberRevokees + data.maxRoleHolders + 1;

//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(arrayLength); 
//         for (uint256 i; i < arrayLength; i++) {
//             targets[i] = msg.sender;
//         }
//         // step 2: calls to revoke roles of previously elected accounts.
//         for (uint256 i; i < numberRevokees; i++) {
//             calldatas[i] = abi.encodeWithSelector(
//                 Powers.revokeRole.selector, 
//                 data.electedRoleId, 
//                 electedAccounts[i]
//             );
//         }
//         // deleting the election contract law. 
//         calldatas[arrayLength - 1] = abi.encodeWithSelector(
//                 Powers.revokeLaw.selector, 
//                 data.electionVotes
//             );

//         // step 3a: calls to add nominees if fewer than data.maxRoleHolders
//         if (numberNominees < data.maxRoleHolders) {
//             accountElects = new address[](numberNominees);
//             for (uint256 i; i < numberNominees; i++) {
//                 address accountElect = NominateMe(data.nominees).nomineesSorted(i);
//                 calldatas[i + numberRevokees] =
//                     abi.encodeWithSelector(
//                         Powers.assignRole.selector, 
//                         data.electedRoleId, 
//                         accountElect
                        
//                         );
//                 accountElects[i] = accountElect;
//             }

//             // step 3b: calls to add nominees if more than data.maxRoleHolders
//         } else {
//             // retrieve votes for delegates from ElectionVotes contract.
//             accountElects = new address[](data.maxRoleHolders);
//             uint256[] memory _votes = new uint256[](numberNominees);
//             address[] memory _nominees = new address[](numberNominees);
//             for (uint256 i; i < numberNominees; i++) {
//                 _nominees[i] = NominateMe(data.nominees).nomineesSorted(i);
//                 _votes[i] = ElectionVotes(data.electionVotes).votes(_nominees[i]);
//             }
//             // £todo: check what will happen if people have the same amount of delegated votes.
//             // note how the following mechanism works:
//             // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
//             // b. if the position is greater than data.maxRoleHolders, we break. (it means there are more accounts that have more tokens than data.maxRoleHolders)
//             // c. if the position is less than data.maxRoleHolders, we assign the roles.
//             uint256 index;
//             for (uint256 i; i < numberNominees; i++) {
//                 uint256 rank;
//                 // a: loop to assess ranking.
//                 for (uint256 j; j < numberNominees; j++) {
//                     if (j != i && _votes[j] >= _votes[i]) {
//                         rank++;
//                         if (rank > data.maxRoleHolders) break; // b: do not need to know rank beyond data.maxRoleHolders threshold.
//                     }
//                 }
//                 // c: assigning role if rank is less than data.maxRoleHolders.
//                 if (rank < data.maxRoleHolders && index < arrayLength - numberRevokees) {
//                     calldatas[index + numberRevokees] =
//                         abi.encodeWithSelector(
//                             Powers.assignRole.selector, 
//                             data.electedRoleId, 
//                             _nominees[i]);
//                     accountElects[index] = _nominees[i];
//                     index++;
//                 }
//             }
//         }
//         stateChange = abi.encode(accountElects);

//         return (actionId, targets, values, calldatas, stateChange);
//     }

//     function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
//         (address[] memory elected) = abi.decode(stateChange, (address[]));
//         delete electedAccounts[lawHash];
//         electedAccounts[lawHash] = elected;
//     }
// }
