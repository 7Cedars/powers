// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BaseSetup } from "../../TestSetup.t.sol";
import { RoleByTransaction } from "../../../src/laws/electoral/RoleByTransaction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";

contract RoleByTransactionTest is BaseSetup {
    RoleByTransaction roleByTransaction;
    Erc20Taxed token;
    address safeProxy;
    uint256 thresholdAmount = 100 ether;
    uint256 newRoleId = 4;

    function setUp() public override {
        super.setUp();
        roleByTransaction = RoleByTransaction(lawAddresses[21]);
        token = Erc20Taxed(mockAddresses[1]);
        safeProxy = makeAddr("safeProxy");

        // Give alice some tokens
        // token owner is daoMock in BaseSetup
        vm.startPrank(address(daoMock));
        token.mint(2000 ether); // Mint enough tokens to daoMock first
        token.transfer(alice, 1000 ether);
        vm.stopPrank();
    }

    function testRoleByTransactionExecution() public {
        // Adopt the law
        bytes memory config = abi.encode(address(token), thresholdAmount, newRoleId, safeProxy);
        conditions.allowedRole = type(uint256).max; // Public access

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Role By Transaction",
                targetLaw: address(roleByTransaction),
                config: config,
                conditions: conditions
            })
        );
        lawId = uint16(daoMock.lawCounter() - 1);

        // Alice approves RoleByTransaction contract to spend tokens
        // With the FIX, alice should approve RoleByTransaction.
        // Before the fix, RoleByTransaction tries to transfer from itself, so this test will fail appropriately.

        vm.startPrank(alice);
        token.approve(address(roleByTransaction), thresholdAmount);

        bytes memory callData = abi.encode(thresholdAmount);
        daoMock.request(lawId, callData, nonce, "Test role by transaction");
        vm.stopPrank();

        // Check balances
        // Note: Erc20Taxed has 10% tax. 10% of 100 ether = 10 ether. Total deduction = 110 ether.
        assertEq(token.balanceOf(alice), 1000 ether - thresholdAmount - 10 ether, "Alice balance incorrect");
        assertEq(token.balanceOf(safeProxy), thresholdAmount, "SafeProxy balance incorrect");

        // Check role
        assertTrue(daoMock.hasRoleSince(alice, newRoleId) > 0, "Role not assigned");
    }

    function testRoleByTransactionExecutionETH() public {
        // Adopt the law with token = address(0) (ETH)
        bytes memory config = abi.encode(address(0), thresholdAmount, newRoleId, safeProxy);
        conditions.allowedRole = type(uint256).max; // Public access

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Role By Transaction ETH",
                targetLaw: address(roleByTransaction),
                config: config,
                conditions: conditions
            })
        );
        lawId = uint16(daoMock.lawCounter() - 1);

        // Alice tries to request with ETH
        // Since Powers.request is not payable, she cannot send value.
        // But even if she could, Powers doesn't forward it.
        // Let's see if we can even send value to request (should fail at compilation if I try to attach value in solidity test, but let's try with .value() in foundry).

        vm.deal(alice, 1000 ether);
        bytes memory callData = abi.encode(thresholdAmount);

        vm.startPrank(alice);
        // We expect this to fail because RoleByTransaction tries to send ETH it doesn't have.
        vm.expectRevert("Transaction failed");
        daoMock.request(lawId, callData, nonce, "Test role by transaction ETH");
        vm.stopPrank();

        assertTrue(daoMock.hasRoleSince(alice, newRoleId) > 0, "Role not assigned");
    }
}
