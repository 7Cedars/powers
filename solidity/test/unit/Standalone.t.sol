// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { DelegateElection } from "../../src/standalone/DelegateElection.sol";
import { FlagActions } from "../../src/standalone/FlagActions.sol";
import { Grant } from "../../src/standalone/Grant.sol";
import { OpenElection } from "../../src/standalone/OpenElection.sol";
import { TestSetupPowers } from "../TestSetup.t.sol";
import { SimpleErc20Votes } from "../mocks/SimpleErc20Votes.sol";
import { ERC20Votes } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @notice Unit tests for helper contracts

//////////////////////////////////////////////////////////////
//               DELEGATE ELECTION TESTS                    //
//////////////////////////////////////////////////////////////
contract DelegateElectionTest is TestSetupPowers {
    DelegateElection delegateElection;
    SimpleErc20Votes token;

    function setUp() public override {
        super.setUp();
        token = SimpleErc20Votes(mockAddresses[0]);
        delegateElection = new DelegateElection(address(token), address(daoMock));
    }

    function testConstructor() public view {
        assertEq(address(delegateElection.owner()), address(daoMock));
    }

    function testConstructorRevertsWithZeroToken() public {
        vm.expectRevert("token required");
        new DelegateElection(address(0), address(daoMock));
    }

    function testNominate() public {
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);

        assertTrue(delegateElection.nominations(address(daoMock)));
        assertTrue(delegateElection.isNominee(address(daoMock)));
        assertEq(delegateElection.nomineesCount(), 1);
    }

    function testNominateRevertsWhenAlreadyNominated() public {
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);

        vm.expectRevert("already nominated");
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);
    }

    function testRevokeNomination() public {
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);

        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), false);

        assertFalse(delegateElection.nominations(address(daoMock)));
        assertFalse(delegateElection.isNominee(address(daoMock)));
        assertEq(delegateElection.nomineesCount(), 0);
    }

    function testRevokeNominationRevertsWhenNotNominated() public {
        vm.expectRevert("not nominated");
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), false);
    }

    function testNominateRevertsWhenNotCalledByOwner() public {
        vm.expectRevert();
        vm.prank(alice);
        delegateElection.nominate(alice, true);
    }

    function testGetNominees() public {
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);

        nominees = delegateElection.getNominees();
        assertEq(nominees.length, 1);
        assertEq(nominees[0], address(daoMock));
    }

    function testGetNomineeRanking() public {
        // Setup: Give tokens to users and delegate
        vm.prank(alice);
        token.mintVotes(1000);
        vm.prank(bob);
        token.mintVotes(2000);
        vm.prank(charlotte);
        token.mintVotes(500);
        
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);
        vm.prank(charlotte);
        token.delegate(charlotte);

        // Nominate users
        vm.prank(address(daoMock));
        delegateElection.nominate(address(daoMock), true);
        
        vm.prank(alice);
        vm.expectRevert();
        delegateElection.nominate(alice, true);

        // Test ranking
        (address[] memory nominees2, uint256[] memory votes) = delegateElection.getNomineeRanking();
        assertEq(nominees2.length, 1);
        assertEq(votes.length, 1);
        assertEq(nominees2[0], address(daoMock));
        assertEq(votes[0], 0); // daoMock has no delegated votes
    }

    function testNomineeRankingWithMultipleNominees() public {
        // Create a mock powers contract for testing
        address mockPowers = makeAddr("mockPowers");
        DelegateElection testElection = new DelegateElection(address(token), mockPowers);

        // Give tokens and delegate
        vm.prank(alice);
        token.mintVotes(1000);
        vm.prank(bob);
        token.mintVotes(2000);
        vm.prank(charlotte);
        token.mintVotes(500);
        
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);
        vm.prank(charlotte);
        token.delegate(charlotte);

        // Nominate multiple users
        vm.startPrank(mockPowers);
        testElection.nominate(alice, true);
        testElection.nominate(bob, true);
        vm.stopPrank(); 

        // Test with multiple nominees
        (address[] memory nominees2, uint256[] memory votes) = testElection.getNomineeRanking();
        assertEq(nominees2.length, 2);
        assertEq(votes.length, 2);
        assertEq(nominees2[0], bob); // bob has more votes (2000) than alice (1000)
        assertEq(nominees2[1], alice);
        assertEq(votes[0], 2000);
        assertEq(votes[1], 1000);
    }
}

//////////////////////////////////////////////////////////////
//               FLAG ACTIONS TESTS                        //
//////////////////////////////////////////////////////////////
contract FlagActionsTest is TestSetupPowers {
    FlagActions flagActions;

    function setUp() public override {
        super.setUp();
        flagActions = new FlagActions(address(daoMock));
    }

    function testConstructor() public view {
        assertEq(flagActions.owner(), address(daoMock));
    }

    function testConstructorRevertsWithZeroAddress() public {
        vm.expectRevert();
        new FlagActions(address(0));
    }

    function testFlag() public {
        actionId = 123;
        
        vm.prank(address(daoMock));
        flagActions.flag(actionId);

        assertTrue(flagActions.flaggedActions(actionId));
        assertTrue(flagActions.isActionIdFlagged(actionId));
    }

    function testFlagRevertsWhenAlreadyFlagged() public {
        actionId = 123;
        
        vm.prank(address(daoMock));
        flagActions.flag(actionId);

        vm.expectRevert("Already true");
        vm.prank(address(daoMock));
        flagActions.flag(actionId);
    }

    function testUnflag() public {
        actionId = 123;
        
        vm.prank(address(daoMock));
        flagActions.flag(actionId);

        vm.prank(address(daoMock));
        flagActions.unflag(actionId);

        assertFalse(flagActions.flaggedActions(actionId));
        assertFalse(flagActions.isActionIdFlagged(actionId));
    }

    function testUnflagRevertsWhenNotFlagged() public {
        actionId = 123;

        vm.expectRevert("Already false");
        vm.prank(address(daoMock));
        flagActions.unflag(actionId);
    }

    function testFlagRevertsWhenNotCalledByOwner() public {
        actionId = 123;

        vm.expectRevert();
        vm.prank(alice);
        flagActions.flag(actionId);
    }

    function testUnflagRevertsWhenNotCalledByOwner() public {
        actionId = 123;

        vm.expectRevert();
        vm.prank(alice);
        flagActions.unflag(actionId);
    }

    function testMultipleActions() public {
        uint256 actionId1 = 123;
        uint256 actionId2 = 456;
        uint256 actionId3 = 789;

        vm.startPrank(address(daoMock));
        flagActions.flag(actionId1);
        flagActions.flag(actionId2);
        flagActions.flag(actionId3);
        vm.stopPrank();

        assertTrue(flagActions.isActionIdFlagged(actionId1));
        assertTrue(flagActions.isActionIdFlagged(actionId2));
        assertTrue(flagActions.isActionIdFlagged(actionId3));

        vm.startPrank(address(daoMock));
        flagActions.unflag(actionId2);
        vm.stopPrank();

        assertTrue(flagActions.isActionIdFlagged(actionId1));
        assertFalse(flagActions.isActionIdFlagged(actionId2));
        assertTrue(flagActions.isActionIdFlagged(actionId3));
    }
}

//////////////////////////////////////////////////////////////
//               GRANT TESTS                               //
//////////////////////////////////////////////////////////////
contract GrantTest is TestSetupPowers {
    Grant grant;
    address testToken;

    function setUp() public override {
        super.setUp();
        grant = new Grant(address(daoMock));
        testToken = makeAddr("testToken");
    }

    function testConstructor() public view {
        assertEq(grant.owner(), address(daoMock));
    }

    function testConstructorRevertsWithZeroAddress() public {
        vm.expectRevert();
        new Grant(address(0));
    }

    function testUpdateNativeBudget() public {
        uint256 budget = 1000 ether;
        
        vm.prank(address(daoMock));
        grant.updateNativeBudget(budget);

        assertEq(grant.getNativeBudget(), budget);
        assertEq(grant.getRemainingNativeBudget(), budget);
    }

    function testUpdateTokenBudget() public {
        uint256 budget = 5000;
        
        vm.prank(address(daoMock));
        grant.updateTokenBudget(testToken, budget);

        assertEq(grant.getTokenBudget(testToken), budget);
        assertEq(grant.getRemainingTokenBudget(testToken), budget);
    }

    function testUpdateTokenBudgetRevertsWithZeroAddress() public {
        vm.expectRevert("Invalid token address");
        vm.prank(address(daoMock));
        grant.updateTokenBudget(address(0), 1000);
    }

    function testWhitelistToken() public {
        vm.prank(address(daoMock));
        grant.whitelistToken(testToken);

        assertTrue(grant.isTokenWhitelisted(testToken));
    }

    function testWhitelistTokenRevertsWithZeroAddress() public {
        vm.expectRevert("Invalid token address");
        vm.prank(address(daoMock));
        grant.whitelistToken(address(0));
    }

    function testDewhitelistToken() public {
        vm.prank(address(daoMock));
        grant.whitelistToken(testToken);

        vm.prank(address(daoMock));
        grant.dewhitelistToken(testToken);

        assertFalse(grant.isTokenWhitelisted(testToken));
    }

    function testSubmitProposal() public {
        // Setup: Whitelist token and set budget
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 5000);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 100 ether;
        milestoneAmounts[1] = 200 ether;
        tokens[0] = address(0); // Native
        tokens[1] = testToken;

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        assertEq(proposalId, 0);
        assertEq(grant.getProposalCount(), 1);
        
        Grant.Proposal memory proposal = grant.getProposal(proposalId);
        assertEq(proposal.proposer, tx.origin);
        assertEq(proposal.uri, uri);
        assertEq(proposal.milestoneBlocks.length, 2);
        assertEq(proposal.milestoneAmounts.length, 2);
        assertEq(proposal.tokens.length, 2);
        assertFalse(proposal.approved);
        assertFalse(proposal.rejected);
        assertEq(proposal.submissionBlock, block.number);
    }

    function testSubmitProposalRevertsWithInvalidData() public {
        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](0);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);

        vm.expectRevert("Invalid proposal");
        vm.prank(address(daoMock));
        grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);
    }

    function testSubmitProposalRevertsWithMismatchedArrays() public {
        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](2);

        vm.expectRevert("Invalid proposal");
        vm.prank(address(daoMock));
        grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);
    }

    function testSubmitProposalRevertsWithUnwhitelistedToken() public {
        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = testToken; // Not whitelisted

        vm.expectRevert("Token not whitelisted");
        vm.prank(address(daoMock));
        grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);
    }

    function testApproveProposal() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 5000);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        assertTrue(grant.isProposalApproved(proposalId));
        assertFalse(grant.isProposalRejected(proposalId));
    }

    function testRejectProposal() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 5000);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.rejectProposal(proposalId);

        assertFalse(grant.isProposalApproved(proposalId));
        assertTrue(grant.isProposalRejected(proposalId));
    }

    function testApproveProposalRevertsWhenNotFound() public {
        vm.expectRevert("Proposal not found");
        vm.prank(address(daoMock));
        grant.approveProposal(999);
    }

    function testApproveProposalRevertsWhenAlreadyProcessed() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        vm.expectRevert("Proposal already processed");
        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);
    }

    function testReleaseMilestone() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        // Fast forward to milestone block
        vm.roll(block.number + 101);

        vm.prank(address(daoMock));
        grant.releaseMilestone(proposalId, 0);

        Grant.Milestone memory milestone = grant.getMilestone(proposalId, 0);
        assertTrue(milestone.released);
        assertEq(grant.getTotalSpentNative(), 100 ether);
    }

    function testReleaseMilestoneRevertsWhenNotApproved() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.roll(block.number + 101);

        vm.expectRevert("Proposal not approved");
        vm.prank(address(daoMock));
        grant.releaseMilestone(proposalId, 0);
    }

    function testReleaseMilestoneRevertsWhenNotReached() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        vm.expectRevert("Milestone not reached");
        vm.prank(address(daoMock));
        grant.releaseMilestone(proposalId, 0);
    }

    function testReleaseMilestoneRevertsWhenInsufficientBudget() public {
        // Test the scenario where budget becomes insufficient between approval and release
        // This can happen if the budget is reduced after approval but before release
        
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(100 ether); // Sufficient budget for approval
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 50 ether; // Within budget at approval time
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        // Now reduce the budget to make it insufficient for release
        vm.prank(address(daoMock));
        grant.updateNativeBudget(30 ether); // Less than milestone amount

        vm.roll(block.number + 101);

        // This should fail at release due to insufficient budget
        vm.expectRevert("Insufficient budget");
        vm.prank(address(daoMock));
        grant.releaseMilestone(proposalId, 0);
    }

    function testCanReleaseMilestone() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](1);
        uint256[] memory milestoneAmounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneAmounts[0] = 100 ether;
        tokens[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        // Before milestone block
        assertFalse(grant.canReleaseMilestone(proposalId, 0));

        // After milestone block
        vm.roll(block.number + 101);
        assertTrue(grant.canReleaseMilestone(proposalId, 0));
    }

    function testGetProposalMilestones() public {
        // Setup proposal
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 100 ether;
        milestoneAmounts[1] = 200 ether;
        tokens[0] = address(0);
        tokens[1] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        Grant.Milestone[] memory milestones = grant.getProposalMilestones(proposalId);
        assertEq(milestones.length, 2);
        assertEq(milestones[0].blockNumber, block.number + 100);
        assertEq(milestones[1].blockNumber, block.number + 200);
    }

    function testGetBudgetStatus() public {
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 5000);
        vm.stopPrank();

        (
            uint256 nativeBudget,
            uint256 nativeSpent,
            uint256 nativeRemaining,
            address[] memory whitelistedTokensList,
            uint256[] memory tokenBudgets,
            uint256[] memory tokenSpent,
            uint256[] memory tokenRemaining
        ) = grant.getBudgetStatus();

        assertEq(nativeBudget, 1000 ether);
        assertEq(nativeSpent, 0);
        assertEq(nativeRemaining, 1000 ether);
        assertEq(whitelistedTokensList.length, 0);
        assertEq(tokenBudgets.length, 0);
        assertEq(tokenSpent.length, 0);
        assertEq(tokenRemaining.length, 0);
    }

    function testApproveProposalRevertsWithInsufficientNativeBudget() public {
        // Setup proposal with budget smaller than total proposal amount
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(50 ether); // Less than total proposal amount
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 30 ether; // Total: 30 + 40 = 70 ether
        milestoneAmounts[1] = 40 ether;
        tokens[0] = address(0); // Native
        tokens[1] = address(0); // Native

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.expectRevert("Insufficient native budget for proposal");
        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);
    }

    function testApproveProposalRevertsWithInsufficientTokenBudget() public {
        // Setup proposal with token budget smaller than total proposal amount
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 50); // Less than total proposal amount
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 30; // Total: 30 + 40 = 70 tokens
        milestoneAmounts[1] = 40;
        tokens[0] = testToken;
        tokens[1] = testToken;

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.expectRevert("Insufficient token budget for proposal");
        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);
    }

    function testApproveProposalSucceedsWithSufficientBudget() public {
        // Setup proposal with sufficient budget
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(100 ether);
        grant.updateTokenBudget(testToken, 100);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 30 ether; // Total: 30 + 40 = 70 ether
        milestoneAmounts[1] = 40 ether;
        tokens[0] = address(0); // Native
        tokens[1] = address(0); // Native

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        assertTrue(grant.isProposalApproved(proposalId));
    }

    function testApproveProposalSucceedsWithMixedTokenTypes() public {
        // Setup proposal with mixed native and token types
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.updateNativeBudget(100 ether);
        grant.updateTokenBudget(testToken, 100);
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](3);
        uint256[] memory milestoneAmounts = new uint256[](3);
        address[] memory tokens = new address[](3);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneBlocks[2] = block.number + 300;
        milestoneAmounts[0] = 30 ether; // Native
        milestoneAmounts[1] = 40; // Token
        milestoneAmounts[2] = 20 ether; // Native (total native: 50 ether, total token: 40)
        tokens[0] = address(0); // Native
        tokens[1] = testToken;
        tokens[2] = address(0); // Native

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);

        assertTrue(grant.isProposalApproved(proposalId));
    }

    function testApproveProposalRevertsWithMultipleTokenTypes() public {
        // Setup proposal with multiple token types where one exceeds budget
        address testToken2 = makeAddr("testToken2");
        
        vm.startPrank(address(daoMock));
        grant.whitelistToken(testToken);
        grant.whitelistToken(testToken2);
        grant.updateNativeBudget(1000 ether);
        grant.updateTokenBudget(testToken, 100);
        grant.updateTokenBudget(testToken2, 10); // Small budget for token2
        vm.stopPrank();

        string memory uri = "https://example.com/proposal";
        uint256[] memory milestoneBlocks = new uint256[](2);
        uint256[] memory milestoneAmounts = new uint256[](2);
        address[] memory tokens = new address[](2);
        
        milestoneBlocks[0] = block.number + 100;
        milestoneBlocks[1] = block.number + 200;
        milestoneAmounts[0] = 50; // Token1 - within budget
        milestoneAmounts[1] = 20; // Token2 - exceeds budget
        tokens[0] = testToken;
        tokens[1] = testToken2;

        vm.prank(address(daoMock));
        uint256 proposalId = grant.submitProposal(uri, milestoneBlocks, milestoneAmounts, tokens);

        vm.expectRevert("Insufficient token budget for proposal");
        vm.prank(address(daoMock));
        grant.approveProposal(proposalId);
    }

    function testApproveProposalRevertsWithAlreadySpentBudget() public {
        // Setup: First approve and release a milestone to spend some budget
        vm.startPrank(address(daoMock));
        grant.updateNativeBudget(100 ether);
        vm.stopPrank();

        // First proposal
        string memory uri1 = "https://example.com/proposal1";
        uint256[] memory milestoneBlocks1 = new uint256[](1);
        uint256[] memory milestoneAmounts1 = new uint256[](1);
        address[] memory tokens1 = new address[](1);
        
        milestoneBlocks1[0] = block.number + 100;
        milestoneAmounts1[0] = 60 ether;
        tokens1[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId1 = grant.submitProposal(uri1, milestoneBlocks1, milestoneAmounts1, tokens1);

        vm.prank(address(daoMock));
        grant.approveProposal(proposalId1);

        // Release the milestone to spend budget
        vm.roll(block.number + 101);
        vm.prank(address(daoMock));
        grant.releaseMilestone(proposalId1, 0);

        // Second proposal that would exceed remaining budget
        string memory uri2 = "https://example.com/proposal2";
        uint256[] memory milestoneBlocks2 = new uint256[](1);
        uint256[] memory milestoneAmounts2 = new uint256[](1);
        address[] memory tokens2 = new address[](1);
        
        milestoneBlocks2[0] = block.number + 200;
        milestoneAmounts2[0] = 50 ether; // Would exceed remaining 40 ether budget
        tokens2[0] = address(0);

        vm.prank(address(daoMock));
        uint256 proposalId2 = grant.submitProposal(uri2, milestoneBlocks2, milestoneAmounts2, tokens2);

        vm.expectRevert("Insufficient native budget for proposal");
        vm.prank(address(daoMock));
        grant.approveProposal(proposalId2);
    }

    function testAllFunctionsRevertWhenNotCalledByPowers() public {
        vm.expectRevert();
        vm.prank(alice);
        grant.updateNativeBudget(1000);

        vm.expectRevert();
        vm.prank(alice);
        grant.updateTokenBudget(testToken, 1000);

        vm.expectRevert();
        vm.prank(alice);
        grant.whitelistToken(testToken);

        vm.expectRevert();
        vm.prank(alice);
        grant.dewhitelistToken(testToken);

        vm.expectRevert();
        vm.prank(alice);
        grant.submitProposal("", new uint256[](0), new uint256[](0), new address[](0));

        vm.expectRevert();
        vm.prank(alice);
        grant.approveProposal(0);

        vm.expectRevert();
        vm.prank(alice);
        grant.rejectProposal(0);

        vm.expectRevert();
        vm.prank(alice);
        grant.releaseMilestone(0, 0);
    }
}

//////////////////////////////////////////////////////////////
//               OPEN ELECTION TESTS                       //
//////////////////////////////////////////////////////////////
contract OpenElectionTest is TestSetupPowers {
    OpenElection openElection;

    function setUp() public override {
        super.setUp();
        openElection = new OpenElection(address(daoMock));
    }

    function testConstructor() public view {
        assertEq(openElection.owner(), address(daoMock));
        assertEq(openElection.currentElectionId(), 0);
        assertEq(openElection.nomineesCount(), 0);
    }

    function testNominate() public {
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);

        assertTrue(openElection.nominations(address(daoMock)));
        assertTrue(openElection.isNominee(address(daoMock)));
        assertEq(openElection.nomineesCount(), 1);
    }

    function testNominateRevertsWhenAlreadyNominated() public {
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);

        vm.expectRevert("already nominated");
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);
    }

    function testRevokeNomination() public {
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);

        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), false);

        assertFalse(openElection.nominations(address(daoMock)));
        assertFalse(openElection.isNominee(address(daoMock)));
        assertEq(openElection.nomineesCount(), 0);
    }

    function testRevokeNominationRevertsWhenNotNominated() public {
        vm.expectRevert("not nominated");
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), false);
    }

    function testNominateRevertsWhenNotCalledByPowers() public {
        vm.expectRevert();
        vm.prank(alice);
        openElection.nominate(alice, true);
    }

    function testGetNominees() public {
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);

        nominees = openElection.getNominees();
        assertEq(nominees.length, 1);
        assertEq(nominees[0], address(daoMock));
    }

    function testOpenElection() public {
        uint256 durationBlocks = 100;
        
        vm.prank(address(daoMock));
        openElection.openElection(durationBlocks);

        OpenElection.ElectionData memory election = openElection.getElectionInfo();
        assertTrue(election.isOpen);
        assertEq(election.startBlock, block.number);
        assertEq(election.durationBlocks, durationBlocks);
        assertEq(election.endBlock, block.number + durationBlocks);
        assertTrue(openElection.isElectionOpen());
    }

    function testOpenElectionRevertsWhenAlreadyOpen() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert("election already open");
        vm.prank(address(daoMock));
        openElection.openElection(200);
    }

    function testOpenElectionRevertsWithZeroDuration() public {
        vm.expectRevert("duration must be > 0");
        vm.prank(address(daoMock));
        openElection.openElection(0);
    }

    function testOpenElectionRevertsWhenNotCalledByPowers() public {
        vm.expectRevert();
        vm.prank(alice);
        openElection.openElection(100);
    }

    function testVote() public {
        // Setup: Nominate and open election
        vm.startPrank(address(daoMock));
        openElection.nominate(address(daoMock), true);
        openElection.openElection(100);
        vm.stopPrank();

        vm.prank(address(daoMock));
        openElection.vote(address(daoMock), address(daoMock));

        assertTrue(openElection.hasUserVoted(address(daoMock), 1));
        assertEq(openElection.getVoteCount(address(daoMock), 1), 1);
    }

    function testVoteRevertsWhenElectionNotOpen() public {
        vm.expectRevert("election not open");
        vm.prank(address(daoMock));
        openElection.vote(address(daoMock), address(daoMock));
    }

    function testVoteRevertsWhenElectionClosed() public {
        // Setup: Open election and fast forward past end
        vm.prank(address(daoMock));
        openElection.openElection(100);
        
        vm.roll(block.number + 101);

        vm.expectRevert("election closed");
        vm.prank(address(daoMock));
        openElection.vote(address(daoMock), address(daoMock));
    }

    function testVoteRevertsWhenNomineeNotNominated() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert("nominee not nominated");
        vm.prank(address(daoMock));
        openElection.vote(address(daoMock), alice);
    }

    function testVoteRevertsWhenAlreadyVoted() public {
        // Setup: Nominate and open election
        vm.startPrank(address(daoMock));
        openElection.nominate(address(daoMock), true);
        openElection.openElection(100);
        openElection.vote(address(daoMock), address(daoMock));
        vm.stopPrank();

        vm.expectRevert("already voted");
        vm.prank(address(daoMock));
        openElection.vote(address(daoMock), address(daoMock));
    }

    function testVoteRevertsWhenNotCalledByPowers() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert();
        vm.prank(alice);
        openElection.vote(alice, address(daoMock));
    }

    function testCloseElection() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.roll(block.number + 101); 

        vm.prank(address(daoMock));
        openElection.closeElection();

        OpenElection.ElectionData memory election = openElection.getElectionInfo();
        assertFalse(election.isOpen);
        assertFalse(openElection.isElectionOpen());
    }

    function testCloseElectionRevertsWhenNotOpen() public {
        vm.expectRevert("election not open");
        vm.prank(address(daoMock));
        openElection.closeElection();
    }

    function testCloseElectionRevertsWhenStillActive() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert("election still active");
        vm.prank(address(daoMock));
        openElection.closeElection();
    }

    function testCloseElectionRevertsWhenNotCalledByPowers() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert();
        vm.prank(alice);
        openElection.closeElection();
    }

    function testTallyElection() public {
        // Setup: Nominate, open election, vote, and close
        vm.startPrank(address(daoMock));
        openElection.nominate(address(daoMock), true);
        openElection.openElection(100);
        openElection.vote(address(daoMock), address(daoMock));
        vm.stopPrank();

        vm.roll(block.number + 101);

        (address[] memory nominees2, uint256[] memory votes) = openElection.getNomineeRanking();
        assertEq(nominees2.length, 1);
        assertEq(votes.length, 1);
        assertEq(nominees2[0], address(daoMock));
        assertEq(votes[0], 1);
    }

    function testRankingRevertsWhenStillActive() public {
        vm.prank(address(daoMock));
        openElection.openElection(100);

        vm.expectRevert("election still active");
        openElection.getNomineeRanking();
    }

    function testGetNomineeRanking() public {
        // Setup: Create multiple nominees and votes
        address nominee1 = makeAddr("nominee1");
        address nominee2 = makeAddr("nominee2");
        
        // We need to simulate the nomination process by directly calling the contract
        // Since we can't easily create multiple nominees with the current setup,
        // we'll test the basic functionality
        vm.startPrank(address(daoMock));
        openElection.nominate(nominee1, true);
        openElection.nominate(nominee2, true);
        
        openElection.openElection(100);

        openElection.vote(address(daoMock), nominee1); 
        vm.stopPrank(); 
        
        vm.roll(block.number + 101);

        (address[] memory nominees2, uint256[] memory votes) = openElection.getNomineeRanking();
        assertEq(nominees2.length, 2);
        assertEq(votes.length, 2);
        assertEq(nominees2[0], nominee1);
        assertEq(nominees2[1], nominee2);
        assertEq(votes[0], 1);
    }

    function testGetNomineesForElection() public {
        vm.prank(address(daoMock));
        openElection.nominate(address(daoMock), true);

        vm.prank(address(daoMock));
        openElection.openElection(100);

        nominees = openElection.getNomineesForElection(1);
        assertEq(nominees.length, 1);
        assertEq(nominees[0], address(daoMock));
    }

    function testGetVoteCount() public {
        vm.startPrank(address(daoMock));
        openElection.nominate(address(daoMock), true);
        openElection.openElection(100);
        openElection.vote(address(daoMock), address(daoMock));
        vm.stopPrank();

        assertEq(openElection.getVoteCount(address(daoMock), 1), 1);
    }

    function testHasUserVoted() public {
        vm.startPrank(address(daoMock));
        openElection.nominate(address(daoMock), true);
        openElection.openElection(100);
        openElection.vote(address(daoMock), address(daoMock));
        vm.stopPrank();

        assertTrue(openElection.hasUserVoted(address(daoMock), 1));
        assertFalse(openElection.hasUserVoted(alice, 0));
    }

    function testIsElectionOpen() public {
        assertFalse(openElection.isElectionOpen());

        vm.prank(address(daoMock));
        openElection.openElection(100);

        assertTrue(openElection.isElectionOpen());

        vm.roll(block.number + 101);
        assertFalse(openElection.isElectionOpen());
    }

    function testGetElectionInfo() public {
        OpenElection.ElectionData memory election = openElection.getElectionInfo();
        assertFalse(election.isOpen);
        assertEq(election.startBlock, 0);
        assertEq(election.durationBlocks, 0);
        assertEq(election.endBlock, 0);

        vm.prank(address(daoMock));
        openElection.openElection(100);

        election = openElection.getElectionInfo();
        assertTrue(election.isOpen);
        assertEq(election.startBlock, block.number);
        assertEq(election.durationBlocks, 100);
        assertEq(election.endBlock, block.number + 100);
    }

    function testNominateAndVoteWithDifferentAddresses() public {
        // Test nominating different addresses
        vm.startPrank(address(daoMock));
        openElection.nominate(alice, true);
        openElection.nominate(bob, true);
        openElection.nominate(charlotte, true);
        vm.stopPrank();

        assertTrue(openElection.isNominee(alice));
        assertTrue(openElection.isNominee(bob));
        assertTrue(openElection.isNominee(charlotte));
        assertEq(openElection.nomineesCount(), 3);

        // Open election
        vm.prank(address(daoMock));
        openElection.openElection(100);

        // Test voting with different callers for different nominees
        vm.prank(address(daoMock));
        openElection.vote(alice, alice); // alice votes for alice

        vm.prank(address(daoMock));
        openElection.vote(bob, bob); // bob votes for bob

        vm.prank(address(daoMock));
        openElection.vote(charlotte, alice); // charlotte votes for alice

        // Check vote counts
        assertEq(openElection.getVoteCount(alice, 1), 2); // alice and charlotte voted for alice
        assertEq(openElection.getVoteCount(bob, 1), 1); // only bob voted for bob
        assertEq(openElection.getVoteCount(charlotte, 1), 0); // no one voted for charlotte

        // Check who voted
        assertTrue(openElection.hasUserVoted(alice, 1));
        assertTrue(openElection.hasUserVoted(bob, 1));
        assertTrue(openElection.hasUserVoted(charlotte, 1));

        // Close election and tally
        vm.roll(block.number + 101);
        (address[] memory nominees2, uint256[] memory votes) = openElection.getNomineeRanking();
        
        // Should be ranked by vote count: alice (2), bob (1), charlotte (0)
        assertEq(nominees2.length, 3);
        assertEq(votes.length, 3);
        assertEq(nominees2[0], alice);
        assertEq(votes[0], 2);
        assertEq(nominees2[1], bob);
        assertEq(votes[1], 1);
        assertEq(nominees2[2], charlotte);
        assertEq(votes[2], 0);
    }

    function testNominateAndRevokeDifferentAddresses() public {
        // Nominate multiple addresses
        vm.startPrank(address(daoMock));
        openElection.nominate(alice, true);
        openElection.nominate(bob, true);
        openElection.nominate(charlotte, true);
        vm.stopPrank();

        assertEq(openElection.nomineesCount(), 3);

        // Revoke one nomination
        vm.prank(address(daoMock));
        openElection.nominate(bob, false);

        assertFalse(openElection.isNominee(bob));
        assertEq(openElection.nomineesCount(), 2);

        // Check that only alice and charlotte are still nominees
        address[] memory nominees = openElection.getNominees();
        assertEq(nominees.length, 2);
        // Note: order might vary due to swap-and-pop implementation
        bool aliceFound = false;
        bool charlotteFound = false;
        for (uint256 i = 0; i < nominees.length; i++) {
            if (nominees[i] == alice) aliceFound = true;
            if (nominees[i] == charlotte) charlotteFound = true;
        }
        assertTrue(aliceFound);
        assertTrue(charlotteFound);
    }
}
