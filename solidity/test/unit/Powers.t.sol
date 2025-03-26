// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Powers} from "../../src/Powers.sol";
import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { TestSetupPowers } from "../TestSetup.t.sol";
import { DaoMock } from "../mocks/DaoMock.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";

/// @notice Unit tests for the core Separated Powers protocol.
/// @dev tests build on the Hats protocol example. See // https.... £todo

//////////////////////////////////////////////////////////////
//               CONSTRUCTOR & RECEIVE                      //
//////////////////////////////////////////////////////////////
contract DeployTest is TestSetupPowers {
    function testDeployDaoMock() public { 
        assertEq(daoMock.name(), "DaoMock");
        assertEq(daoMock.version(), "0.3");
        assertNotEq(daoMock.lawCount(), 0);

        assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
    }

    function testReceive() public {
        vm.prank(alice);

        vm.expectEmit(true, false, false, false);
        emit FundsReceived(1 ether);
        (bool success,) = address(daoMock).call{ value: 1 ether }("");

        assertTrue(success);
        assertEq(address(daoMock).balance, 1 ether);
    }

    function testDeployProtocolEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        
        emit Powers__Initialized(address(daoMock), "DaoMock", "https://example.com");
        vm.prank(alice);
        daoMock = new DaoMock();
    }

    function testDeployProtocolSetsSenderToAdmin() public {
        vm.prank(alice);
        daoMock = new DaoMock();

        assertNotEq(daoMock.hasRoleSince(alice, ADMIN_ROLE), 0);
    }

    function testDeployProtocolSetsPublicRole() public {
        vm.prank(alice);
        daoMock = new DaoMock();

        assertEq(daoMock.getAmountRoleHolders(PUBLIC_ROLE), type(uint256).max);
    }

    function testDeployProtocolSetsAdminRole() public {
        vm.prank(alice);
        daoMock = new DaoMock();

        assertEq(daoMock.getAmountRoleHolders(ADMIN_ROLE), 1);
    }
}

//////////////////////////////////////////////////////////////
//                  GOVERNANCE LOGIC                        //
//////////////////////////////////////////////////////////////
contract ProposeTest is TestSetupPowers {
    function testProposeRevertsWhenAccountLacksCredentials() public {
        uint16 lawId = 4;
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
        uint16 lawId = 4;
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
        uint16 lawId = 2; // does not need vote.
        description = "Creating a proposal";
        lawCalldata = abi.encode("this is dummy Data"); 
        // check if david has correct role
        assertTrue(daoMock.canCallLaw(david, lawId), "david should be able to call law 2");

        vm.prank(david);
        vm.expectRevert(Powers__NoVoteNeeded.selector);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        uint16 lawId = 5;
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
        uint16 lawId = 5; 
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.hasRoleSince(alice, 2) != 0, "alice should have role 2");
        assertTrue(daoMock.canCallLaw(alice, lawId), "alice should be able to call law 4");

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        ( , , conditions) = daoMock.getActiveLaw(lawId);

        vm.expectEmit(true, false, false, false);
        emit ProposedActionCreated(
            actionId, alice, lawId, "", lawCalldata, block.number, block.number + conditions.votingPeriod, nonce, description
        );
        vm.prank(alice);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfAlreadyExist() public {
        uint16 lawId = 5;
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
        uint16 lawId = 5;
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        assertEq(daoMock.getProposedActionDeadline(actionId), block.number + conditions.votingPeriod);
    }
}

contract CancelTest is TestSetupPowers {
    function testCancellingProposalsEmitsCorrectEvent() public {
        // prep: create a proposal
        uint16 lawId = 5;
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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
        lawCalldata = abi.encode(
            targets,
            values,
            calldatas
        );
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        ( , , conditions) = daoMock.getActiveLaw(lawId);
        
        // prep: execute the proposal
        for ( i = 0; i < users.length; i++) {    
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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        // act: go forward in time without votes
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));
    }

    function testVotingIsNotPossibleForDefeatedProposals() public {
        // prep: create a proposal
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        // prep: defeat proposal by going beyond voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // act: try to vote
        vm.expectRevert(Powers__ProposedActionNotActive.selector);
        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalSucceededIfQuorumReachedInTime() public {
        // prep: create a proposal
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

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
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

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
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

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
        uint16 lawId = 5;
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
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        // act: vote against
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
                numberAgainstVotes++;
            }
        }

        // assert
        (uint256 againstVotes,,) = daoMock.getProposedActionVotes(actionId);
        assertEq(againstVotes, numberAgainstVotes);
    }

    function testForVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberForVotes;
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        // act: vote for
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
                numberForVotes++;
            }
        }

        // assert
        (, uint256 forVotes,) = daoMock.getProposedActionVotes(actionId);
        assertEq(forVotes, numberForVotes);
    }

    function testAbstainVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAbstainVotes;
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

        // act: abstain
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, ABSTAIN);
                numberAbstainVotes++;
            }
        }

        // assert
        (,, uint256 abstainVotes) = daoMock.getProposedActionVotes(actionId);
        assertEq(abstainVotes, numberAbstainVotes);
    }

    function testVoteRevertsWithInvalidVote() public {
        // prep: create a proposal
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // act: try invalid vote
        vm.prank(charlotte);
        vm.expectRevert(Powers__InvalidVoteType.selector);
        daoMock.castVote(actionId, 4); // invalid vote type

        // assert
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = daoMock.getProposedActionVotes(actionId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testHasVotedReturnCorrectData() public {
        // prep: create a proposal
        uint16 lawId = 5;
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
        uint16 lawId = 1;
        address mockAddress = makeAddr("mock");
        lawCalldata = abi.encode(true, mockAddress);

        // prep: verify initial state
        assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

        // act: execute the action
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify state change
        assertNotEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);
    }

    function testExecuteSuccessSetsStateToFulfilled() public {
        // prep: create proposal data
        uint16 lawId = 1;
        address mockAddress = makeAddr("mock");
        lawCalldata = abi.encode(true, mockAddress);

        // act: execute the action
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify state
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        ActionState actionState = daoMock.state(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Fulfilled));
    }

    function testExecuteEmitsEvent() public {
        // prep: create proposal data
        uint16 lawId = 1;
        address mockAddress = makeAddr("mock");
        lawCalldata = abi.encode(true, mockAddress);

        // prep: build expected event data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.assignRole.selector, ROLE_ONE, mockAddress);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // act: execute and verify event
        vm.expectEmit(true, false, false, false);
        emit ActionExecuted(lawId, actionId, tar, val, cal);
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfNotAuthorised() public {
        // prep: create proposal data
        uint16 lawId = 3;
        lawCalldata = abi.encode(false, true);
        address mockAddress = makeAddr("mock");

        // prep: verify unauthorized state
        assertFalse(daoMock.canCallLaw(mockAddress, lawId));

        // act: try to execute without authorization
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfActionAlreadyExecuted() public {
        // prep: create proposal data
        uint16 lawId = 1;
        address mockAddress = makeAddr("mock");
        lawCalldata = abi.encode(true, mockAddress);

        // prep: execute action once
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // act: try to execute again
        vm.expectRevert(Powers__ActionAlreadyInitiated.selector);
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfLawNotActive() public {
        // prep: create proposal data
        uint16 lawId = 1;
        address mockAddress = makeAddr("mock");
        lawCalldata = abi.encode(true, mockAddress);

        // prep: revoke the law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        // act: try to execute with inactive law
        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(mockAddress);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalNeeded() public {
        // prep: create proposal data
        uint16 lawId = 6;
        lawCalldata = abi.encode(true);

        // act: try to execute without proposal
        vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
        vm.prank(charlotte);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalDefeated() public {
        // prep: create a proposal
        uint16 lawId = 5;
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        ( , , conditions) = daoMock.getActiveLaw(lawId);

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
        uint16 lawId = 5;
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

// //////////////////////////////////////////////////////////////
// //                  ROLE AND LAW ADMIN                      //
// //////////////////////////////////////////////////////////////
// contract ConstituteTest is TestSetupPowers {
//     function testConstituteSetsLawsToActive() public {
//         vm.prank(alice);
//         DaoMock daoMockTest = new DaoMock();


//         address[] memory newLaws = new address[](1);
//         newLaws[0] = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMockTest)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.prank(alice);
//         daoMockTest.constitute(newLaws);

//         for (uint32 i = 0; i < newLaws.length; i++) {
//             bool active = daoMockTest.getActiveLaw(newLaws[i]);
//             assertTrue(active, "Law should be active after constitution");
//         }
//     }

//     function testConstituteRevertsOnSecondCall() public {
//         vm.prank(alice);
//         DaoMock daoMockTest = new DaoMock();

//         address[] memory newLaws = new address[](1);
//         newLaws[0] = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMockTest)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.prank(alice);
//         daoMockTest.constitute(newLaws);

//         vm.expectRevert(Powers__ConstitutionAlreadyExecuted.selector);
//         vm.prank(alice);
//         daoMockTest.constitute(newLaws);
//     }

//     function testConstituteCannotBeCalledByNonAdmin() public {
//         vm.prank(alice);
//         DaoMock daoMockTest = new DaoMock();

//         address[] memory newLaws = new address[](1);
//         newLaws[0] = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMockTest)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.expectRevert(Powers__AccessDenied.selector);
//         vm.prank(bob);
//         daoMockTest.constitute(newLaws);
//     }
// }

// contract SetLawTest is TestSetupPowers {
//     function testSetLawSetsNewLaw() public {

//         address newLaw = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMock)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.prank(address(daoMock));
//         daoMock.adoptLaw(newLaw);

//         assertTrue(daoMock.getActiveLaw(newLaw), "New law should be active after adoption");
//     }

//     function testSetLawEmitsEvent() public {

//         address newLaw = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMock)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.expectEmit(true, false, false, false);
//         emit LawAdopted(newLaw);
//         vm.prank(address(daoMock));
//         daoMock.adoptLaw(newLaw);
//     }

//     function testSetLawRevertsIfNotCalledFromPowers() public {

//         address newLaw = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMock)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.expectRevert(Powers__OnlyPowers.selector);
//         vm.prank(alice);
//         daoMock.adoptLaw(newLaw);
//     }

//     function testSetLawRevertsIfAddressNotALaw() public {
//         address newNotALaw = address(3333);

//         vm.expectRevert(Powers__IncorrectInterface.selector);
//         vm.prank(address(daoMock));
//         daoMock.adoptLaw(newNotALaw);
//     }

//     function testAdoptLawRevertsIfAddressAlreadyLaw() public {
//         uint16 lawId = 0;

//         vm.expectRevert(Powers__LawAlreadyActive.selector);
//         vm.prank(address(daoMock));
//         daoMock.adoptLaw(lawId);
//     }

//     function testRevokeLawRevertsIfAddressNotActive() public {

//         address newLaw = address(new OpenAction(
//             "test law",
//             "This is a test Law",
//             payable(address(daoMock)),
//             ROLE_ONE,
//             Conditions
//         ));

//         vm.expectRevert(Powers__LawNotActive.selector);
//         vm.prank(address(daoMock));
//         daoMock.revokeLaw(newLaw);
//     }
// }

// contract SetRoleTest is TestSetupPowers {
//     function testSetRoleSetsNewRole() public {
//         // prep: check that helen does not have ROLE_THREE
//         assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

//         // act
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_THREE, helen);

//         // assert: helen now holds ROLE_THREE
//         assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
//     }

//     function testSetRoleRevertsWhenCalledFromOutsideProtocol() public {
//         vm.prank(alice);
//         vm.expectRevert(Powers__OnlyPowers.selector);
//         daoMock.assignRole(ROLE_THREE, bob);
//     }

//     function testSetRoleEmitsCorrectEventIfAccountAlreadyHasRole() public {
//         // prep: check that bob has ROLE_ONE
//         assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

//         vm.prank(address(daoMock));
//         vm.expectEmit(true, false, false, false);
//         emit RoleSet(ROLE_ONE, bob, false);
//         daoMock.assignRole(ROLE_ONE, bob);
//     }

//     function testAddingRoleAddsOneToAmountMembers() public {
//         // prep
//         uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_THREE);
//         assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

//         // act
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_THREE, helen);

//         // assert
//         uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_THREE);
//         assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
//         assertEq(amountMembersAfter, amountMembersBefore + 1, "Member count should increase by 1");
//     }

//     function testRemovingRoleSubtractsOneFromAmountMembers() public {
//         // prep
//         uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_ONE);
//         assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

//         // act
//         vm.prank(address(daoMock));
//         daoMock.revokeRole(ROLE_ONE, bob);

//         // assert
//         uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_ONE);
//         assertEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0, "Role should be revoked");
//         assertEq(amountMembersAfter, amountMembersBefore - 1, "Member count should decrease by 1");
//     }

//     function testSetRoleSetsEmitsEvent() public {
//         // act & assert
//         vm.expectEmit(true, false, false, false);
//         emit RoleSet(ROLE_THREE, helen, true);
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_THREE, helen);
//     }

//     function testLabelRoleEmitsCorrectEvent() public {
//         // act & assert
//         vm.expectEmit(true, false, false, false);
//         emit RoleLabel(ROLE_THREE, "This is role three");
//         vm.prank(address(daoMock));
//         daoMock.labelRole(ROLE_THREE, "This is role three");
//     }

//     function testLabelRoleRevertsForLockedRoles() public {
//         // act & assert
//         vm.expectRevert(Powers__LockedRole.selector);
//         vm.prank(address(daoMock));
//         daoMock.labelRole(ADMIN_ROLE, "Admin role");
//     }
// }

// contract ComplianceTest is TestSetupPowers {
//     function testErc721Compliance() public {
//         // prep
//         uint256 nftToMint = 42;
//         assertEq(erc721Mock.balanceOf(address(daoMock)), 0, "Initial balance should be 0");

//         // act
//         vm.prank(address(daoMock));
//         erc721Mock.mintNFT(nftToMint, address(daoMock));

//         // assert
//         assertEq(erc721Mock.balanceOf(address(daoMock)), 1, "Balance should be 1 after minting");
//         assertEq(erc721Mock.ownerOf(nftToMint), address(daoMock), "NFT should be owned by DAO");
//     }

//     function testOnERC721Received() public {
//         // prep
//         address sender = alice;
//         address recipient = address(daoMock);
//         uint256 tokenId = 42;
//         bytes memory data = bytes(abi.encode(0));

//         // act
//         vm.prank(address(daoMock));
//         (bytes4 response) = daoMock.onERC721Received(sender, recipient, tokenId, data);

//         // assert
//         assertEq(response, daoMock.onERC721Received.selector, "Should return correct selector");
//     }

//     function testErc1155Compliance() public {
//         // prep
//         uint256 numberOfCoinsToMint = 100;
//         assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 0, "Initial balance should be 0");

//         // act
//         vm.prank(address(daoMock));
//         erc1155Mock.mintCoins(numberOfCoinsToMint);

//         // assert
//         assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 100, "Balance should be 100 after minting");
//     }

//     function testOnERC1155BatchReceived() public {
//         // prep
//         address sender = alice;
//         address recipient = address(daoMock);
//         uint256[] memory tokenIds = new uint256[](1);
//         tokenIds[0] = 1;
//         uint256[] memory values = new uint256[](1);
//         values[0] = 22;
//         bytes memory data = bytes(abi.encode(0));

//         // act
//         vm.prank(address(daoMock));
//         (bytes4 response) = daoMock.onERC1155BatchReceived(sender, recipient, tokenIds, values, data);

//         // assert
//         assertEq(response, daoMock.onERC1155BatchReceived.selector, "Should return correct selector");
//     }
// }

