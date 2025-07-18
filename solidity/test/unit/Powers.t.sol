// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Powers } from "../../src/Powers.sol";
import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { TestSetupPowers } from "../TestSetup.t.sol";
import { PowersMock } from "../mocks/PowersMock.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";

import { Erc1155Mock } from "../mocks/Erc1155Mock.sol";
import { Erc721Mock } from "../mocks/Erc721Mock.sol";

/// @notice Unit tests for the core Separated Powers protocol.
/// @dev tests build on the Hats protocol example. See // https.... £todo

//////////////////////////////////////////////////////////////
//               CONSTRUCTOR & RECEIVE                      //
//////////////////////////////////////////////////////////////
contract DeployTest is TestSetupPowers {
    function testDeployPowersMock() public {
        assertEq(daoMock.name(), "This is a test DAO");
        assertEq(daoMock.uri(), "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibd3qgeohyjeamqtfgk66lr427gpp4ify5q4civ2khcgkwyvz5hcq");
        assertEq(daoMock.version(), "0.3");
        assertNotEq(daoMock.lawCount(), 0);

        assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
    }

    function testReceive() public {
        vm.prank(alice);

        vm.expectEmit(true, false, false, false);
        emit FundsReceived(1 ether, alice);
        (bool success,) = address(daoMock).call{ value: 1 ether }("");

        assertTrue(success);
        assertEq(address(daoMock).balance, 1 ether);
    }

    function testDeployProtocolEmitsEvent() public {
        vm.expectEmit(true, false, false, false);

        emit Powers__Initialized(address(daoMock), "PowersMock", "https://example.com");
        vm.prank(alice);
        daoMock = new PowersMock();
    }

    function testDeployProtocolSetsSenderToAdmin() public {
        vm.prank(alice);
        daoMock = new PowersMock();

        assertNotEq(daoMock.hasRoleSince(alice, ADMIN_ROLE), 0);
    }

    function testDeployProtocolSetsPublicRole() public {
        vm.prank(alice);
        daoMock = new PowersMock();

        assertEq(daoMock.getAmountRoleHolders(PUBLIC_ROLE), type(uint256).max);
    }

    function testDeployProtocolSetsAdminRole() public {
        vm.prank(alice);
        daoMock = new PowersMock();

        assertEq(daoMock.getAmountRoleHolders(ADMIN_ROLE), 1);
    }
}

//////////////////////////////////////////////////////////////
//                  GOVERNANCE LOGIC                        //
//////////////////////////////////////////////////////////////
contract ProposeTest is TestSetupPowers {
    function testProposeRevertsWhenAccountLacksCredentials() public {
        lawId = 4;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if mockAddress does not have correct role
        address mockAddress = makeAddr("mock");
        assertFalse(daoMock.canCallLaw(mockAddress, lawId));

        // act & assert
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfLawNotActive() public {
        lawId = 4;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.canCallLaw(bob, lawId), "bob should be able to call law 4");

        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(charlotte);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfLawDoesNotNeedVote() public {
        lawId = 2; // does not need vote.
        description = "Creating a proposal";
        lawCalldata = abi.encode("this is dummy Data");
        // check if david has correct role
        assertTrue(daoMock.canCallLaw(david, lawId), "david should be able to call law 2");

        vm.prank(david);
        vm.expectRevert(Powers__NoVoteNeeded.selector);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        lawId = 5;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.canCallLaw(alice, lawId));

        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Active));
    }

    function testProposeEmitsEvents() public {
        lawId = 5;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.hasRoleSince(alice, 2) != 0, "alice should have role 2");
        assertTrue(daoMock.canCallLaw(alice, lawId), "alice should be able to call law 4");

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        vm.expectEmit(true, false, false, false);
        emit ProposedActionCreated(
            actionId,
            alice,
            lawId,
            "",
            lawCalldata,
            block.number,
            block.number + conditions.votingPeriod,
            nonce,
            description
        );
        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfAlreadyExist() public {
        lawId = 5;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if alice has correct role
        assertTrue(daoMock.canCallLaw(alice, lawId));

        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeSetsCorrectVoteStartAndDuration() public {
        lawId = 5;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);

        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        assertEq(daoMock.getProposedActionDeadline(actionId), block.number + conditions.votingPeriod);
    }
}

contract CancelTest is TestSetupPowers {
    function testCancellingProposalsEmitsCorrectEvent() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: cancel the proposal
        vm.expectEmit(true, false, false, false);
        emit ProposedActionCancelled(actionId);
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancellingProposalsSetsStateToCancelled() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: cancel the proposal
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);

        // check the state
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Cancelled));
    }

    function testCancelRevertsWhenAccountDidNotCreateProposal() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: try to cancel the proposal
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(helen);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelledProposalsCannotBeCancelledAgain() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: cancel the proposal
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);

        // act: try to cancel proposal a second time
        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelRevertsIfProposalAlreadyExecuted() public {
        // prep: create a proposal
        lawId = 5;
        targets = new address[](1);
        targets[0] = address(123);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encode("mockCall");

        lawCalldata = abi.encode(targets, values, calldatas);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: execute the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + 1);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // act: try to cancel an executed proposal
        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelRevertsIfLawNotActive() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: revoke the law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        // act: try to cancel proposal for inactive law
        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }
}

contract VoteTest is TestSetupPowers {
    function testVotingRevertsIfAccountNotAuthorised() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // create unauthorised account
        address mockAddress = makeAddr("mock");
        assertFalse(daoMock.canCallLaw(mockAddress, lawId));

        // act: try to vote without credentials
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalDefeatedIfQuorumNotReachedInTime() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: go forward in time without votes
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));
    }

    function testVotingIsNotPossibleForDefeatedProposals() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: defeat proposal by going beyond voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // act: try to vote
        vm.expectRevert(Powers__ProposedActionNotActive.selector);
        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalSucceededIfQuorumReachedInTime() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: vote with authorized users
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // act: go forward in time
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Succeeded));
    }

    function testVotesWithReasonsWorks() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: vote with reasons
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVoteWithReason(actionId, FOR, "This is a test");
            }
        }

        // act: go forward in time
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Succeeded));
    }

    function testProposalDefeatedIfQuorumReachedButNotEnoughForVotes() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: vote against
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // act: go forward in time
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));
    }

    function testAccountCannotVoteTwice() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: vote once
        vm.prank(alice);
        daoMock.castVote(actionId, FOR);

        // act: try to vote again
        vm.prank(alice);
        vm.expectRevert(Powers__AlreadyCastVote.selector);
        daoMock.castVote(actionId, FOR);
    }

    function testAgainstVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAgainstVotes;
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: vote against
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
                numberAgainstVotes++;
            }
        }

        // assert
        (, , , , , , , , uint256 againstVotes, , , ) = daoMock.getActionData(actionId);
        assertEq(againstVotes, numberAgainstVotes);
    }

            

    function testForVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberForVotes;
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: vote for
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
                numberForVotes++;
            }
        }

        // assert
        (, , , , , , , , , uint256 forVotes , , ) = daoMock.getActionData(actionId);
        assertEq(forVotes, numberForVotes);
    }

    function testAbstainVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAbstainVotes;
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: abstain
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, ABSTAIN);
                numberAbstainVotes++;
            }
        }

        // assert
        (, , , , , , , , , , uint256 abstainVotes, ) = daoMock.getActionData(actionId);
        assertEq(abstainVotes, numberAbstainVotes);
    }

    function testVoteRevertsWithInvalidVote() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: try invalid vote
        vm.prank(charlotte);
        vm.expectRevert(Powers__InvalidVoteType.selector);
        daoMock.castVote(actionId, 4); // invalid vote type

        // assert
        (, , , , , , , , uint256 againstVotes, uint256 forVotes, uint256 abstainVotes, ) = daoMock.getActionData(actionId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testHasVotedReturnCorrectData() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: vote
        vm.prank(charlotte);
        daoMock.castVote(actionId, ABSTAIN);

        // assert
        assertTrue(daoMock.hasVoted(actionId, charlotte));
    }
}

contract ExecuteTest is TestSetupPowers {
    function testExecuteCanChangeState() public {
        // prep: create proposal data
        lawId = 1;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // prep: verify initial state
        assertEq(daoMock.hasRoleSince(addresses[0], ROLE_ONE), 0);
        assertEq(daoMock.canCallLaw(addresses[0], lawId), true);

        // act: execute the action
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify state change
        assertNotEq(daoMock.hasRoleSince(addresses[0], ROLE_ONE), 0);
    }

    function testExecuteSuccessSetsStateToFulfilled() public {
        // prep: create proposal data
        lawId = 1;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // act: execute the action
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify state
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Fulfilled));
    }

    function testExecuteEmitsEvent() public {
        // prep: create proposal data
        lawId = 1;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // prep: build expected event data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.assignRole.selector, ROLE_ONE, addresses[0]);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // act: execute and verify event
        vm.expectEmit(true, false, false, false);
        emit ActionExecuted(lawId, actionId, tar, val, cal);
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfNotAuthorised() public {
        // prep: create proposal data
        lawId = 3;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // prep: verify unauthorized state
        assertFalse(daoMock.canCallLaw(addresses[0], lawId));

        // act: try to execute without authorization
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfActionAlreadyExecuted() public {
        // prep: create proposal data
        lawId = 1;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // prep: execute action once
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // act: try to execute again
        vm.expectRevert(Powers__ActionAlreadyInitiated.selector);
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfLawNotActive() public {
        // prep: create proposal data
        lawId = 1;
        address[] memory addresses = new address[](1); 
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        // prep: revoke the law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        // act: try to execute with inactive law
        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalNeeded() public {
        // prep: create proposal data
        lawId = 6;
        lawCalldata = abi.encode(true);

        // act: try to execute without proposal
        vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
        vm.prank(charlotte);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalDefeated() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
                (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: vote against proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // prep: verify proposal is defeated
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));

        // act: try to execute defeated proposal
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        vm.prank(charlotte);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalCancelled() public {
        // prep: create a proposal
        lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: cancel the proposal
        vm.prank(alice);
        daoMock.cancel(lawId, lawCalldata, nonce);

        // prep: verify proposal is cancelled
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Cancelled));

        // act: try to execute cancelled proposal
        vm.expectRevert(Powers__ActionCancelled.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }
}

//////////////////////////////////////////////////////////////
//                  ROLE AND LAW ADMIN                      //
//////////////////////////////////////////////////////////////
contract ConstituteTest is TestSetupPowers {
    function testConstituteSetsLawsToActive() public {
        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        // prep: create new LawInitData[]
        LawInitData[] memory lawInitData = new LawInitData[](1);

        // prep: create new law
        lawInitData[0] = LawInitData({
            nameDescription: "Test law: Test law description",
            // = directSelect
            targetLaw: lawAddresses[6],
            config: abi.encode(1), // role that can be assigned.
            conditions: conditions
        });

        vm.prank(alice);
        daoMockTest.constitute(lawInitData);

        for (i = 1; i <= lawInitData.length; i++) {
            daoMockTest.getActiveLaw(uint16(i));
        }
    }

    function testConstituteRevertsOnSecondCall() public {
        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        LawInitData[] memory lawInitData = new LawInitData[](1);
        lawInitData[0] = LawInitData({
            nameDescription: "Test law: Test law description",
            // = directSelect
            targetLaw: lawAddresses[6],
            config: abi.encode(1), // role that can be assigned.
            conditions: conditions
        });

        vm.prank(alice);
        daoMockTest.constitute(lawInitData);

        vm.expectRevert(Powers__ConstitutionAlreadyExecuted.selector);
        vm.prank(alice);
        daoMockTest.constitute(lawInitData);
    }

    function testConstituteCannotBeCalledByNonAdmin() public {
        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        LawInitData[] memory lawInitData = new LawInitData[](1);
        lawInitData[0] = LawInitData({
            nameDescription: "Test law: Test law description",
            // = directSelect
            targetLaw: lawAddresses[6],
            config: abi.encode(1), // role that can be assigned.
            conditions: conditions
        });

        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(bob);
        daoMockTest.constitute(lawInitData);
    }
}

contract SetLawTest is TestSetupPowers {
    function testSetLawSetsNewLaw() public {
        // prep: create new law
        lawCount = daoMock.lawCount();
        newLaw = address(new OpenAction());

        // prep: create LawInitData
        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        // act: adopt the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);

        // assert: verify law is active
        (address law,,) = daoMock.getActiveLaw(lawCount);
        assertEq(law, newLaw, "New law should be active after adoption");
    }

    function testSetLawEmitsEvent() public {
        // prep: create new law
        lawCount = daoMock.lawCount();
        newLaw = address(new OpenAction());

        // prep: create LawInitData
        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        // act: adopt the law and verify event
        vm.expectEmit(true, false, false, false);
        emit LawAdopted(uint16(lawCount));
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);
    }

    function testSetLawRevertsIfNotCalledFromPowers() public {
        // prep: create new law
        newLaw = address(new OpenAction());

        // prep: create LawInitData
        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        // act: try to adopt law from outside
        vm.expectRevert(Powers__OnlyPowers.selector);
        vm.prank(alice);
        daoMock.adoptLaw(lawInitData);
    }

    function testSetLawRevertsIfAddressNotALaw() public {
        // prep: create invalid law address
        newLaw = address(3333);

        // prep: create LawInitData with invalid law
        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        // act: try to adopt invalid law
        vm.expectRevert(Powers__IncorrectInterface.selector);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);
    }

    function testAdoptintSameLawTwice() public {
        // prep: create new law
        newLaw = address(new OpenAction());

        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        // prep: create LawInitData
        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        // prep: adopt law once
        vm.prank(address(daoMockTest));
        daoMockTest.adoptLaw(lawInitData);

        // act: try to adopt same law again
        vm.prank(address(daoMockTest));
        daoMockTest.adoptLaw(lawInitData);

        for (i = 1; i <= 2; i++) {
            (address law,,) = daoMockTest.getActiveLaw(uint16(i));
            assertEq(law, newLaw, "New law should be active after adoption");
        }
    }

    function testRevokeLawRevertsIfAddressNotActive() public {
        // prep: create new law
        newLaw = address(new OpenAction());

        // prep: revoke law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(1);

        // act: try to revoke already revoked law
        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(address(daoMock));
        daoMock.revokeLaw(1);
    }
}

contract SetRoleTest is TestSetupPowers {
    function testSetRoleSetsNewRole() public {
        // prep: check that helen does not have ROLE_THREE
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        // assert: helen now holds ROLE_THREE
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
    }

    function testSetRoleRevertsWhenCalledFromOutsideProtocol() public {
        vm.prank(alice);
        vm.expectRevert(Powers__OnlyPowers.selector);
        daoMock.assignRole(ROLE_THREE, bob);
    }

    function testSetRoleEmitsCorrectEventIfAccountAlreadyHasRole() public {
        // prep: check that bob has ROLE_ONE
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        vm.prank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit RoleSet(ROLE_ONE, bob, false);
        daoMock.assignRole(ROLE_ONE, bob);
    }

    function testAddingRoleAddsOneToAmountMembers() public {
        // prep
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        // assert
        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
        assertEq(amountMembersAfter, amountMembersBefore + 1, "Member count should increase by 1");
    }

    function testRemovingRoleSubtractsOneFromAmountMembers() public {
        // prep
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.revokeRole(ROLE_ONE, bob);

        // assert
        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0, "Role should be revoked");
        assertEq(amountMembersAfter, amountMembersBefore - 1, "Member count should decrease by 1");
    }

    function testSetRoleSetsEmitsEvent() public {
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit RoleSet(ROLE_THREE, helen, true);
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);
    }

    function testLabelRoleEmitsCorrectEvent() public {
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit RoleLabel(ROLE_THREE, "This is role three");
        vm.prank(address(daoMock));
        daoMock.labelRole(ROLE_THREE, "This is role three");
    }

    function testLabelRoleRevertsForLockedRoles() public {
        // act & assert
        vm.expectRevert(Powers__LockedRole.selector);
        vm.prank(address(daoMock));
        daoMock.labelRole(ADMIN_ROLE, "Admin role");
    }
}

contract ComplianceTest is TestSetupPowers {
    function testErc721Compliance() public {
        // prep
        uint256 nftToMint = 42;
        assertEq(Erc721Mock(mockAddresses[4]).balanceOf(address(daoMock)), 0, "Initial balance should be 0");

        // act
        vm.prank(address(daoMock));
        Erc721Mock(mockAddresses[4]).mintNFT(nftToMint, address(daoMock));

        // assert
        assertEq(Erc721Mock(mockAddresses[4]).balanceOf(address(daoMock)), 1, "Balance should be 1 after minting");
        assertEq(Erc721Mock(mockAddresses[4]).ownerOf(nftToMint), address(daoMock), "NFT should be owned by DAO");
    }

    function testOnERC721Received() public {
        // prep
        address sender = alice;
        address recipient = address(daoMock);
        uint256 tokenId = 42;
        bytes memory data = bytes(abi.encode(0));

        // act
        vm.prank(address(daoMock));
        (bytes4 response) = daoMock.onERC721Received(sender, recipient, tokenId, data);

        // assert
        assertEq(response, daoMock.onERC721Received.selector, "Should return correct selector");
    }

    function testErc1155Compliance() public {
        // prep
        uint256 numberOfCoinsToMint = 100;
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 0, "Initial balance should be 0");

        // act
        vm.prank(address(daoMock));
        Erc1155Mock(mockAddresses[5]).mintCoins(numberOfCoinsToMint);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 100, "Balance should be 100 after minting");
    }

    function testOnERC1155BatchReceived() public {
        // prep
        address sender = alice;
        address recipient = address(daoMock);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        values = new uint256[](1);
        values[0] = 22;
        bytes memory data = bytes(abi.encode(0));

        // act
        vm.prank(address(daoMock));
        (bytes4 response) = daoMock.onERC1155BatchReceived(sender, recipient, tokenIds, values, data);

        // assert
        assertEq(response, daoMock.onERC1155BatchReceived.selector, "Should return correct selector");
    }
}
