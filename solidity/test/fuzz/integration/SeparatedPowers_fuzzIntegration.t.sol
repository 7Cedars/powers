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

    // function testFuzz_SeparatedPowers_ProposeVetoExecute(
    //     uint256 step0Chance,
    //     uint256 step1Chance,
    //     uint256 step2Chance,
    //     uint256 step3Chance
    // ) public {
    //     // Bound the chances to reasonable ranges
    //     step0Chance = bound(step0Chance, 30, 70);
    //     step1Chance = bound(step1Chance, 30, 70);
    //     step2Chance = bound(step2Chance, 30, 70);
    //     step3Chance = bound(step3Chance, 30, 70);

    //     uint256 balanceBefore = Erc20VotesMock(mockAddresses[2]).balanceOf(address(separatedPowers));
    //     uint256 seed = 9034273427;
    //     nonce = 423342432432; 

    //     bool[] memory stepsPassed = new bool[](4);

    //     // Setup initial roles
    //     vm.startPrank(address(separatedPowers));
    //     separatedPowers.assignRole(0, alice); // ADMIN ROLE
    //     separatedPowers.assignRole(1, bob); // USER ROLE
    //     separatedPowers.assignRole(2, charlotte); // HOLDER ROLE
    //     separatedPowers.assignRole(3, david); // DEVELOPER ROLE
    //     separatedPowers.assignRole(4, eve); // SUBSCRIBER ROLE
    //     vm.stopPrank();

    //     ////////////////////////////////////////
    //     console2.log("STEP 0: User proposal");
    //     ////////////////////////////////////////

    //     targets = new address[](1);
    //     values = new uint256[](1);
    //     calldatas = new bytes[](1);
    //     targets[0] = mockAddresses[2]; // ERC20VotesMock
    //     values[0] = 0;
    //     calldatas[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

    //     lawCalldata = abi.encode(targets, values, calldatas);
    //     description = "Propose minting 5000 tokens to the DAO";

    //     vm.prank(bob); // User role
    //     actionId = separatedPowers.propose(1, lawCalldata, nonce, description);

    //     (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
    //         payable(address(separatedPowers)),
    //         1,
    //         actionId,
    //         users,
    //         seed,
    //         step0Chance
    //     );

    //     // Check if proposal passed
    //     (, , conditions) = separatedPowers.getActiveLaw(1);
    //     quorumReached = (forVote + abstainVote) * 100 / roleCount > conditions.quorum;
    //     voteSucceeded = forVote * 100 / roleCount > conditions.succeedAt;
    //     stepsPassed[0] = quorumReached && voteSucceeded;
    //     vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution +  1);

    //     // Only continue if proposal passed
    //     console2.log("stepsPassed[0]", stepsPassed[0]);
    //     vm.assume(stepsPassed[0]);
    //     // Execute the proposal
    //     vm.prank(bob);
    //     separatedPowers.request(1, lawCalldata, nonce, description);
        
    //     ////////////////////////////////////////
    //     console2.log("STEP 1: Developer veto");
    //     ////////////////////////////////////////
    //     vm.prank(david); // Developer role
    //     actionId = separatedPowers.propose(2, lawCalldata, nonce, description);

    //     (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
    //         payable(address(separatedPowers)),
    //         2,
    //         actionId,
    //         users,
    //         seed,
    //         step1Chance
    //     );

    //     // Check if proposal passed
    //     (, , conditions) = separatedPowers.getActiveLaw(2);
    //     quorumReached = (forVote + abstainVote) * 100 / roleCount > conditions.quorum;
    //     voteSucceeded = forVote * 100 / roleCount > conditions.succeedAt;
    //     stepsPassed[1] = quorumReached && voteSucceeded;
    //     vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution +  1);

    //     if (stepsPassed[1]) {
    //         vm.prank(david); // Developer role
    //         separatedPowers.request(2, lawCalldata, nonce, "Developer veto");
    //     }
    //     // Only continue if veto has been implemented
    //     vm.assume(stepsPassed[1]);

    //     ////////////////////////////////////////
    //     console2.log("STEP 2: Subscriber veto");
    //     ////////////////////////////////////////
    //     vm.prank(eve); // Subscriber role
    //     actionId = separatedPowers.propose(3, lawCalldata, nonce, description);

    //     (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
    //         payable(address(separatedPowers)),
    //         3,
    //         actionId,
    //         users,
    //         seed,
    //         step2Chance
    //     );

    //     // Check if proposal passed
    //     (, , conditions) = separatedPowers.getActiveLaw(3);
    //     quorumReached = (forVote + abstainVote) * 100 / roleCount > conditions.quorum;
    //     voteSucceeded = forVote * 100 / roleCount > conditions.succeedAt;
    //     stepsPassed[2] = quorumReached && voteSucceeded;
    //     vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution +  1);

    //     // proposal passed, execute veto & stop. Otherwise, continue.
    //     if (stepsPassed[2]) {
    //         vm.prank(eve); // Subscriber role
    //         separatedPowers.request(3, lawCalldata, nonce, "Subscriber veto");
    //     }
    //     // Only continue if proposal passed
    //     vm.assume(!stepsPassed[2]);

    //     ////////////////////////////////////////
    //     console2.log("STEP 3: Holder execution");
    //     ////////////////////////////////////////
    //     vm.prank(charlotte); // Holder role
    //     actionId = separatedPowers.propose(4, lawCalldata, nonce, description);

    //     (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
    //         payable(address(separatedPowers)),
    //         4,
    //         actionId,
    //         users,
    //         seed,
    //         step3Chance
    //     );

    //     // Check if proposal passed
    //     (, , conditions) = separatedPowers.getActiveLaw(4);

    //     quorumReached = (forVote + abstainVote) * 100 / roleCount > conditions.quorum;
    //     voteSucceeded = forVote * 100 / roleCount > conditions.succeedAt;
    //     stepsPassed[3] = quorumReached && voteSucceeded;
    //     vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution +  1);

    //     // Only continue if proposal passed
    //     vm.assume(stepsPassed[3] && !stepsPassed[2] && !stepsPassed[1]);

    //     // Step 1: Developer veto
    //     vm.prank(charlotte); // Holder role
    //     separatedPowers.request(4, lawCalldata, nonce, "Holder execution");
    //     actionId = hashProposal(lawAddresses[4], lawCalldata, nonce);
    //     assertTrue(separatedPowers.state(actionId) == ActionState.Fulfilled);
    // }

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: ROLE MANAGEMENT                  //
    //////////////////////////////////////////////////////////////

    // function testFuzz_SeparatedPowers_RoleManagement(
    //     uint256 taxAmount,
    //     uint256 tokenAmount,
    //     uint256 subscriptionAmount
    // ) public {
    //     // Bound the amounts to reasonable ranges
    //     taxAmount = bound(taxAmount, 100, 1000); // 100-1000 gwei tax
    //     tokenAmount = bound(tokenAmount, 1e18, 10e18); // 1-10 tokens
    //     subscriptionAmount = bound(subscriptionAmount, 1000, 10000); // 1000-10000 gwei subscription

    //     // Test User role self-selection based on tax
    //     vm.startPrank(bob);
    //     Erc20TaxedMock(mockAddresses[3]).faucet();
    //     Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
    //     vm.stopPrank();

    //     vm.prank(bob);
    //     separatedPowers.request(5, abi.encode(), nonce, "Self-select as user");
    //     nonce++;

    //     assertTrue(separatedPowers.hasRoleSince(bob, 1) != 0, "Bob should have user role");

    //     // Test Holder role self-selection based on token holdings
    //     vm.startPrank(charlotte);
    //     Erc20VotesMock(mockAddresses[2]).mintVotes(tokenAmount);
    //     vm.stopPrank();

    //     vm.prank(charlotte);
    //     separatedPowers.request(6, abi.encode(), nonce, "Self-select as holder");
    //     nonce++;

    //     assertTrue(separatedPowers.hasRoleSince(charlotte, 2) != 0, "Charlotte should have holder role");

    //     // Test Subscriber role self-selection based on subscription
    //     vm.startPrank(eve);
    //     Erc20TaxedMock(mockAddresses[3]).faucet();
    //     Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
    //     vm.stopPrank();

    //     vm.prank(eve);
    //     separatedPowers.request(7, abi.encode(), nonce, "Self-select as subscriber");
    //     nonce++;

    //     assertTrue(separatedPowers.hasRoleSince(eve, 4) != 0, "Eve should have subscriber role");

    //     // Test Developer role management
    //     vm.startPrank(david); // Existing developer
    //     separatedPowers.request(8, abi.encode(frank), nonce, "Assign developer role");
    //     nonce++;
    //     vm.stopPrank();

    //     assertTrue(separatedPowers.hasRoleSince(frank, 3) != 0, "Frank should have developer role");
    // }

    // function testFuzz_SeparatedPowers_RoleRequirements(
    //     uint256 taxAmount,
    //     uint256 tokenAmount,
    //     uint256 subscriptionAmount
    // ) public {
    //     // Test insufficient tax payment for User role
    //     vm.startPrank(bob);
    //     Erc20TaxedMock(mockAddresses[3]).faucet();
    //     Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
    //     vm.stopPrank();

    //     vm.prank(bob);
    //     vm.expectRevert();
    //     separatedPowers.request(5, abi.encode(), nonce, "Self-select as user with insufficient tax");
    //     nonce++;

    //     // Test insufficient token holdings for Holder role
    //     vm.startPrank(charlotte);
    //     Erc20VotesMock(mockAddresses[2]).mintVotes(tokenAmount);
    //     vm.stopPrank();

    //     vm.prank(charlotte);
    //     vm.expectRevert();
    //     separatedPowers.request(6, abi.encode(), nonce, "Self-select as holder with insufficient tokens");
    //     nonce++;

    //     // Test insufficient subscription for Subscriber role
    //     vm.startPrank(eve);
    //     Erc20TaxedMock(mockAddresses[3]).faucet();
    //     Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
    //     vm.stopPrank();

    //     vm.prank(eve);
    //     vm.expectRevert();
    //     separatedPowers.request(7, abi.encode(), nonce, "Self-select as subscriber with insufficient subscription");
    //     nonce++;
    // }

    // function test_SeparatedPowers_AssignRoleLabels() public {
    //     // Setup initial roles
    //     vm.startPrank(address(separatedPowers));
    //     separatedPowers.assignRole(0, alice); // ADMIN ROLE
    //     vm.stopPrank();
    //     // I should make a fuzz test out of this
        
    //     vm.prank(alice);
    //     separatedPowers.request(9, abi.encode(), nonce, "Assign role labels");

    //     vm.expectRevert();
    //     separatedPowers.getActiveLaw(9);
    // }
} 