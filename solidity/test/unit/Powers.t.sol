// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Powers} from "../../src/Powers.sol";
import { Law } from "../../src/Law.sol";
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
    function testDeployAlignedDao() public view {
        assertEq(daoMock.name(), daoNames[0]);
        assertEq(daoMock.version(), "0.2");

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
        emit Powers__Initialized(address(daoMock), "DaoMock");

        vm.prank(alice);
        daoMock = new DaoMock();
    }

    function testDeployProtocolSetsSenderToAdmin() public {
        vm.prank(alice);
        daoMock = new DaoMock();

        assertNotEq(daoMock.hasRoleSince(alice, ADMIN_ROLE), 0);
    }
}

//////////////////////////////////////////////////////////////
//                  GOVERNANCE LOGIC                        //
//////////////////////////////////////////////////////////////
contract ProposeTest is TestSetupPowers {
    function testProposeRevertsWhenAccountLacksCredentials() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if mockAddress does not have correct role
        address mockAddress = makeAddr("mock");
        assertFalse(daoMock.canCallLaw(mockAddress, laws[lawNumber]));

        // act & assert
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.propose(laws[4], lawCalldata, description);
    }

    function testProposeRevertsIfLawNotActive() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.canCallLaw(charlotte, laws[lawNumber]));

        vm.prank(address(daoMock));
        daoMock.revokeLaw(laws[lawNumber]);

        vm.expectRevert(Powers__NotActiveLaw.selector);
        vm.prank(charlotte);
        daoMock.propose(laws[lawNumber], lawCalldata, description);
    }

    function testProposeRevertsIfLawDoesNotNeedVote() public {
        uint32 lawNumber = 2;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode("this is dummy Data");
        address lawThatDoesNotNeedVote = laws[lawNumber];
        // check if david has correct role
        assertTrue(daoMock.canCallLaw(david, laws[lawNumber]));

        vm.prank(david);
        vm.expectRevert(Powers__NoVoteNeeded.selector);
        daoMock.propose(lawThatDoesNotNeedVote, lawCalldata, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Active));
    }

    function testProposeEmitsEvents() public {
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        address targetLaw = laws[lawNumber];
        // check if charlotte has correct role
        assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

        uint256 actionId = hashProposal(targetLaw, lawCalldata, keccak256(bytes(description)));
        (,, uint32 duration,,,,,) = Law(laws[lawNumber]).config();

        vm.expectEmit(true, false, false, false);
        emit ProposalCreated(
            actionId, alice, targetLaw, "", lawCalldata, block.number, block.timestamp + duration, description
        );
        vm.prank(alice);
        daoMock.propose(targetLaw, lawCalldata, description);
    }

    function testProposeRevertsIfAlreadyExist() public {
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        address targetLaw = laws[lawNumber];
        // check if alice has correct role
        assertTrue(daoMock.canCallLaw(alice, laws[lawNumber]));

        vm.prank(alice);
        daoMock.propose(targetLaw, lawCalldata, description);

        vm.expectRevert(Powers__UnexpectedProposalState.selector);
        vm.prank(alice);
        daoMock.propose(targetLaw, lawCalldata, description);
    }
}

contract CancelTest is TestSetupPowers {
    function testCancellingProposalsEmitsCorrectEvent() public {
        // prep: create a proposal
        address targetLaw = laws[5];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // act: cancel the proposal
        vm.expectEmit(true, false, false, false);
        emit ProposalCancelled(actionId);
        vm.prank(alice);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }

    function testCancellingProposalsSetsStateToCancelled() public {
        // prep: create a proposal
        address targetLaw = laws[5];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // act: cancel the proposal
        vm.prank(alice);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));

        // check the state
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Cancelled));
    }

    function testCancelRevertsWhenAccountDidNotCreateProposal() public {
        // prep: create a proposal
        address targetLaw = laws[5];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.propose(targetLaw, lawCalldata, description);

        // act: try to cancel the proposal
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(helen);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }

    function testCancelledProposalsCannotBeExecuted() public {
        // prep: create a proposal
        address targetLaw = laws[5];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.propose(targetLaw, lawCalldata, description);

        // prep: cancel the proposal one time...
        vm.prank(alice);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));

        // act: try to cancel proposal a second time. Should revert
        vm.expectRevert(Powers__UnexpectedProposalState.selector);
        vm.prank(alice);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }
}

contract VoteTest is TestSetupPowers {
    function testVotingRevertsIfAccountNotAuthorised() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // create unauthorised account.
        address mockAddress = makeAddr("mock");
        assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

        // act: try to vote, without credentials
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalDefeatedIfQuorumNotReachedInTime() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act: go forward in time. -- no votes are cast.
        vm.roll(block.number + 4000);

        // check state of proposal
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Defeated));
    }

    function testVotingIsNotPossibleForDefeatedProposals() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // prep: defeat proposal: by going beyond voting period, quorum not reached. Proposal is defeated.
        vm.roll(block.number + 4000);

        // act : try to vote
        vm.expectRevert(Powers__ProposalNotActive.selector);
        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalSucceededIfQuorumReachedInTime() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        // go forward in time.
        vm.roll(block.number + 4000); //

        // assert
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Succeeded));
    }

    function testVotesWithReasonsWorks() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVoteWithReason(actionId, FOR, "This is a test");
            }
        }
        // go forward in time.
        vm.roll(block.number + 4000);

        // assert
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Succeeded));
    }

    function testProposalDefeatedIfQuorumReachedButNotEnoughForVotes() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        // go forward in time.
        vm.roll(block.number + 4000); //

        // assert
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Defeated));
    }

    function testAccountCannotVoteTwice() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // alice votes once..
        vm.prank(alice);
        daoMock.castVote(actionId, FOR);

        // alice tries to vote twice...
        vm.prank(alice);
        vm.expectRevert(Powers__AlreadyCastVote.selector);
        daoMock.castVote(actionId, FOR);
    }

    function testAgainstVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAgainstVotes;
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
                numberAgainstVotes++;
            }
        }

        // check
        (uint256 againstVotes,,) = daoMock.getProposalVotes(actionId);
        assertEq(againstVotes, numberAgainstVotes);
    }

    function testForVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberForVotes;
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
                numberForVotes++;
            }
        }

        // check
        (, uint256 forVotes,) = daoMock.getProposalVotes(actionId);
        assertEq(forVotes, numberForVotes);
    }

    function testAbstainVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAbstainVotes;
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'ABSTAIN'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, ABSTAIN);
                numberAbstainVotes++;
            }
        }

        // check
        (,, uint256 abstainVotes) = daoMock.getProposalVotes(actionId);
        assertEq(abstainVotes, numberAbstainVotes);
    }

    function testVoteRevertsWithInvalidVote() public {
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act
        vm.prank(charlotte);
        vm.expectRevert(Powers__InvalidVoteType.selector);
        daoMock.castVote(actionId, 4); // = incorrect vote type

        // check if indeed not stored as a vote
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = daoMock.getProposalVotes(actionId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testHasVotedReturnCorrectData() public {
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act
        vm.prank(charlotte);
        daoMock.castVote(actionId, ABSTAIN);

        // check
        assertTrue(daoMock.hasVoted(actionId, charlotte));
    }
}

contract ExecuteTest is TestSetupPowers {
    function testExecuteCanChangeState() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        // check that mockAddress does NOT have ROLE_ONE
        assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

        // act
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert that mockAddress now has ROLE_ONE
        assertNotEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);
    }

    function testExecuteSuccessSetsStateToComplete() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        // act
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        uint256 actionId = hashProposal(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Completed));
    }

    function testExecuteEmitEvent() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        // build return expected return data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.assignRole.selector, ROLE_ONE, mockAddress); // selector = assignRole

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit ProposalExecuted(tar, val, cal);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfNotAuthorised() public {
        // prep
        uint32 lawNumber = 3;
        string memory description = "Unauthorised call to law 3";
        bytes memory lawCalldata = abi.encode(false, true); // (bool nominateMe, bool assignRoles)
        address mockAddress = makeAddr("mock");
        // check that mockAddress is not authorised
        assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

        // act & assert
        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfActionAlreadyExecuted() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        // execute action once...
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // act: try to execute action again.
        vm.expectRevert(Powers__ProposalAlreadyCompleted.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfLawNotActive() public {
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        // revoke law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(laws[lawNumber]);

        // act & assert
        vm.expectRevert(Powers__NotActiveLaw.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfProposalNeeded() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);

        vm.expectRevert();
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfProposalDefeated() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        // go forward in time.
        vm.roll(block.number + 4000); //

        // check if proposal is defeated.
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Defeated));

        // act & assert: try to execute proposal.
        vm.expectRevert(); // check selector
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfProposalCancelled() public {
        // prep: create a proposal
        uint32 lawNumber = 5;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // cancel proposal
        vm.prank(alice);
        daoMock.cancel(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // check if proposal is cancelled.
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Cancelled));

        // act & assert: try to execute proposal.
        vm.expectRevert(Powers__ProposalCancelled.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testExecuteRevertsIfLawChecksNotPassed() public {
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        address[] memory tar = new address[](0);
        uint256[] memory val = new uint256[](0);
        bytes[] memory cal = new bytes[](0);

        vm.mockCall(
            laws[lawNumber],
            abi.encodeWithSelector(Law.executeLaw.selector, charlotte, lawCalldata, keccak256(bytes(description))),
            abi.encode(tar, val, cal)
        );

        // act & assert
        vm.expectRevert(Powers__LawDidNotPassChecks.selector);
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        vm.clearMockedCalls();
    }

    function testIfReturnDataIsAddressOneNothingGetsExecuted() public {
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(1);

        vm.mockCall(
            laws[lawNumber],
            abi.encodeWithSelector(Law.executeLaw.selector, charlotte, lawCalldata, keccak256(bytes(description))),
            abi.encode(tar, val, cal)
        );

        // act .
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        vm.assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

        // clear mock calls
        vm.clearMockedCalls();
    }

    function testExecuteRevertsWithIncorrectReturnArrayLengths() public {
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        address mockAddress = makeAddr("mock");
        bytes memory lawCalldata = abi.encode(false, mockAddress); // revoke = false

        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](2);
        bytes[] memory cal = new bytes[](3);
        tar[0] = address(123);

        vm.mockCall(
            laws[lawNumber],
            abi.encodeWithSelector(Law.executeLaw.selector, charlotte, lawCalldata, keccak256(bytes(description))),
            abi.encode(tar, val, cal)
        );

        // act & assert.
        vm.expectRevert(Powers__InvalidCallData.selector);
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // clear mock calls
        vm.clearMockedCalls();
    }
}

//////////////////////////////////////////////////////////////
//                  ROLE AND LAW ADMIN                      //
//////////////////////////////////////////////////////////////
contract ConstituteTest is TestSetupPowers {
    function testConstituteSetsLawsToActive() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();

        ILaw.LawConfig memory lawConfig;
        address[] memory laws = new address[](1);
        laws[0] =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.prank(alice);
        daoMockTest.constitute(laws);

        for (uint32 i = 0; i < laws.length; i++) {
            bool active = daoMockTest.getActiveLaw(laws[i]);
            assertTrue(active);
        }
    }

    function testConstituteRevertsOnSecondCall() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();

        ILaw.LawConfig memory lawConfig;
        address[] memory laws = new address[](1);
        laws[0] =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.prank(alice);
        daoMockTest.constitute(laws);

        vm.expectRevert(Powers__ConstitutionAlreadyExecuted.selector);
        vm.prank(alice);
        daoMockTest.constitute(laws);
    }

    function testConstituteCannotBeCalledByNonAdmin() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();

        ILaw.LawConfig memory lawConfig;
        address[] memory laws = new address[](1);
        laws[0] =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.expectRevert(Powers__AccessDenied.selector);
        vm.prank(bob);
        daoMockTest.constitute(laws);
    }
}

contract SetLawTest is
    TestSetupPowers // also tests revokeLaw function
{
    function testSetLawSetsNewLaw() public {
        ILaw.LawConfig memory lawConfig;
        address newLaw =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.prank(address(daoMock));
        daoMock.adoptLaw(newLaw);

        assertTrue(daoMock.getActiveLaw(newLaw));
    }

    function testSetLawEmitsEvent() public {
        ILaw.LawConfig memory lawConfig;
        address newLaw =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.expectEmit(true, false, false, false);
        emit LawAdopted(newLaw);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(newLaw);
    }

    function testSetLawRevertsIfNotCalledFromPowers() public {
        ILaw.LawConfig memory lawConfig;
        address newLaw =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.expectRevert(Powers__OnlyPowers.selector);
        vm.prank(alice);
        daoMock.adoptLaw(newLaw);
    }

    function testSetLawRevertsIfAddressNotALaw() public {
        address newNotALaw = address(3333);

        vm.expectRevert(Powers__IncorrectInterface.selector);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(newNotALaw);
    }

    function testAdoptLawRevertsIfAddressAlreadyLaw() public {
        uint32 lawNumber = 0;

        vm.expectRevert(Powers__LawAlreadyActive.selector);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(laws[lawNumber]);
    }

    function testRevokeLawRevertsIfAddressNotActive() public {
        ILaw.LawConfig memory lawConfig;
        address newLaw =
            address(new OpenAction("test law", "This is a test Law", payable(address(daoMock)), ROLE_ONE, lawConfig));

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(address(daoMock));
        daoMock.revokeLaw(newLaw);
    }
}

contract SetRoleTest is TestSetupPowers {
    function testSetRoleSetsNewRole() public {
        // prep: check that bob does not have ROLE_THREE
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        // assert: bob now holds ROLE_THREE
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);
    }

    function testSetRoleRevertsWhenCalledFromOutsidePropotocol() public {
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
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);
        assertEq(amountMembersAfter, amountMembersBefore + 1);
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
        assertEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);
        assertEq(amountMembersAfter, amountMembersBefore - 1);
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
}

contract ComplianceTest is TestSetupPowers {
    function testErc721Compliance() public {
        // prep
        uint256 NftToMint = 42;
        assertEq(erc721Mock.balanceOf(address(daoMock)), 0);

        // act
        vm.prank(address(daoMock));
        erc721Mock.mintNFT(NftToMint, address(daoMock));

        // assert
        assertEq(erc721Mock.balanceOf(address(daoMock)), 1);
        assertEq(erc721Mock.ownerOf(NftToMint), address(daoMock));
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
        assertEq(response, daoMock.onERC721Received.selector);
    }

    function testErc1155Compliance() public {
        // prep
        uint256 NumberOfCoinsToMint = 100;
        assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 0);

        // act
        vm.prank(address(daoMock));
        erc1155Mock.mintCoins(NumberOfCoinsToMint);

        // assert
        assertEq(erc1155Mock.balanceOf(address(daoMock), 0), NumberOfCoinsToMint);
    }

    function testOnERC1155BatchReceived() public {
        // prep
        address sender = alice;
        address recipient = address(daoMock);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256[] memory values = new uint256[](1);
        values[0] = 22;
        bytes memory data = bytes(abi.encode(0));

        // act
        vm.prank(address(daoMock));
        (bytes4 response) = daoMock.onERC1155BatchReceived(sender, recipient, tokenIds, values, data);

        // assert
        assertEq(response, daoMock.onERC1155BatchReceived.selector);
    }
}

contract DataTypeSignatureTest is TestSetupPowers {
    function testEncodeDataType() public {
        console.logBytes4(encodeDataType("uint8"));
        console.logBytes4(encodeDataType("uint16"));
        console.logBytes4(encodeDataType("uint32"));
        console.logBytes4(encodeDataType("uint64"));
        console.logBytes4(encodeDataType("uint128"));
        console.logBytes4(encodeDataType("uint256"));
        console.logBytes4(encodeDataType("address"));
        console.logBytes4(encodeDataType("bytes"));
        console.logBytes4(encodeDataType("string"));
        console.logBytes4(encodeDataType("bytes32"));
        console.logBytes4(encodeDataType("bool"));
        console.logBytes4(encodeDataType("uint8[]"));
        console.logBytes4(encodeDataType("uint16[]"));
        console.logBytes4(encodeDataType("uint32[]"));
        console.logBytes4(encodeDataType("uint64[]"));
        console.logBytes4(encodeDataType("uint128[]"));
        console.logBytes4(encodeDataType("uint256[]"));
        console.logBytes4(encodeDataType("address[]"));
        console.logBytes4(encodeDataType("bytes[]"));
        console.logBytes4(encodeDataType("string[]"));
        console.logBytes4(encodeDataType("bytes32[]"));
        console.logBytes4(encodeDataType("bool[]"));
    }

    function encodeDataType(string memory param) private returns (bytes4 signature) {
        return bytes4(keccak256(bytes(param)));
    }
}

// uint8,
// uint16,
// uint32,
// uint64,
// uint128,
// uint256,
// address,
// bytes,
// string,
// bytes32,
// bool,
// uint8[],
// uint16[],
// uint32[],
// uint64[],
// uint128[],
// uint256[],
// address[],
// bytes[],
// string[],
// bytes32[],
// bool[],
