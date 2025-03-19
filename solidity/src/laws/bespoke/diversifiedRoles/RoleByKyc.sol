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

// import { SelfSelect } from "../../electoral/SelfSelect.sol";
// import { Members } from "./Members.sol";

// contract RoleByKyc is SelfSelect { 
//     uint16[] public nationalities;
//     uint16[] public countryOfResidences;
//     int64 public olderThan; // in seconds
//     int64 public youngerThan; // in seconds
//     address public members;

//     constructor(
//         // standard
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint256 allowedRole_,
//         LawChecks memory config_,
//         // self select
//         uint256 roleId_,
//         // filter
//         uint16[] memory nationalities_,
//         uint16[] memory countryOfResidences_,
//         int64 olderThan_, // in seconds
//         int64 youngerThan_, // in seconds
//         // members state law
//         address members_
//     ) SelfSelect(name_, description_, powers_, allowedRole_, config_, roleId_) {
//         nationalities = nationalities_;
//         countryOfResidences = countryOfResidences_;
//         olderThan = olderThan_;
//         youngerThan = youngerThan_;
//     }

//     function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {
//         // note that each initiates to 'false'.
//         bool nationalityOk;
//         bool residencyOk;
//         bool oldEnough;
//         bool youngEnough;
//         (uint16 nationality, uint16 countryOfResidence, int64 DoB) = Members(members).members(caller);

//         // step 0: check nationalities
//         if (nationalities.length > 0) {
//             for (uint256 i = 0; i < nationalities.length; i++) {
//                 if (nationality == nationalities[i]) {
//                     nationalityOk = true;
//                     break;
//                 }
//             }
//         } else {
//             nationalityOk = true;
//         }

//         // step 1: check country of residences
//         if (countryOfResidences.length > 0) {
//             for (uint256 i = 0; i < countryOfResidences.length; i++) {
//                 if (countryOfResidence == countryOfResidences[i]) {
//                     residencyOk = true;
//                     break;
//                 }
//             }
//         } else {
//             residencyOk = true;
//         }

//         // step 2: check if individual is old enough
//         if (olderThan > 0) {
//             if (uint64(DoB) < (uint64(block.timestamp) - uint64(olderThan))) oldEnough = true;
//         } else {
//             oldEnough = true;
//         }

//         // step 3: check if individual is young enough
//         if (youngerThan > 0) {
//             if (uint64(DoB) > (uint64(block.timestamp) - uint64(youngerThan))) youngEnough = true;
//         } else {
//             youngEnough = true;
//         }

//         // step 4: revert if any of the checks fail
//         if (!nationalityOk || !residencyOk || !oldEnough || !youngEnough) {
//             revert ("Not eligible."); 
//         }

//         // step 5: call super
//         return super.handleRequest(caller, lawCalldata, nonce);
//     }
// }
