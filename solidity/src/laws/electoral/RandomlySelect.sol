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

/// @notice This contract assigns accounts to roles by the tokens that they hold.
/// - At construction time, the following is set:
///    - the amount of role holders {N}
///    - the roleId {R} to be assigned
///    - the ERC20 token {T} address to be assessed.
///
/// - The contract is meant to be open (using PUBLIC_ROLE at SeperatedPowers protocol), but can also be role restricted.
///    - anyone can nominate themselves for the role.
///    - anyone can call the law to have it (re)assign accounts to the law.
///
/// - The logic:
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
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
// import { NominateMe } from "../state/NominateMe.sol";

// contract RandomlySelect is Law {
//     uint256 private immutable MAX_ROLE_HOLDERS;
//     uint256 private immutable ROLE_ID;
//     address private immutable nominees;
//     address[] public electedAccounts;

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint256 allowedRole_,
//         LawChecks memory config_,
//         uint256 maxRoleHolders_,
//         uint256 roleId_
//     )  {
//         MAX_ROLE_HOLDERS = maxRoleHolders_;
//         ROLE_ID = roleId_;
//         stateVars = abi.encode("address[]");
//     }

//     function handleRequest(address, /*caller*/ bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {
//         // setting up array for revoking & assigning roles.
//         address nominees = config.readStateFrom;  
//         uint256 numberNominees = NominateMe(nominees).nomineesCount();
//         uint256 numberRevokees = electedAccounts.length;
//         uint256 arrayLength =
//             numberNominees < MAX_ROLE_HOLDERS ? numberRevokees + numberNominees : numberRevokees + MAX_ROLE_HOLDERS;
//         address[] memory accountElects =
//             new address[](numberNominees < MAX_ROLE_HOLDERS ? numberNominees : MAX_ROLE_HOLDERS);

//         targets = new address[](arrayLength);
//         values = new uint256[](arrayLength);
//         calldatas = new bytes[](arrayLength);
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
//         } else {
//             uint256 pseudoRandomValue = uint256(keccak256(abi.encodePacked(block.number, nonce)));
//             // note: this is very inefficient, but I cannot add a getter function in NominateMe - so have to retrieve addresses one by one..
//             address[] memory _nomineesSorted = new address[](numberNominees);
//             for (uint256 i; i < numberNominees; i++) {
//                 _nomineesSorted[i] = NominateMe(nominees).nomineesSorted(i);
//             }
//             for (uint256 i; i < MAX_ROLE_HOLDERS; i++) {
//                 uint256 indexSelected = (pseudoRandomValue / 10 ** (i + 1)) % (numberNominees - i);
//                 address selectedNominee = _nomineesSorted[indexSelected];
//                 // creating call, assigning role, adding nominee to elected, and removing nominee from nominees list.
//                 calldatas[i] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, selectedNominee); // selector probably wrong. check later.
//                 accountElects[i] = selectedNominee;
//                 // note that we do not need to .pop the last item of the list, because it will never be accessed as the modulo decreases each run.
//                 _nomineesSorted[indexSelected] = _nomineesSorted[numberNominees - (i + 1)];
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
