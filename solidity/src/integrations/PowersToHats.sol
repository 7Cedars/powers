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

// // The following code is a proof of concept for integration with the HatsModule.
// // It delegates all role assignment and revocation to the HatsModule.
// // The only roles that remain are the ADMIN_ROLE and PUBLIC_ROLE -- which are not used by the Hats Protocol.

// // todo: create tests and case study for this integration.

// // @dev: If this module is used, the HatsModule should be used to assign and revoke roles.
// // Note that means that laws should be role restricted along eligble roles, controlled by the Powers protocol.
// // @title HatsModule
// pragma solidity 0.8.26;

// import { Powers } from "../Powers.sol";
// import { Law } from "../Law.sol";
// // I had a lot of trouble importing the Hats contract, hence I use low level calls to the Hats contract.
// // This is not the best way to do it, but it works for now.

// contract PowersToHats is Powers {
//     error PowersToHats__NotAdmin(address caller, uint256 hatId);
//     error PowersToHats__CallFailed(address caller, uint256 hatId);
//     error PowersToHats__FunctionDisabled();
//     error PowersToHats__MintFailed();

//     address public immutable HATS_ADDRESS = 0x850f3384829D7bab6224D141AFeD9A559d745E3D; // Hats protocol address. It is the same across all deployed chains.

//     event PowerToHats__Initialised(uint256 topHatId);

//     constructor(string memory name_, string memory uri_, string memory details, string memory imageURI) Powers(name_, uri_) {
//         (bool success, bytes memory data) = HATS_ADDRESS.call(abi.encodeWithSignature("mintTopHat(address,string,string)", address(this), details, imageURI));
//         if (!success) {
//             revert PowersToHats__MintFailed();
//         }
//         uint256 topHatId = abi.decode(data, (uint256));

//         emit PowerToHats__Initialised(topHatId);
//     }

//     // @notice override _adoptLaw to check if law is role restricted along a role that is controlled by the Powers protocol.
//     function _adoptLaw(address law) internal override {
//         uint256 allowedRole = Law(law).allowedRole();
//         (bool success, bytes memory data) = HATS_ADDRESS.call(abi.encodeWithSignature("isAdminOfHat(address,uint256)", address(this), allowedRole));
//         if (!success) {
//             revert PowersToHats__NotAdmin(msg.sender, allowedRole);
//         }
//         bool isAdmin = abi.decode(data, (bool));
//         if (!isAdmin) {
//             revert PowersToHats__NotAdmin(msg.sender, allowedRole);
//         }
//         super._adoptLaw(law);
//     }

//     /// @dev override canCallLaw to check if caller has the correct hat to call the law
//     function canCallLaw(address caller, address targetLaw) public override view returns (bool) {
//         uint256 allowedRole = Law(targetLaw).allowedRole();
//         (bool success, bytes memory data) = HATS_ADDRESS.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", caller, allowedRole));
//         if (!success) {
//             revert PowersToHats__CallFailed(caller, allowedRole);
//         }
//         uint256 balance = abi.decode(data, (uint256));
//         return balance > 0 || allowedRole == PUBLIC_ROLE;
//     }

//     // @dev override _countMembersRole to count the number of members in a role using the Hats contract.
//     // Necessary for votes to work properly.
//     function _countMembersRole(uint256 roleId) internal view override returns (uint256 amountMembers) {
//         (bool success, bytes memory data) = HATS_ADDRESS.staticcall(abi.encodeWithSignature("viewHat(uint256)", roleId));
//         if (!success) {
//             revert PowersToHats__CallFailed(msg.sender, roleId);
//         }
//         ( , , uint32 memberAmount , , , , , , ) = abi.decode(data, (string, uint32, uint32, address, address, string, uint16, bool, bool));

//         return uint256(memberAmount);
//     }

//     /////////////////////////////////////////////////////////////////
//     //            DISABLED ROLE MANAGEMENT FUNCTIONS               //
//     // All role related function are handled by the Hats protocol. //
//     /////////////////////////////////////////////////////////////////
//     /// @dev disabled functions
//     function _setRole(uint256 roleId, address account, bool access) internal override {
//         revert PowersToHats__FunctionDisabled();
//     }

//     /// @dev disabled functions
//     function labelRole(uint256 roleId, string memory label) public override onlyPowers {
//         revert PowersToHats__FunctionDisabled();
//     }
// }
