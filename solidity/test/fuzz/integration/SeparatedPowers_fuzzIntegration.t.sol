// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import { Powers } from "../../../src/Powers.sol";
import { PowersEvents } from "../../../src/interfaces/PowersEvents.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { Erc20VotesMock } from "../../../test/mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../../test/mocks/Erc20TaxedMock.sol";

import { TestSetupSeparatedPowers } from "../../../test/TestSetup.t.sol";

contract SeparatedPowers_fuzzIntegrationTest is TestSetupSeparatedPowers {
    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////

    function testFuzz_SeparatedPowers_ProposeVetoExecute(
        uint256 step0Chance,
        uint256 step1Chance,
        uint256 step2Chance,
        uint256 step3Chance
    ) public {
        // Bound the chances to reasonable ranges
        step0Chance = bound(step0Chance, 0, 100);
        step1Chance = bound(step1Chance, 0, 100);
        step2Chance = bound(step2Chance, 0, 100);
        step3Chance = bound(step3Chance, 0, 100);

        uint256 balanceBefore = Erc20VotesMock(mockAddresses[2]).balanceOf(address(separatedPowers));
        uint256 seed = 9034273427;

        bool[] memory stepsPassed = new bool[](4);

        // Setup initial roles
        vm.startPrank(address(separatedPowers));
        separatedPowers.assignRole(0, alice); // ADMIN ROLE
        separatedPowers.assignRole(1, bob); // USER ROLE
        separatedPowers.assignRole(2, charlotte); // HOLDER ROLE
        separatedPowers.assignRole(3, david); // DEVELOPER ROLE
        separatedPowers.assignRole(4, eve); // SUBSCRIBER ROLE
        vm.stopPrank();

        // Step 0: User proposes an action
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = mockAddresses[2]; // ERC20VotesMock
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

        lawCalldata = abi.encode(targets, values, calldatas);
        description = "Propose minting 5000 tokens to the DAO";

        vm.prank(bob); // User role
        actionId = separatedPowers.propose(1, lawCalldata, nonce, description);
        nonce++;

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(separatedPowers)),
            1,
            actionId,
            users,
            seed,
            step0Chance
        );

        // Check if proposal passed
        (, , conditions) = separatedPowers.getActiveLaw(1);
        quorumReached = (forVote + abstainVote) * 100 / roleCount > conditions.quorum;
        voteSucceeded = forVote * 100 / roleCount > conditions.succeedAt;
        stepsPassed[0] = quorumReached && voteSucceeded;
        vm.roll(block.number + conditions.votingPeriod + 1);

        // Only continue if proposal passed
        vm.assume(stepsPassed[0]);

        console2.log("WAYPOINT 1");

        // Execute the proposal
        vm.prank(bob);
        separatedPowers.request(1, lawCalldata, nonce, description);
        nonce++;

        console2.log("WAYPOINT 2");

        // Step 1: Developer veto
        if (step1Chance > 50) {
            console2.log("WAYPOINT 3");
            vm.prank(david); // Developer role
            separatedPowers.request(2, lawCalldata, nonce, "Developer veto");

            actionId = hashProposal(lawAddresses[2], lawCalldata, nonce);
            uint8 vetoState = uint8(separatedPowers.state(actionId));
            stepsPassed[1] = vetoState != uint8(ActionState.Fulfilled);
            nonce++;
        } else {
            console2.log("WAYPOINT 4");
            stepsPassed[1] = true;
        }

        // Only continue if developer veto didn't pass
        vm.assume(stepsPassed[1]);

        console2.log("WAYPOINT 5");

        // Step 2: Subscriber veto
        if (step2Chance > 50) {
            console2.log("WAYPOINT 6");
            vm.prank(eve); // Subscriber role
            separatedPowers.request(3, lawCalldata, nonce, "Subscriber veto");
            
            actionId = hashProposal(lawAddresses[3], lawCalldata, nonce);
            uint8 vetoState = uint8(separatedPowers.state(actionId));
            stepsPassed[2] = vetoState != uint8(ActionState.Fulfilled);
            nonce++;
        } else {
            console2.log("WAYPOINT 7");
            stepsPassed[2] = true;
        }

        // Only continue if subscriber veto didn't pass
        vm.assume(stepsPassed[2]);

        // Step 3: Holder execution
        if (step3Chance > 50) {
            vm.prank(charlotte); // Holder role
            separatedPowers.request(4, lawCalldata, nonce, "Execute action");
            nonce++;
            
            uint256 balanceAfter = Erc20VotesMock(mockAddresses[2]).balanceOf(address(separatedPowers));
            stepsPassed[3] = balanceAfter == balanceBefore + 5000;
        } else {
            vm.expectRevert();
            vm.prank(charlotte);
            separatedPowers.request(4, lawCalldata, nonce, "Execute action");
            nonce++;
            stepsPassed[3] = true;
        }
    }

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: ROLE MANAGEMENT                  //
    //////////////////////////////////////////////////////////////

    function testFuzz_SeparatedPowers_RoleManagement(
        uint256 taxAmount,
        uint256 tokenAmount,
        uint256 subscriptionAmount
    ) public {
        // Bound the amounts to reasonable ranges
        taxAmount = bound(taxAmount, 100, 1000); // 100-1000 gwei tax
        tokenAmount = bound(tokenAmount, 1e18, 10e18); // 1-10 tokens
        subscriptionAmount = bound(subscriptionAmount, 1000, 10000); // 1000-10000 gwei subscription

        // Test User role self-selection based on tax
        vm.startPrank(bob);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
        vm.stopPrank();

        vm.prank(bob);
        separatedPowers.request(5, abi.encode(), nonce, "Self-select as user");
        nonce++;

        assertTrue(separatedPowers.hasRoleSince(bob, 1) != 0, "Bob should have user role");

        // Test Holder role self-selection based on token holdings
        vm.startPrank(charlotte);
        Erc20VotesMock(mockAddresses[2]).mintVotes(tokenAmount);
        vm.stopPrank();

        vm.prank(charlotte);
        separatedPowers.request(6, abi.encode(), nonce, "Self-select as holder");
        nonce++;

        assertTrue(separatedPowers.hasRoleSince(charlotte, 2) != 0, "Charlotte should have holder role");

        // Test Subscriber role self-selection based on subscription
        vm.startPrank(eve);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
        vm.stopPrank();

        vm.prank(eve);
        separatedPowers.request(7, abi.encode(), nonce, "Self-select as subscriber");
        nonce++;

        assertTrue(separatedPowers.hasRoleSince(eve, 4) != 0, "Eve should have subscriber role");

        // Test Developer role management
        vm.startPrank(david); // Existing developer
        separatedPowers.request(8, abi.encode(frank), nonce, "Assign developer role");
        nonce++;
        vm.stopPrank();

        assertTrue(separatedPowers.hasRoleSince(frank, 3) != 0, "Frank should have developer role");
    }

    function testFuzz_SeparatedPowers_RoleRequirements(
        uint256 taxAmount,
        uint256 tokenAmount,
        uint256 subscriptionAmount
    ) public {
        // Test insufficient tax payment for User role
        vm.startPrank(bob);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert();
        separatedPowers.request(5, abi.encode(), nonce, "Self-select as user with insufficient tax");
        nonce++;

        // Test insufficient token holdings for Holder role
        vm.startPrank(charlotte);
        Erc20VotesMock(mockAddresses[2]).mintVotes(tokenAmount);
        vm.stopPrank();

        vm.prank(charlotte);
        vm.expectRevert();
        separatedPowers.request(6, abi.encode(), nonce, "Self-select as holder with insufficient tokens");
        nonce++;

        // Test insufficient subscription for Subscriber role
        vm.startPrank(eve);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
        vm.stopPrank();

        vm.prank(eve);
        vm.expectRevert();
        separatedPowers.request(7, abi.encode(), nonce, "Self-select as subscriber with insufficient subscription");
        nonce++;
    }
} 