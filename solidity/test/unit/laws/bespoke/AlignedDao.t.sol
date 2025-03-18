// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupAlignedDao } from "../../../TestSetup.t.sol";

// protocol
import { Powers } from "../../../../src/Powers.sol";
import { Law } from "../../../../src/Law.sol";
import { Erc721Mock } from "../../../mocks/Erc721Mock.sol";

// law contracts being tested
import { RevokeMembership } from "../../../../src/laws/bespoke/alignedDao/RevokeMembership.sol";
import { ReinstateRole } from "../../../../src/laws/bespoke/alignedDao/ReinstateRole.sol";
import { RequestPayment } from "../../../../src/laws/bespoke/alignedDao/RequestPayment.sol";
import { NftSelfSelect } from "../../../../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// openzeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NftSelfSelectTest is TestSetupAlignedDao {
    function testConstructorInitialization() public {
        address nftSelfSelect = laws[0];
        
        assertTrue(Powers(daoMock).getActiveLaw(nftSelfSelect), "Law should be active after initialization");
        assertEq(Law(nftSelfSelect).powers(), address(daoMock), "Powers address should be set correctly");
        assertEq(Law(nftSelfSelect).allowedRole(), type(uint32).max, "Allowed role should be PUBLIC_ROLE");
        assertEq(NftSelfSelect(nftSelfSelect).roleId(), 1, "Role ID should be set correctly");
        assertEq(NftSelfSelect(nftSelfSelect).erc721Token(), address(erc721Mock), "ERC721 token address should be set correctly");
    }

    function testSelfSelectSucceedsWithValidNft() public {
        address nftSelfSelect = laws[0];
        uint256 tokenId = 123;

        // Give alice an NFT
        vm.prank(alice);
        erc721Mock.cheatMint(tokenId);

        // Verify alice has NFT but not role
        assertEq(erc721Mock.balanceOf(alice), 1, "Alice should have 1 NFT");
        assertEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should not have role initially");

        // Execute self-select
        vm.prank(alice);
        Powers(daoMock).request(
            nftSelfSelect,
            abi.encode(false), // revoke = false
            nonce,
            "Self-selecting role with valid NFT"
        );

        // Verify role assignment
        assertNotEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should have role after self-select");
    }

    function testSelfSelectFailsWithoutNft() public {
        address nftSelfSelect = laws[0];

        // Verify alice has no NFT
        assertEq(erc721Mock.balanceOf(alice), 0, "Alice should have no NFTs");

        // Attempt self-select
        vm.prank(alice);
        vm.expectRevert("Does not own token.");
        Powers(daoMock).request(
            nftSelfSelect,
            abi.encode(false),
            nonce,
            "Attempting self-select without NFT"
        );

        // Verify no role assignment
        assertEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should not have role");
    }

    function testHandleRequestOutput() public {
        address nftSelfSelect = laws[0];
        bytes memory lawCalldata = abi.encode(false);
        

        // Give alice an NFT
        vm.prank(alice);
        erc721Mock.cheatMint(123);

        // Call handleRequest directly to check output
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        ) = Law(nftSelfSelect).handleRequest(alice, lawCalldata, nonce);

        // Verify outputs
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.assignRole.selector, 1, alice),
            "Calldata should be for role assignment"
        );
        assertEq(stateChange, "", "State change should be empty");
        assertTrue(actionId != 0, "Action ID should not be 0");
    }

    function testMultipleUsersCanSelfSelect() public {
        address nftSelfSelect = laws[0];
        address[] memory testUsers = new address[](3);
        testUsers[0] = alice;
        testUsers[1] = bob;
        testUsers[2] = charlotte;

        // Give NFTs and self-select for multiple users
        for (uint i = 0; i < testUsers.length; i++) {
            vm.prank(testUsers[i]);
            erc721Mock.cheatMint(i + 100);

            vm.prank(testUsers[i]);
            Powers(daoMock).request(
                nftSelfSelect,
                abi.encode(false),
                nonce,
                string(abi.encodePacked("Self-selecting role for user ", i))
            );
            nonce++;
            // Verify role assignment
            assertNotEq(daoMock.hasRoleSince(testUsers[i], 1), 0, "User should have role after self-select");
        }
    }
}

contract RevokeMembershipTest is TestSetupAlignedDao {
    function testConstructorInitialization() public {
        address revokeMembership = laws[1];
        
        assertTrue(Powers(daoMock).getActiveLaw(revokeMembership), "Law should be active after initialization");
        assertEq(Law(revokeMembership).powers(), address(daoMock), "Powers address should be set correctly");
        assertEq(Law(revokeMembership).allowedRole(), 1, "Allowed role should be ROLE_ONE");
        assertEq(RevokeMembership(revokeMembership).erc721Token(), address(erc721Mock), "ERC721 token address should be set correctly");
    }

    function testRevokeSucceedsWithValidNftHolder() public {
        address revokeMembership = laws[1];
        uint256 tokenId = 123;

        // Setup: Give alice an NFT and the role
        vm.prank(alice);
        erc721Mock.cheatMint(tokenId);
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, alice);

        // Verify initial state
        assertEq(erc721Mock.balanceOf(alice), 1, "Alice should have 1 NFT initially");
        assertNotEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should have role initially");

        // Give bob permission to revoke (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, bob);

        // Execute revocation
        vm.prank(bob);
        Powers(daoMock).request(
            revokeMembership,
            abi.encode(tokenId, alice),
            nonce,
            "Revoking alice's membership"
        );

        // Verify final state
        assertEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should not have role after revocation");
        assertEq(erc721Mock.balanceOf(alice), 0, "Alice should not have NFT after revocation");
    }

    function testRevokeFailsWithoutProperPermissions() public {
        address revokeMembership = laws[1];
        uint256 tokenId = 123;

        // Setup: Give alice an NFT and the role
        vm.prank(alice);
        erc721Mock.cheatMint(tokenId);
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, alice);

        // Attempt revocation without proper role (bob has no role)
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        Powers(daoMock).request(
            revokeMembership,
            abi.encode(tokenId, alice),
            nonce,
            "Attempting to revoke without permission"
        );

        // Verify state unchanged
        assertNotEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should still have role");
        assertEq(erc721Mock.balanceOf(alice), 1, "Alice should still have NFT");
    }

    function testRevokeFailsWithInvalidNftId() public {
        address revokeMembership = laws[1];
        uint256 tokenId = 123;
        uint256 wrongTokenId = 456;

        // Setup: Give alice an NFT and the role
        vm.prank(alice);
        erc721Mock.cheatMint(tokenId);
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, alice);

        // Give bob permission to revoke (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, bob);

        // Attempt revocation with wrong token ID
        vm.prank(bob);
        vm.expectRevert(); // NFT burn will fail
        Powers(daoMock).request(
            revokeMembership,
            abi.encode(wrongTokenId, alice),
            nonce,
            "Attempting to revoke with wrong token ID"
        );

        // Verify state unchanged
        assertNotEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should still have role");
        assertEq(erc721Mock.balanceOf(alice), 1, "Alice should still have NFT");
    }

    function testHandleRequestOutput() public {
        address revokeMembership = laws[1];
        uint256 tokenId = 123;
        bytes memory lawCalldata = abi.encode(tokenId, alice);
        

        // Call handleRequest directly to verify output format
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        ) = Law(revokeMembership).handleRequest(bob, lawCalldata, nonce);

        // Verify outputs
        assertEq(targets.length, 2, "Should have two targets");
        assertEq(values.length, 2, "Should have two values");
        assertEq(calldatas.length, 2, "Should have two calldatas");
        
        // First action: revoke role
        assertEq(targets[0], address(daoMock), "First target should be the DAO");
        assertEq(values[0], 0, "First value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.revokeRole.selector, 1, alice),
            "First calldata should be role revocation"
        );

        // Second action: burn NFT
        assertEq(targets[1], address(erc721Mock), "Second target should be the NFT contract");
        assertEq(values[1], 0, "Second value should be 0");
        assertEq(
            calldatas[1],
            abi.encodeWithSelector(Erc721Mock.burnNFT.selector, tokenId, alice),
            "Second calldata should be NFT burning"
        );

        assertEq(stateChange, "", "State change should be empty");
        assertTrue(actionId != 0, "Action ID should not be 0");
    }
}

contract ReinstateRoleTest is TestSetupAlignedDao {
    function testConstructorInitialization() public {
        address reinstateRole = laws[2];
        
        assertTrue(Powers(daoMock).getActiveLaw(reinstateRole), "Law should be active after initialization");
        assertEq(Law(reinstateRole).powers(), address(daoMock), "Powers address should be set correctly");
        assertEq(Law(reinstateRole).allowedRole(), 1, "Allowed role should be ROLE_ONE");
        assertEq(ReinstateRole(reinstateRole).erc721Token(), address(erc721Mock), "ERC721 token address should be set correctly");
    }

    function testReinstateSucceedsWithValidRevokedRole() public {
        address reinstateRole = laws[2];
        uint256 tokenId = 123;

        // Setup: Give bob permission to reinstate (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, bob);

        // Execute reinstatement
        vm.prank(bob);
        Powers(daoMock).request(
            reinstateRole,
            abi.encode(tokenId, alice),
            nonce,
            "Reinstating alice's membership"
        );

        // Verify final state
        assertNotEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should have role after reinstatement");
        assertEq(erc721Mock.balanceOf(alice), 1, "Alice should have NFT after reinstatement");
        assertEq(erc721Mock.ownerOf(tokenId), alice, "Alice should own the specific token");
    }

    function testReinstateFailsWithoutProperPermissions() public {
        address reinstateRole = laws[2];
        uint256 tokenId = 123;

        // Attempt reinstatement without proper role (bob has no role)
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        Powers(daoMock).request(
            reinstateRole,
            abi.encode(tokenId, alice),
            nonce,
            "Attempting to reinstate without permission"
        );

        // Verify state unchanged
        assertEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should not have role");
        assertEq(erc721Mock.balanceOf(alice), 0, "Alice should not have NFT");
    }

    function testReinstateFailsWithExistingToken() public {
        address reinstateRole = laws[2];
        uint256 tokenId = 123;

        // Setup: Give charlotte the token first
        vm.prank(charlotte);
        erc721Mock.cheatMint(tokenId);

        // Give bob permission to reinstate (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, bob);

        // Attempt reinstatement with already existing token
        vm.prank(bob);
        vm.expectRevert(); // NFT mint will fail
        Powers(daoMock).request(
            reinstateRole,
            abi.encode(tokenId, alice),
            nonce,
            "Attempting to reinstate with existing token"
        );

        // Verify state unchanged
        assertEq(daoMock.hasRoleSince(alice, 1), 0, "Alice should not have role");
        assertEq(erc721Mock.balanceOf(alice), 0, "Alice should not have NFT");
        assertEq(erc721Mock.ownerOf(tokenId), charlotte, "Charlotte should still own the token");
    }

    function testHandleRequestOutput() public {
        address reinstateRole = laws[2];
        uint256 tokenId = 123;
        bytes memory lawCalldata = abi.encode(tokenId, alice);
        

        // Call handleRequest directly to verify output format
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        ) = Law(reinstateRole).handleRequest(bob, lawCalldata, nonce);

        // Verify outputs
        assertEq(targets.length, 2, "Should have two targets");
        assertEq(values.length, 2, "Should have two values");
        assertEq(calldatas.length, 2, "Should have two calldatas");
        
        // First action: assign role
        assertEq(targets[0], address(daoMock), "First target should be the DAO");
        assertEq(values[0], 0, "First value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.assignRole.selector, 1, alice),
            "First calldata should be role assignment"
        );

        // Second action: mint NFT
        assertEq(targets[1], address(erc721Mock), "Second target should be the NFT contract");
        assertEq(values[1], 0, "Second value should be 0");
        assertEq(
            calldatas[1],
            abi.encodeWithSelector(Erc721Mock.mintNFT.selector, tokenId, alice),
            "Second calldata should be NFT minting"
        );

        assertEq(stateChange, "", "State change should be empty");
        assertTrue(actionId != 0, "Action ID should not be 0");
    }

    function testMultipleReinstatementsSucceed() public {
        address reinstateRole = laws[2];
        address[] memory testUsers = new address[](3);
        testUsers[0] = alice;
        testUsers[1] = charlotte;
        testUsers[2] = david;

        // Give bob permission to reinstate (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, bob);

        // Reinstate multiple users
        for (uint i = 0; i < testUsers.length; i++) {
            vm.prank(bob);
            Powers(daoMock).request(
                reinstateRole,
                abi.encode(i + 100, testUsers[i]),
                nonce,
                string(abi.encodePacked("Reinstating role for user ", i))
            );

            // Verify role and NFT assignment
            assertNotEq(daoMock.hasRoleSince(testUsers[i], 1), 0, "User should have role after reinstatement");
            assertEq(erc721Mock.balanceOf(testUsers[i]), 1, "User should have NFT after reinstatement");
            assertEq(erc721Mock.ownerOf(i + 100), testUsers[i], "User should own the specific token");
        }
    }
}

contract RequestPaymentTest is TestSetupAlignedDao {
    function testConstructorInitialization() public {
        address requestPayment = laws[3];
        
        assertTrue(Powers(daoMock).getActiveLaw(requestPayment), "Law should be active after initialization");
        assertEq(Law(requestPayment).powers(), address(daoMock), "Powers address should be set correctly");
        assertEq(Law(requestPayment).allowedRole(), 1, "Allowed role should be ROLE_ONE");
        assertEq(RequestPayment(requestPayment).erc1155(), address(erc20TaxedMock), "ERC1155 token address should be set correctly");
        assertEq(RequestPayment(requestPayment).amount(), 5000, "Payment amount should be set correctly");
        assertEq(RequestPayment(requestPayment).delay(), 100, "Delay should be set correctly");
    }

    function testRequestPaymentSucceedsAfterDelay() public {
        address requestPayment = laws[3];

        // Setup: Give alice permission to request payment (ROLE_ONE)
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, alice);

        // Move forward past the delay
        vm.roll(block.number + 101); // delay = 100

        // Initial balance check
        uint256 initialBalance = erc20TaxedMock.balanceOf(alice);

        // Execute payment request
        vm.prank(alice);
        Powers(daoMock).request(
            requestPayment,
            abi.encode(),
            nonce,
            "Requesting payment after delay"
        );

        // Verify final state
        assertEq(
            erc20TaxedMock.balanceOf(alice),
            initialBalance + 5000,
            "Alice should have received payment"
        );
    }

    function testRequestPaymentFailsWithoutProperPermissions() public {
        address requestPayment = laws[3];

        // Move forward past the delay
        vm.roll(block.number + 101);

        // Attempt payment request without proper role
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        Powers(daoMock).request(
            requestPayment,
            abi.encode(),
            nonce,
            "Attempting payment request without permission"
        );

        // Verify state unchanged
        assertEq(erc20TaxedMock.balanceOf(bob), 0, "Bob should not have received payment");
    }

    function testRequestPaymentFailsBeforeDelay() public {
        address requestPayment = laws[3];

        // Setup: Give alice permission to request payment
        vm.prank(address(daoMock));
        Powers(daoMock).assignRole(1, alice);

        // First payment request
        vm.roll(block.number + 101);
        vm.prank(alice);
        Powers(daoMock).request(
            requestPayment,
            abi.encode(),
            nonce,
            "First payment request"
        );

        // Second payment request before delay passes
        vm.roll(block.number + 10); // Less than required delay
        vm.prank(alice);
        vm.expectRevert(); // Should revert due to throttle check
        Powers(daoMock).request(
            requestPayment,
            abi.encode(),
            nonce,
            "Second payment request too soon"
        );
    }

    function testHandleRequestOutput() public {
        address requestPayment = laws[3];
        bytes memory lawCalldata = abi.encode();
        

        // Call handleRequest directly to verify output format
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        ) = Law(requestPayment).handleRequest(alice, lawCalldata, nonce);

        // Verify outputs
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        
        // Payment action
        assertEq(targets[0], address(erc20TaxedMock), "Target should be the token contract");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(ERC20.transfer.selector, alice, 5000),
            "Calldata should be token transfer"
        );

        // State change should contain initiator address for logging
        assertEq(
            abi.decode(stateChange, (address)),
            alice,
            "State change should contain initiator address"
        );
        assertTrue(actionId != 0, "Action ID should not be 0");
    }

    function testMultipleUsersCanRequestPayment() public {
        address requestPayment = laws[3];
        address[] memory testUsers = new address[](3);
        testUsers[0] = alice;
        testUsers[1] = bob;
        testUsers[2] = charlotte;

        // Give all users permission to request payment
        for (uint i = 0; i < testUsers.length; i++) {
            vm.prank(address(daoMock));
            Powers(daoMock).assignRole(1, testUsers[i]);
        }

        // Move forward past initial delay
        vm.roll(block.number + 101);

        // Each user requests payment
        for (uint i = 0; i < testUsers.length; i++) {
            uint256 initialBalance = erc20TaxedMock.balanceOf(testUsers[i]);
            
            vm.prank(testUsers[i]);
            Powers(daoMock).request(
                requestPayment,
                abi.encode(),
                nonce,
                string(abi.encodePacked("Payment request for user ", i))
            );
            nonce++;
            // Verify payment received and state updated
            assertEq(
                erc20TaxedMock.balanceOf(testUsers[i]),
                initialBalance + 5000,
                "User should have received payment"
            );

            // Move forward past delay for next user
            vm.roll(block.number + 101);
        }
    }
}
