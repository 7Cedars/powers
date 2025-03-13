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

// import { Law } from "../../../Law.sol";

// contract Members is Law {
//     // see for country codes IBAN: https://www.iban.com/country-codes
//     struct Member {
//         uint16 nationality;
//         uint16 countryOfResidence;
//         int64 dateOfBirth; // NB: can also go into minus for before 1970.  https://en.wikipedia.org/wiki/Unix_time#:~:text=A%20signed%2032%2Dbit%20value,Tuesday%202038%2D01%2D19.
//     }

//     mapping(address => Member) public members;

//     event Members__Added(address indexed account);
//     event Members__Removed(address indexed account);

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint32 allowedRole_,
//         LawConfig memory config_
//     )  {
//         inputParams = abi.encode(
//             "address Account", // account
//             "uint16 Nationality", // nationality
//             "uint16 Residency", // country of residence
//             "int64 DoB", // DoB
//             "bool Add" // add ? (if false: remove)
//         );
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
//         // step 0: decode law calldata
//         (address account,,,, bool add) = abi.decode(lawCalldata, (address, uint16, uint16, int64, bool));

//         // step 1: run additional checks
//         if (add && members[account].nationality != 0) {
//             revert ("Member already exists.");
//         }
//         if (!add && members[account].nationality == 0) {
//             revert ("Non existent member.");
//         }

//         // step 2: create arrays
//         targets = new address[](1);
//         values = new uint256[](1);
//         calldatas = new bytes[](1);
//         stateChange = abi.encode("");

//         // step 3: fill out arrays with data - no action should be taken by protocol.
//         targets[0] = address(1);
//         stateChange = lawCalldata;

//         // step 4: return data
//         return (targets, values, calldatas, stateChange);
//     }

//     // add or remove member from state mapping in law.
//     function _changeState(bytes memory stateChange) internal override {
//         (address account, uint16 nationality, uint16 countryOfResidence, int64 DoB, bool add) =
//             abi.decode(stateChange, (address, uint16, uint16, int64, bool));

//         if (add) {
//             members[account] = Member(nationality, countryOfResidence, DoB);
//             emit Members__Added(account);
//         } else {
//             members[account] = Member(0, 0, 0);
//             emit Members__Removed(account);
//         }
//     }
// }
