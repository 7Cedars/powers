// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import { Powers} from "../../src/Powers.sol";
// import { Law } from "../../src/Law.sol";
// import { LawUtilities } from "../../src/LawUtilities.sol";
// import { ILaw } from "../../src/interfaces/ILaw.sol";
// import { TestSetupPowers } from "../TestSetup.t.sol";
// import { DaoMock } from "../mocks/DaoMock.sol";
// import { OpenAction } from "../../src/laws/executive/OpenAction.sol";

// /// @notice Unit tests for the core Separated Powers protocol.
// /// @dev tests build on the Hats protocol example. See // https.... £todo

// //////////////////////////////////////////////////////////////
// //               CONSTRUCTOR & RECEIVE                      //
// //////////////////////////////////////////////////////////////
// contract DeployTest is TestSetupPowers {
//     function testDeployAlignedDao() public view { 
//         assertEq(daoMock.name(), daoNames[0]);
//         assertEq(daoMock.version(), "0.3");

//         assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
//     }

//     function testReceive() public {
//         vm.prank(alice);

//         vm.expectEmit(true, false, false, false);
//         emit FundsReceived(1 ether);
//         (bool success,) = address(daoMock).call{ value: 1 ether }("");

//         assertTrue(success);
//         assertEq(address(daoMock).balance, 1 ether);
//     }

//     function testDeployProtocolEmitsEvent() public {
//         vm.expectEmit(true, false, false, false);
//         emit Powers__Initialized(address(daoMock), "DaoMock", "https://example.com");

//         vm.prank(alice);
//         daoMock = new DaoMock();
//     }

//     function testDeployProtocolSetsSenderToAdmin() public {
//         vm.prank(alice);
//         daoMock = new DaoMock();

//         assertNotEq(daoMock.hasRoleSince(alice, ADMIN_ROLE), 0);
//     }

//     function testDeployProtocolSetsPublicRole() public {
//         vm.prank(alice);
//         daoMock = new DaoMock();

//         assertEq(daoMock.getAmountRoleHolders(PUBLIC_ROLE), type(uint256).max);
//     }

//     function testDeployProtocolSetsAdminRole() public {
//         vm.prank(alice);
//         daoMock = new DaoMock();

//         assertEq(daoMock.getAmountRoleHolders(ADMIN_ROLE), 1);
//     }
// }

// //////////////////////////////////////////////////////////////
// //                  GOVERNANCE LOGIC                        //
// //////////////////////////////////////////////////////////////
// contract ProposeTest is TestSetupPowers {
//     function testProposeRevertsWhenAccountLacksCredentials() public {
//         uint32 lawNumber = 4;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         // check if mockAddress does not have correct role
//         address mockAddress = makeAddr("mock");
//         assertFalse(daoMock.canCallLaw(mockAddress, laws[lawNumber]));

//         // act & assert
//         vm.expectRevert(Powers__AccessDenied.selector);
//         vm.prank(mockAddress);
//         daoMock.propose(laws[4], lawCalldata, nonce, description);
//     }

//     function testProposeRevertsIfLawNotActive() public {
//         uint32 lawNumber = 4;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         // check if charlotte has correct role
//         assertTrue(daoMock.canCallLaw(charlotte, laws[lawNumber]));

//         vm.prank(address(daoMock));
//         daoMock.revokeLaw(laws[lawNumber]);

//         vm.expectRevert(Powers__NotActiveLaw.selector);
//         vm.prank(charlotte);
//         daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testProposeRevertsIfLawDoesNotNeedVote() public {
//         uint32 lawNumber = 2;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode("this is dummy Data");
//         address lawThatDoesNotNeedVote = laws[lawNumber];
//         // check if david has correct role
//         assertTrue(daoMock.canCallLaw(david, laws[lawNumber]));

//         vm.prank(david);
//         vm.expectRevert(Powers__NoVoteNeeded.selector);
//         daoMock.propose(lawThatDoesNotNeedVote, lawCalldata,  nonce, description);
//     }

//     function testProposePassesWithCorrectCredentials() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         // check if charlotte has correct role
//         assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Active));
//     }

//     function testProposeEmitsEvents() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         address targetLaw = laws[lawNumber];
//         // check if charlotte has correct role
//         assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

//         actionId = LawUtilities.hashActionId(targetLaw, lawCalldata, nonce);
//         ( , , , , votingPeriod, , ,) = Law(laws[lawNumber]).conditions();

//         vm.expectEmit(true, false, false, false);
//         emit ProposedActionCreated(
//             actionId, alice, targetLaw, "", lawCalldata, block.number, block.number + votingPeriod, nonce, description
//         );
//         vm.prank(alice);
//         daoMock.propose(targetLaw, lawCalldata, nonce, description);
//     }

//     function testProposeRevertsIfAlreadyExist() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         address targetLaw = laws[lawNumber];
//         // check if alice has correct role
//         assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

//         vm.prank(alice);
//         daoMock.propose(targetLaw, lawCalldata, nonce, description);

//         vm.expectRevert(Powers__UnexpectedActionState.selector);
//         vm.prank(alice);
//         daoMock.propose(targetLaw, lawCalldata, nonce, description);
//     }

//     function testProposeSetsCorrectVoteStartAndDuration() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         address targetLaw = laws[lawNumber];
        
//         vm.prank(alice);
//         actionId = daoMock.propose(targetLaw, lawCalldata, nonce, description);
//         ( , , , , votingPeriod, , ,) = Law(laws[lawNumber]).conditions();

//         assertEq(daoMock.getProposedActionDeadline(actionId), block.number + votingPeriod);
//     }
// }

// contract CancelTest is TestSetupPowers {
//     function testCancellingProposalsEmitsCorrectEvent() public {
//         // prep: create a proposal
//         address targetLaw = laws[5];
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(targetLaw, lawCalldata, nonce, description);

//         // act: cancel the proposal
//         vm.expectEmit(true, false, false, false);
//         emit ProposedActionCancelled(actionId);
//         vm.prank(alice);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);
//     }

//     function testCancellingProposalsSetsStateToCancelled() public {
//         // prep: create a proposal
//         address targetLaw = laws[5];
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(targetLaw, lawCalldata, nonce, description);

//         // act: cancel the proposal
//         vm.prank(alice);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);

//         // check the state
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Cancelled));
//     }

//     function testCancelRevertsWhenAccountDidNotCreateProposal() public {
//         // prep: create a proposal
//         address targetLaw = laws[5];
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         daoMock.propose(targetLaw, lawCalldata, nonce, description);

//         // act: try to cancel the proposal
//         vm.expectRevert(Powers__AccessDenied.selector);
//         vm.prank(helen);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);
//     }

//     function testCancelledProposalsCannotBeExecuted() public {
//         // prep: create a proposal
//         address targetLaw = laws[5];
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         daoMock.propose(targetLaw, lawCalldata, nonce, description);

//         // prep: cancel the proposal one time...
//         vm.prank(alice);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);

//         // act: try to cancel proposal a second time. Should revert
//         vm.expectRevert(Powers__UnexpectedActionState.selector);
//         vm.prank(alice);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);
//     }

//     function testCancelRevertsIfProposalAlreadyExecuted() public {
//         // prep: create a proposal
//         address targetLaw = laws[5];
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(targetLaw, lawCalldata, nonce, description);
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(targetLaw).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }

//         // prep: execute the proposal
//         vm.roll(block.number + 4000);
//         vm.prank(alice);
//         daoMock.request(targetLaw, lawCalldata, nonce, description);

//         // act: try to cancel an executed proposal
//         vm.expectRevert(Powers__UnexpectedActionState.selector);
//         vm.prank(alice);
//         daoMock.cancel(targetLaw, lawCalldata, nonce, description);
//     }
// }

// contract VoteTest is TestSetupPowers {
//     function testVotingRevertsIfAccountNotAuthorised() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // create unauthorised account.
//         address mockAddress = makeAddr("mock");
//         assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

//         // act: try to vote, without credentials
//         vm.expectRevert(Powers__AccessDenied.selector);
//         vm.prank(mockAddress);
//         daoMock.castVote(actionId, FOR);
//     }

//     function testProposalDefeatedIfQuorumNotReachedInTime() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // act: go forward in time. -- no votes are cast.
//         vm.roll(block.number + 4000);

//         // check state of proposal
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Defeated));
//     }

//     function testVotingIsNotPossibleForDefeatedProposals() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // prep: defeat proposal: by going beyond voting period, quorum not reached. Proposal is defeated.
//         vm.roll(block.number + 4000);

//         // act : try to vote
//         vm.expectRevert(Powers__ProposedActionNotActive.selector);
//         vm.prank(charlotte);
//         daoMock.castVote(actionId, FOR);
//     }

//     function testProposalSucceededIfQuorumReachedInTime() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'FOR'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         // go forward in time.
//         vm.roll(block.number + 4000);

//         // assert
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Succeeded));
//     }

//     function testVotesWithReasonsWorks() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'FOR'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVoteWithReason(actionId, FOR, "This is a test");
//             }
//         }
//         // go forward in time.
//         vm.roll(block.number + 4000);

//         // assert
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Succeeded));
//     }

//     function testProposalDefeatedIfQuorumReachedButNotEnoughForVotes() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'AGAINST'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, AGAINST);
//             }
//         }
//         // go forward in time.
//         vm.roll(block.number + 4000);

//         // assert
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Defeated));
//     }

//     function testAccountCannotVoteTwice() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // alice votes once..
//         vm.prank(alice);
//         daoMock.castVote(actionId, FOR);

//         // alice tries to vote twice...
//         vm.prank(alice);
//         vm.expectRevert(Powers__AlreadyCastVote.selector);
//         daoMock.castVote(actionId, FOR);
//     }

//     function testAgainstVoteIsCorrectlyCounted() public {
//         // prep: create a proposal
//         uint256 numberAgainstVotes;
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'AGAINST'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, AGAINST);
//                 numberAgainstVotes++;
//             }
//         }

//         // check
//         (uint256 againstVotes,,) = daoMock.getProposedActionVotes(actionId);
//         assertEq(againstVotes, numberAgainstVotes);
//     }

//     function testForVoteIsCorrectlyCounted() public {
//         // prep: create a proposal
//         uint256 numberForVotes;
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'FOR'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//                 numberForVotes++;
//             }
//         }

//         // check
//         (, uint256 forVotes,) = daoMock.getProposedActionVotes(actionId);
//         assertEq(forVotes, numberForVotes);
//     }

//     function testAbstainVoteIsCorrectlyCounted() public {
//         // prep: create a proposal
//         uint256 numberAbstainVotes;
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'ABSTAIN'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, ABSTAIN);
//                 numberAbstainVotes++;
//             }
//         }

//         // check
//         (,, uint256 abstainVotes) = daoMock.getProposedActionVotes(actionId);
//         assertEq(abstainVotes, numberAbstainVotes);
//     }

//     function testVoteRevertsWithInvalidVote() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // act
//         vm.prank(charlotte);
//         vm.expectRevert(Powers__InvalidVoteType.selector);
//         daoMock.castVote(actionId, 4); // = incorrect vote type

//         // check if indeed not stored as a vote
//         (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = daoMock.getProposedActionVotes(actionId);
//         assertEq(againstVotes, 0);
//         assertEq(forVotes, 0);
//         assertEq(abstainVotes, 0);
//     }

//     function testHasVotedReturnCorrectData() public {
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // act
//         vm.prank(charlotte);
//         daoMock.castVote(actionId, ABSTAIN);

//         // check
//         assertTrue(daoMock.hasVoted(actionId, charlotte));
//     }
// }

// contract ExecuteTest is TestSetupPowers {
//     function testExecuteCanChangeState() public {
//         // prep
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); //  assign = true

//         // check that mockAddress does NOT have ROLE_ONE
//         assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

//         // act
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // assert that mockAddress now has ROLE_ONE
//         assertNotEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);
//     }

//     function testExecuteSuccessSetsStateToFulfilled() public {
//         // prep
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = truee

//         // act
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // assert
//         actionId = LawUtilities.hashActionId(laws[lawNumber], lawCalldata, nonce);
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Fulfilled));
//     }

//     function testExecuteEmitsEvent() public {
//         // prep
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = true

//         // build return expected return data
//         address[] memory tar = new address[](1);
//         uint256[] memory val = new uint256[](1);
//         bytes[] memory cal = new bytes[](1);
//         tar[0] = address(daoMock);
//         val[0] = 0;
//         cal[0] = abi.encodeWithSelector(daoMock.assignRole.selector, ROLE_ONE, mockAddress); // selector = assignRole
//         actionId = LawUtilities.hashActionId(laws[lawNumber], lawCalldata, nonce);

//         // act & assert
//         vm.expectEmit(true, false, false, false);
//         emit ActionExecuted(actionId, tar, val, cal);
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfNotAuthorised() public {
//         // prep
//         uint32 lawNumber = 3;
//         description = "Unauthorised call to law 3";
//         lawCalldata = abi.encode(false, true); // (bool nominateMe, bool assignRoles)
//         address mockAddress = makeAddr("mock");
//         // check that mockAddress is not authorised
//         assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

//         // act & assert
//         vm.expectRevert(Powers__AccessDenied.selector);
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfActionAlreadyExecuted() public {
//         // prep
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = truee

//         // execute action once...
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // act: try to execute action again.
//         vm.expectRevert(Powers__ActionAlreadyInitiated.selector);
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfLawNotActive() public {
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = truee

//         // revoke law
//         vm.prank(address(daoMock));
//         daoMock.revokeLaw(laws[lawNumber]);

//         // act & assert
//         vm.expectRevert(Powers__NotActiveLaw.selector);
//         vm.prank(mockAddress);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfProposalNeeded() public {
//         // prep: create a proposal
//         uint32 lawNumber = 4;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);

//         vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
//         vm.prank(charlotte);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfProposalDefeated() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users,
//         // each user that is authorised to vote, votes 'AGAINST'.
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, AGAINST);
//             }
//         }
//         // go forward in time.
//         vm.roll(block.number + 4000);

//         // check if proposal is defeated.
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Defeated));

//         // act & assert: try to execute proposal.
//         vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
//         vm.prank(charlotte);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfProposalCancelled() public {
//         // prep: create a proposal
//         uint32 lawNumber = 5;
//         description = "Creating a proposal";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // cancel proposal
//         vm.prank(alice);
//         daoMock.cancel(laws[lawNumber], lawCalldata, nonce, description);

//         // check if proposal is cancelled.
//         ActionState actionState = daoMock.state(actionId);
//         assertEq(uint8(actionState), uint8(ActionState.Cancelled));

//         // act & assert: try to execute proposal.
//         vm.expectRevert(Powers__ActionCancelled.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testExecuteRevertsIfConditionsNotPassed() public {
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = truee

//         address[] memory tar = new address[](0);
//         uint256[] memory val = new uint256[](0);
//         bytes[] memory cal = new bytes[](0);

//         vm.mockCall(
//             laws[lawNumber],
//             abi.encodeWithSelector(Law.executeLaw.selector, charlotte, lawCalldata, nonce),
//             abi.encode(false)
//         );

//         // act & assert
//         vm.expectRevert(Powers__LawDidNotPassChecks.selector);
//         vm.prank(charlotte);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         vm.clearMockedCalls();
//     }

//     function testIfReturnDataIsAddressOneNothingGetsExecuted() public {
//         uint32 lawNumber = 0;
//         description = "Assigning mockAddress ROLE_ONE";
//         address mockAddress = makeAddr("mock");
//         lawCalldata = abi.encode(true, mockAddress); // assign = truee

//         address[] memory tar = new address[](1);
//         uint256[] memory val = new uint256[](1);
//         bytes[] memory cal = new bytes[](1);
//         tar[0] = address(1);

//         vm.mockCall(
//             laws[lawNumber],
//             abi.encodeWithSelector(Law.executeLaw.selector, charlotte, lawCalldata, nonce),
//             abi.encode(true)
//         );

//         // act
//         vm.prank(charlotte);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // assert
//         assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

//         // clear mock calls
//         vm.clearMockedCalls();
//     }
// }

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
//         uint32 lawNumber = 0;

//         vm.expectRevert(Powers__LawAlreadyActive.selector);
//         vm.prank(address(daoMock));
//         daoMock.adoptLaw(laws[lawNumber]);
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
