// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Powers } from "../../src/Powers.sol";
import { Erc20VotesMock } from "../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../mocks/Erc20TaxedMock.sol";
import { Erc721Mock } from "../mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../mocks/Erc1155Mock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20VotesMockTest is Test {
    Erc20VotesMock erc20VotesMock;

    function setUp() public {
        erc20VotesMock = new Erc20VotesMock();
    }

    function testDeploy_Erc20VotesMockTest() public {
        assertEq(erc20VotesMock.totalSupply(), 1 * 10 ** 18);
        assertEq(erc20VotesMock.name(), "mock");
        assertEq(erc20VotesMock.symbol(), "MOCK");
    }

    function testMintVotesRevertsWithZeroAmount() public {
        vm.expectRevert(Erc20VotesMock.Erc20VotesMock__NoZeroAmount.selector);
        erc20VotesMock.mintVotes(0);
    }

    function testMintVotesRevertsIfMaxAmountExceeded() public {
        uint256 maxAmount = 100 * 10 ** 18;

        vm.expectRevert(
            abi.encodeWithSelector(Erc20VotesMock.Erc20VotesMock__AmountExceedsMax.selector, maxAmount + 1, maxAmount)
        );
        erc20VotesMock.mintVotes(maxAmount + 1);
    }

    function testMint() public {
        //prep
        uint256 amountToMint = 50;
        address mockAddress = makeAddr("mock");
        uint256 amountBeforeMint = erc20VotesMock.balanceOf(mockAddress);

        // act
        vm.prank(mockAddress);
        erc20VotesMock.mintVotes(amountToMint);

        // assert
        uint256 amountAfterMint = erc20VotesMock.balanceOf(mockAddress);
        assertEq(amountBeforeMint, 0);
        assertEq(amountAfterMint, amountToMint);
    }
}

contract Erc20TaxedMockTest is Test {
    Erc20TaxedMock erc20TaxedMock;
    Powers daoMock;

    function setUp() public {
        uint256 taxRate_ = 10;
        uint8 DENOMINATOR_ = 100; // this should work out at 7 percent tax per transaction.
        uint48 epochDuration_ = 900;

        daoMock = new Powers("DAO", "");
        vm.prank(address(daoMock));
        erc20TaxedMock = new Erc20TaxedMock();
        uint256 balanceBefore = erc20TaxedMock.balanceOf(address(daoMock));

        vm.prank(address(daoMock));
        erc20TaxedMock.mint(10_000);

        assertEq(erc20TaxedMock.totalSupply(), 10_000 + balanceBefore);
        assertEq(erc20TaxedMock.balanceOf(address(daoMock)), 10_000 + balanceBefore);
        assertEq(erc20TaxedMock.taxRate(), taxRate_);
        assertEq(erc20TaxedMock.DENOMINATOR(), DENOMINATOR_);
        assertEq(erc20TaxedMock.epochDuration(), epochDuration_);
    }

    function testDeploy_Erc20TaxedMock() public {
        assertEq(erc20TaxedMock.name(), "mockTaxed");
        assertEq(erc20TaxedMock.symbol(), "MTXD");
    }

    function testMintRevertsWithZeroAmount() public {
        vm.expectRevert(Erc20TaxedMock.Erc20TaxedMock__NoZeroAmount.selector);
        vm.prank(address(daoMock));
        erc20TaxedMock.mint(0);
    }

    function testMintRevertsWithNonAuthorizedCall() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(123)));
        vm.prank(address(123));
        erc20TaxedMock.mint(123);
    }

    function testBurnRevertsWithZeroAmount() public {
        vm.expectRevert(Erc20TaxedMock.Erc20TaxedMock__NoZeroAmount.selector);
        vm.prank(address(daoMock));
        erc20TaxedMock.burn(0);
    }

    function testBurnRevertsWithNonAuthorizedCall() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(123)));
        vm.prank(address(123));
        erc20TaxedMock.burn(210);
    }

    function testChangeTaxRate() public {
        uint256 oldTaxRate = erc20TaxedMock.taxRate();
        uint8 denominator = erc20TaxedMock.DENOMINATOR();
        uint8 proposedTaxRate = denominator - 2;

        vm.prank(address(daoMock));
        erc20TaxedMock.changeTaxRate(proposedTaxRate);

        assertEq(erc20TaxedMock.taxRate(), proposedTaxRate);
    }

    function testChangeTaxRateOverflow() public {
        uint256 oldTaxRate = erc20TaxedMock.taxRate();
        uint8 DENOMINATOR = erc20TaxedMock.DENOMINATOR();
        uint256 proposedTaxRate = DENOMINATOR + 1;

        vm.expectRevert(Erc20TaxedMock.Erc20TaxedMock__TaxRateOverflow.selector);
        vm.prank(address(daoMock));
        erc20TaxedMock.changeTaxRate(proposedTaxRate);

        assertEq(erc20TaxedMock.taxRate(), oldTaxRate);
    }

    function testSuccessfulTaxCollection() public {
        // prep
        uint256 taxRate = erc20TaxedMock.taxRate();
        uint8 denominator = erc20TaxedMock.DENOMINATOR();

        uint256 transferAmount1 = 500;
        uint256 transferAmount2 = 250;
        uint256 taxAmount = (transferAmount2 * taxRate) / denominator;
        console.log(taxAmount);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 balanceDaoStep0 = erc20TaxedMock.balanceOf(address(daoMock));

        vm.prank(address(daoMock));
        erc20TaxedMock.transfer(alice, transferAmount1);
        uint256 balanceDaoStep1 = erc20TaxedMock.balanceOf(address(daoMock));
        // note: no taxes collected in transfer from dao to alice and bob.
        vm.assertEq(balanceDaoStep0, balanceDaoStep1 + transferAmount1);

        // act
        vm.prank(alice);
        erc20TaxedMock.transfer(bob, transferAmount2);
        vm.assertEq(erc20TaxedMock.balanceOf(bob), transferAmount2);
        vm.assertEq(erc20TaxedMock.balanceOf(alice), transferAmount1 - (transferAmount2 + taxAmount));
        vm.assertEq(erc20TaxedMock.balanceOf(address(daoMock)), balanceDaoStep1 + taxAmount);

        // assert state logs.
        uint256 loggedTaxPaid = erc20TaxedMock.getTaxLogs(uint48(block.number), alice);
        vm.assertEq(loggedTaxPaid, taxAmount);
    }

    function testTransferRevertsIfInsufficientBalanceForTax() public {
        // prep
        uint256 taxRate = erc20TaxedMock.taxRate();
        uint8 denominator = erc20TaxedMock.DENOMINATOR();

        uint256 transferAmount1 = 500;
        uint256 transferAmount2 = 500;
        uint256 taxAmount = (transferAmount2 * taxRate) / denominator;
        console.log(taxAmount);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 balanceDaoStep0 = erc20TaxedMock.balanceOf(address(daoMock));

        vm.prank(address(daoMock));
        erc20TaxedMock.transfer(alice, transferAmount1);
        uint256 balanceDaoStep1 = erc20TaxedMock.balanceOf(address(daoMock));
        // note: no taxes collected in transfer from dao to alice and bob.
        vm.assertEq(balanceDaoStep0, balanceDaoStep1 + transferAmount1);

        // act
        vm.expectRevert(Erc20TaxedMock.Erc20TaxedMock__InsufficientBalanceForTax.selector);
        vm.prank(alice);
        erc20TaxedMock.transfer(bob, transferAmount2);
    }
}

contract Erc721MockTest is Test {
    Erc721Mock erc721Mock;

    function setUp() public {
        erc721Mock = new Erc721Mock();
    }

    function testDeploy() public {
        assertEq(erc721Mock.name(), "mock");
        assertEq(erc721Mock.symbol(), "MOCK");
    }

    function testMintNFT() public {
        //prep
        uint256 NftToMint = 5;
        address mockAddress = makeAddr("mock");
        // check not owner before mint
        assertEq(erc721Mock.balanceOf(mockAddress), 0);

        // act
        vm.prank(mockAddress);
        erc721Mock.cheatMint(NftToMint);

        // assert owner after mint.
        assertEq(erc721Mock.balanceOf(mockAddress), 1);
        assertEq(erc721Mock.ownerOf(NftToMint), mockAddress);
    }
}

contract Erc1155MockTest is Test {
    Erc1155Mock erc1155Mock;

    function setUp() public {
        erc1155Mock = new Erc1155Mock();
    }

    function testDeploy() public {
        assertEq(
            erc1155Mock.uri(0),
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi"
        );
    }

    function testMintCoinsRevertsWithZeroAmount() public {
        vm.expectRevert(Erc1155Mock.Erc1155Mock__NoZeroAmount.selector);
        erc1155Mock.mintCoins(0);
    }

    function testMintVotesRevertsIfMaxAmountExceeded() public {
        uint256 maxAmount = 100 * 10 ** 18;

        vm.expectRevert(
            abi.encodeWithSelector(Erc1155Mock.Erc1155Mock__AmountExceedsMax.selector, maxAmount + 1, maxAmount)
        );
        erc1155Mock.mintCoins(maxAmount + 1);
    }

    function testMint() public {
        //prep
        uint256 amountToMint = 50;
        address mockAddress = makeAddr("MockAddress");
        uint256 amountBeforeMint = erc1155Mock.balanceOf(mockAddress, 0);

        // act
        vm.prank(mockAddress);
        erc1155Mock.mintCoins(amountToMint);

        // assert
        uint256 amountAfterMint = erc1155Mock.balanceOf(mockAddress, 0);
        assertEq(amountBeforeMint, 0);
        assertEq(amountAfterMint, amountToMint);
    }
}
