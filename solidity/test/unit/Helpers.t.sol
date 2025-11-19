// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { TreasurySimple } from "../../src/helpers/TreasurySimple.sol";
import { TreasuryPools } from "../../src/helpers/TreasuryPools.sol";
import { Erc20Taxed } from "../mocks/Erc20Taxed.sol";
import { TestSetupHelpers } from "../TestSetup.t.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TreasurySimpleTest is TestSetupHelpers {
    TreasurySimple treasury;
    Erc20Taxed erc20;

    function setUp() public override {
        super.setUp();
        treasury = TreasurySimple(payable(mockAddresses[11]));
        erc20 = Erc20Taxed(mockAddresses[1]); 

        vm.startPrank(address(daoMock));
        erc20.mint(1000 ether);
        erc20.transfer(alice, 500 ether);
        treasury.setWhitelistToken(address(erc20), true);
        vm.stopPrank();
    }

    function testDepositNative() public {
        vm.prank(alice);
        treasury.depositNative{value: 1 ether}();
        assertEq(address(treasury).balance, 1 ether);
        assertEq(treasury.transferCount(), 1);
        TreasurySimple.TransferLog memory log = treasury.getTransfer(1);
        (address from, address token, uint256 amount, uint256 blockNumber) = (log.from, log.token, log.amount, log.blockNumber);
        assertEq(from, alice);
        assertEq(token, address(0));
        assertEq(amount, 1 ether);
        assertEq(blockNumber, block.number);
    }

    function testDepositErc20() public {
        vm.startPrank(alice);
        erc20.approve(address(treasury), 100 ether);
        treasury.deposit(address(erc20), 100 ether);
        vm.stopPrank();

        assertEq(erc20.balanceOf(address(treasury)), 100 ether);
        assertEq(treasury.transferCount(), 1);
        TreasurySimple.TransferLog memory log = treasury.getTransfer(1); // transfer log starts at 1. 
        (address from, address token, uint256 amount, uint256 blockNumber) = (log.from, log.token, log.amount, log.blockNumber);
        assertEq(from, alice);
        assertEq(token, address(erc20));
        assertEq(amount, 100 ether);
        assertEq(blockNumber, block.number);
    }

    function testTransferNative() public {
        vm.prank(alice);
        treasury.depositNative{value: 1 ether}();

        vm.prank(treasury.owner());
        treasury.transfer(address(0), payable(bob), 0.5 ether);

        assertEq(address(treasury).balance, 0.5 ether);
        assertEq(bob.balance, 10.5 ether);
    }

    function testTransferErc20() public {
        vm.prank(treasury.owner());
        treasury.setWhitelistToken(address(erc20), true);
        vm.startPrank(alice);
        erc20.approve(address(treasury), 100 ether);
        treasury.deposit(address(erc20), 100 ether);
        vm.stopPrank();

        vm.prank(treasury.owner());
        treasury.transfer(address(erc20), payable(bob), 50 ether);

        assertEq(erc20.balanceOf(address(treasury)), 45 ether); // 10% tax on 50 Ether = 5 Ether. Total cost = 55 Ether; 45 should be left in treasury. 
        assertEq(erc20.balanceOf(bob), 50 ether); 
    }

    function testTransferRevertsIfNotOwner() public {
        vm.prank(alice);
        treasury.depositNative{value: 1 ether}();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        treasury.transfer(address(0), payable(charlotte), 0.5 ether);
    }

    function testGetBalance() public {
        vm.prank(alice);
        treasury.depositNative{value: 1 ether}();

        assertEq(treasury.getBalance(address(0)), 1 ether);

        vm.prank(treasury.owner());
        treasury.setWhitelistToken(address(erc20), true);
        vm.startPrank(alice);
        erc20.approve(address(treasury), 100 ether);
        treasury.deposit(address(erc20), 100 ether);
        vm.stopPrank();

        assertEq(treasury.getBalance(address(erc20)), 100 ether);
    }

    function testWhitelist() public {
        vm.prank(treasury.owner());
        treasury.setWhitelistToken(address(erc20), true);
        assertTrue(treasury.whitelistedTokens(address(erc20)));
    }

    function testDepositRevertsIfNotWhitelisted() public {
        vm.startPrank(alice);
        Erc20Taxed erc20New = new Erc20Taxed();
        erc20New.approve(address(treasury), 100 ether);
        vm.expectRevert("TOKEN_NOT_WHITELISTED");
        treasury.deposit(address(erc20New), 100 ether);
        vm.stopPrank();
    }
}

contract TreasuryPoolsTest is TestSetupHelpers {
    TreasuryPools treasury;
    Erc20Taxed erc20;

    function setUp() public override {
        super.setUp();
        treasury = TreasuryPools(payable(mockAddresses[12]));
        erc20 = Erc20Taxed(mockAddresses[1]);

        vm.startPrank(address(daoMock)); 
        erc20.mint(1000 ether);
        erc20.transfer(alice, 500 ether);
        treasury.setWhitelistToken(address(erc20), true);
        vm.stopPrank();

        vm.prank(alice);
        treasury.depositNative{value: 10 ether}();
        vm.startPrank(alice);
        erc20.approve(address(treasury), 100 ether);
        treasury.deposit(address(erc20), 100 ether);
        vm.stopPrank();
    }

    function testCreatePool() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(0), 1 ether);
        assertEq(treasury.poolCount(), 1);
        TreasuryPools.Pool memory pool = treasury.getPool(1);
        assertEq(pool.tokenAddress, address(0));
        assertEq(pool.budget, 1 ether); 
        assertEq(treasury.totalAllocatedBudgets(address(0)), 1 ether);
    }

    function testIncreaseBudget() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(0), 1 ether);
        vm.prank(treasury.owner());
        treasury.increaseBudget(1, 0.5 ether);
        TreasuryPools.Pool memory pool = treasury.getPool(1);
        assertEq(pool.budget, 1.5 ether);
        assertEq(treasury.totalAllocatedBudgets(address(0)), 1.5 ether);
    }

    function testDeletePool() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(0), 1 ether);
        vm.prank(treasury.owner());
        treasury.deletePool(1);
        TreasuryPools.Pool memory pool = treasury.getPool(1);
        assertEq(pool.tokenAddress, address(0));
        assertEq(pool.budget, 0); 
        assertEq(treasury.totalAllocatedBudgets(address(0)), 0);
    }

    function testTransferFromPool() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(0), 1 ether);
        vm.prank(treasury.owner());
        treasury.poolTransfer(1, payable(bob), 0.5 ether);
        TreasuryPools.Pool memory pool = treasury.getPool(1);
        assertEq(pool.budget, 0.5 ether);
        assertEq(bob.balance, 10.5 ether);
    }

    function testTransferFromErc20Pool() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(erc20), 50 ether);
        vm.prank(treasury.owner());
        treasury.poolTransfer(1, payable(bob), 20 ether);
        TreasuryPools.Pool memory pool = treasury.getPool(1);
        assertEq(pool.budget, 30 ether);
        assertEq(erc20.balanceOf(bob), 20 ether);
    }

    function testTransferRevertsIfAmountExceedsBudget() public {
        vm.prank(treasury.owner());
        treasury.createPool(address(0), 1 ether);
        vm.prank(treasury.owner());
        vm.expectRevert("Amount_exceeds_budget");
        treasury.poolTransfer(1, payable(bob), 1.5 ether);
    }
}
