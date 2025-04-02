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

// // This is an integration for OpenZeppelin's Governor contract into the Powers protocol.
// // Note that it does not inherit Powers into Governor.sol, rather, it creates a dedicated roleId for the governor contract.
// // The reason for this is simple: in Governor.sol you vote with tokens, while in Powers you vote with roles. The two cannot be mixed.
// //
// // This module dedicates a single roleId to a governor contract.
// // It is possible to use the module with multiple governor contracts: creating a governance platform on which DAOs can interact on the basis of a shared set of laws.

// /// @title PowersToGovernor
// /// @notice A module that integrates the Powers protocol with the Governor contract.
// /// @author 7Cedars (https://github.com/7cedars)

// pragma solidity 0.8.26;

// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { Powers } from "../Powers.sol";

// contract PowersToGovernor is Powers {
//     error GovernorModule__InvalidGovernor();
//     error GovernorModule__GovernorNotAdded();
//     error GovernorModule__CannotSetGovernorRole();

//     // have a mapping for Governor contracts.
//     mapping(uint256 => bool) public governorIds;

//     event PowersToGovernor_GovernorAdded(address indexed governor, uint256 indexed governorRoleId);
//     event PowersToGovernor_GovernorRemoved(address indexed governor, uint256 indexed governorRoleId);

//     constructor(string memory name_, string memory uri_) Powers(name_, uri_) {}

//     /// @notice Add a governor to the governor role.
//     /// @param governor The address of the governor to add.
//     function addGovernor(address payable governor) public {
//         if (governor == address(0)) {
//             revert GovernorModule__InvalidGovernor();
//         }
//         uint256 governorRoleId = _hashGovernorRole(governor);

//         labelRole(governorRoleId, Governor(governor).name());
//         _setRole(governorRoleId, governor, true);
//         governorIds[governorRoleId] = true;
//         emit PowersToGovernor_GovernorAdded(governor, governorRoleId);
//     }

//     /// @notice Remove a governor from the governor role.
//     /// @param governor The address of the governor to remove.
//     function removeGovernor(address governor) public {
//         if (!governorIds[_hashGovernorRole(governor)]) {
//             revert GovernorModule__GovernorNotAdded();
//         }
//         uint256 governorRoleId = _hashGovernorRole(governor);
//         _setRole(governorRoleId, governor, false);
//         delete governorIds[governorRoleId];

//         emit PowersToGovernor_GovernorRemoved(governor, governorRoleId);
//     }

//     // override the setRole function to prevent setting the governor role.
//     function _setRole(uint256 roleId, address account, bool access) internal override {
//         if (governorIds[roleId]) {
//             revert GovernorModule__CannotSetGovernorRole();
//         }
//         super._setRole(roleId, account, access);
//     }

//     /// @notice Hash a governor address to a roleId.
//     /// @param governor The address of the governor to hash.
//     /// @return governorRoleId The roleId of the governor.
//     function _hashGovernorRole(address governor) internal view returns (uint256 governorRoleId) {
//         return uint256(keccak256(abi.encode(governor)));
//     }

// }
