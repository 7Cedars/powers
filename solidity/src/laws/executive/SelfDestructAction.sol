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

// // laws
// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";

// contract SelfDestructAction is Law {
//     address[] public targets;
//     uint256[] public values;
//     bytes[] public calldatas;

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint256 allowedRole_,
//         LawUtilities.Conditions memory config_, 
//         address[] memory targets_,
//         uint256[] memory values_,
//         bytes[] memory calldatas_
//     ) Law(name_, powers_, allowedRole_, config_) { 
//         targets = targets_;
//         values = values_;
//         calldatas = calldatas_;

//         emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, ""); // empty params
//     }

//     function handleRequest(address /*caller*/, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         override
//         returns (uint256 actionId, address[] memory, uint256[] memory, bytes[] memory, bytes memory)
//     {
//         (
//             address[] memory targetsNew, 
//             uint256[] memory valuesNew, 
//             bytes[] memory calldatasNew
//             ) = LawUtilities.addSelfDestruct(targets, values, calldatas, powers);
        
//         actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);
//         return (actionId, targetsNew, valuesNew, calldatasNew, "");
//     }
// }
