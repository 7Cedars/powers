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

/// @notice This contract assigns accounts to roles by the tokens that have been delegated to them.
/// - At construction time, the following is set:
///    - the maximum amount of accounts that can be assigned the role
///    - the roleId to be assigned
///    - the ERC20 token address to be assessed.
///    - the address from which to retrieve nominees.
///
/// - The logic:
///    - The calldata holds the accounts that need to be _revoked_ from the role prior to the election.
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
///
///
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { Powers} from "../../Powers.sol";
// import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
// import { NominateMe } from "../state/NominateMe.sol";

// contract DelegateSelect is Law {
//     address public immutable ERC_20_VOTE_TOKEN;
//     uint256 public immutable MAX_ROLE_HOLDERS;
//     uint32 public immutable ROLE_ID;
//     address[] public electedAccounts;

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint32 allowedRole_,
//         LawConfig memory config_,
//         address payable erc20Token_,
//         uint256 maxRoleHolders_,
//         uint32 roleId_
//     )  {
//         ERC_20_VOTE_TOKEN = erc20Token_; // £todo interface should be checked here.
//         MAX_ROLE_HOLDERS = maxRoleHolders_;
//         ROLE_ID = roleId_;
//         stateVars = abi.encode("address[]");
//     }

//     function handleRequest(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {   
//         // step 1: setting up array for revoking & assigning roles.
//         address nominees = config.readStateFrom;  
//         address[] memory accountElects;
//         uint256 numberNominees = NominateMe(nominees).nomineesCount();
//         uint256 numberRevokees = electedAccounts.length;
//         uint256 arrayLength =
//             numberNominees < MAX_ROLE_HOLDERS ? numberRevokees + numberNominees : numberRevokees + MAX_ROLE_HOLDERS;

//         targets = new address[](arrayLength);
//         values = new uint256[](arrayLength);
//         calldatas = new bytes[](arrayLength);
//         accountElects = new address[](numberNominees < MAX_ROLE_HOLDERS ? numberNominees : MAX_ROLE_HOLDERS);

//         for (uint256 i; i < arrayLength; i++) {
//             targets[i] = powers;
//         }

//         // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts.
//         for (uint256 i; i < numberRevokees; i++) {
//             calldatas[i] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, electedAccounts[i]);
//         }

//         // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
//         if (numberNominees < MAX_ROLE_HOLDERS) {
//             for (uint256 i; i < numberNominees; i++) {
//                 address accountElect = NominateMe(nominees).nomineesSorted(i);
//                 calldatas[i + numberRevokees] =
//                     abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, accountElect);
//                 accountElects[i] = accountElect;
//             }

//             // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
//         } else {
//             // retrieve balances of delegated votes of nominees.
//             uint256[] memory _votes = new uint256[](numberNominees);
//             address[] memory _nominees = new address[](numberNominees);
//             for (uint256 i; i < numberNominees; i++) {
//                 _nominees[i] = NominateMe(nominees).nomineesSorted(i);
//                 _votes[i] = ERC20Votes(ERC_20_VOTE_TOKEN).getVotes(_nominees[i]);
//             }
//             // £todo: check what will happen if people have the same amount of delegated votes.
//             // note how the following mechanism works:
//             // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
//             // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
//             // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
//             uint256 index;
//             for (uint256 i; i < numberNominees; i++) {
//                 uint256 rank;
//                 // a: loop to assess ranking.
//                 for (uint256 j; j < numberNominees; j++) {
//                     if (j != i && _votes[j] >= _votes[i]) {
//                         rank++;
//                         if (rank > MAX_ROLE_HOLDERS) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
//                     }
//                 }
//                 // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
//                 if (rank < MAX_ROLE_HOLDERS && index < arrayLength - numberRevokees) {
//                     calldatas[index + numberRevokees] =
//                         abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, _nominees[i]);
//                     accountElects[index] = _nominees[i];
//                     index++;
//                 }
//             }
//         }
//         stateChange = abi.encode(accountElects);
//     }

//     function _changeState(bytes memory stateChange) internal override {
//         (address[] memory elected) = abi.decode(stateChange, (address[]));
//         for (uint256 i; i < electedAccounts.length; i++) {
//             electedAccounts.pop();
//         }
//         electedAccounts = elected;
//     }
// }
