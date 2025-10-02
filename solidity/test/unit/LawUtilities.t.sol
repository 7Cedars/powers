// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and contracts have not been extensively audited.   ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title LawUtilitiesTest - Unit tests for LawUtilities library
/// @notice Tests the LawUtilities library functions
/// @dev Provides comprehensive coverage of all LawUtilities functions
/// @author 7Cedars

pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Law } from "../../src/Law.sol";

import { SoulboundErc721 } from "@mocks/SoulboundErc721.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";

contract LawUtilitiesTest is TestSetupLaw {
    //////////////////////////////////////////////////////////////
    //                  STRING VALIDATION                       //
    //////////////////////////////////////////////////////////////
    function testCheckStringLengthAcceptsValidName() public pure {
        // Should not revert with valid name
        LawUtilities.checkStringLength("Valid Law Name", 1, 31);
    }

    function testCheckStringLengthRevertsWithEmptyName() public {
        // Should revert with empty name
        vm.expectRevert("String too short");
        LawUtilities.checkStringLength("", 1, 31);
    }

    function testCheckStringLengthRevertsWithTooLongName() public {
        // Should revert with name longer than 31 characters
        vm.expectRevert("String too long");
        LawUtilities.checkStringLength("ThisNameIsWaaaaaayTooLongForALawName", 1, 31);
    }

    //////////////////////////////////////////////////////////////
    //                  NFT CHECKS                               //
    //////////////////////////////////////////////////////////////
    function testNftCheckPassesWithValidToken() public {
        // Setup: Mint an NFT to alice
        vm.prank(address(daoMock));
        SoulboundErc721(mockAddresses[2]).mintNFT(1, alice);

        // Should not revert when alice owns an NFT
        LawUtilities.nftCheck(alice, mockAddresses[2]);
    }

    function testNftCheckRevertsWithoutToken() public {
        // Should revert when alice doesn't own any NFTs
        vm.expectRevert("Does not own token.");
        LawUtilities.nftCheck(alice, mockAddresses[2]);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE CHECKS                              //
    //////////////////////////////////////////////////////////////
    function testHasRoleCheckPassesWithValidRole() public view {
        uint32[] memory roles = new uint32[](1);
        roles[0] = uint32(ROLE_ONE);

        // Should not revert when alice has ROLE_ONE
        LawUtilities.hasRoleCheck(alice, roles, address(daoMock));
    }

    function testHasRoleCheckRevertsWithoutRole() public {
        uint32[] memory roles = new uint32[](1);
        roles[0] = uint32(ROLE_ONE);
        address userWithoutRole = makeAddr("userWithoutRole");

        // Should revert when user doesn't have the role
        vm.expectRevert("Does not have role.");
        LawUtilities.hasRoleCheck(userWithoutRole, roles, address(daoMock));
    }

    function testHasNotRoleCheckPassesWithoutRole() public {
        uint32[] memory roles = new uint32[](1);
        roles[0] = uint32(ROLE_THREE);
        address userWithoutRole = makeAddr("userWithoutRole");

        // Should not revert when user doesn't have the role
        LawUtilities.hasNotRoleCheck(userWithoutRole, roles, address(daoMock));
    }

    function testHasNotRoleCheckRevertsWithRole() public {
        uint32[] memory roles = new uint32[](1);
        roles[0] = uint32(ROLE_ONE);

        // Should revert when alice has the role
        vm.expectRevert("Has role.");
        LawUtilities.hasNotRoleCheck(alice, roles, address(daoMock));
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////////
    function testHashActionId() public {
        lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, lawCalldata, nonce))));
    }

    function testHashLaw() public {
        lawId = 1;
        lawHash = LawUtilities.hashLaw(address(daoMock), lawId);
        assertEq(lawHash, keccak256(abi.encode(address(daoMock), lawId)));
    }

    function testCreateEmptyArrays() public {
        uint256 length = 3;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);

        assertEq(targets.length, length);
        assertEq(values.length, length);
        assertEq(calldatas.length, length);
    }

    //////////////////////////////////////////////////////////////
    //                  ARRAY UTILITIES                         //
    //////////////////////////////////////////////////////////////

    function testArrayifyBoolsEmptyArrayPasses(uint256 numBools) public {
        numBools = bound(numBools, 0, 1000);
        // Test with zero booleans
        bool[] memory result = LawUtilities.arrayifyBools(numBools);

        assertEq(result.length, numBools);
    }

    function testArrayifyBoolsFailsWhenTooLarge(uint256 numBools) public {
        vm.assume(numBools > 1000);

        vm.expectRevert("Num bools too large");
        LawUtilities.arrayifyBools(numBools);
    }

    function testArrayifyBoolsAssemblyBehavior() public {
        // Test the assembly code's behavior with different input sizes
        for (i = 0; i <= 5; i++) {
            bool[] memory result = LawUtilities.arrayifyBools(i);
            assertEq(result.length, i);
        }
    }
}
