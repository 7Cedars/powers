// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Powers } from "../../src/Powers.sol";
import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { PowersUtilities } from "../../src/PowersUtilities.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { TestSetupPowers } from "../TestSetup.t.sol";
import { PowersMock } from "../mocks/PowersMock.sol";
import { OpenAction } from "../../src/laws/multi/OpenAction.sol";

import { SimpleErc1155 } from "../mocks/SimpleErc1155.sol";
import { SoulboundErc721 } from "../mocks/SoulboundErc721.sol";

/// @notice Unit tests for the core Powers protocol (updated v0.4)

//////////////////////////////////////////////////////////////
//               CONSTRUCTOR & RECEIVE                      //
//////////////////////////////////////////////////////////////
contract DeployTest is TestSetupPowers {
    function testDeployPowersMock() public view {
        assertEq(daoMock.name(), "This is a test DAO");
        assertEq(
            daoMock.uri(),
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibd3qgeohyjeamqtfgk66lr427gpp4ify5q4civ2khcgkwyvz5hcq"
        );
        assertEq(daoMock.version(), "0.4");
        assertNotEq(daoMock.lawCount(), 0);

        assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
    }

    function testReceive() public {
        // first enable payable. 
        vm.prank(address(daoMock)); 
        daoMock.setPayableEnabled(true);

        vm.deal(alice, 1 ether);
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit FundsReceived(1 ether, alice);
        (bool success,) = address(daoMock).call{ value: 1 ether }("");

        assertTrue(success);
        assertEq(address(daoMock).balance, 1 ether);
    }

    function testReceiveRevertsWhenNotEnabled() public { 
        vm.deal(alice, 1 ether);
        
        vm.prank(alice);
        vm.expectRevert(Powers__PayableNotEnabled.selector);
        (bool success ,) = address(daoMock).call{ value: 1 ether }("");
        
        assertTrue(success);
        assertEq(address(daoMock).balance, 0);
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
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        address mockAddress = makeAddr("mock");
        assertFalse(daoMock.canCallLaw(mockAddress, lawId));

        vm.expectRevert(Powers__CannotCallLaw.selector);
        vm.prank(mockAddress);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfLawNotActive() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        assertTrue(daoMock.canCallLaw(bob, lawId), "bob should be able to call law 4");

        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(charlotte);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfLawDoesNotNeedVote() public {
        lawId = 2; // Nominate Me - does not need vote
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        assertTrue(daoMock.canCallLaw(david, lawId), "david should be able to call law 2");

        vm.prank(david);
        vm.expectRevert(Powers__NoVoteNeeded.selector);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        assertTrue(daoMock.canCallLaw(bob, lawId));

        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Active));
    }

    function testProposeEmitsEvents() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        assertTrue(daoMock.hasRoleSince(bob, ROLE_ONE) != 0, "bob should have role 1");
        assertTrue(daoMock.canCallLaw(bob, lawId), "bob should be able to call law 4");

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        vm.expectEmit(true, false, false, false);
        emit ProposedActionCreated(
            actionId,
            bob,
            lawId,
            "",
            lawCalldata,
            block.number,
            block.number + conditions.votingPeriod,
            nonce,
            description
        );
        vm.prank(bob);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeRevertsIfAlreadyExist() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);
        assertTrue(daoMock.canCallLaw(bob, lawId));

        vm.prank(bob);
        daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(bob);
        daoMock.propose(lawId, lawCalldata, nonce, description);
    }

    function testProposeSetsCorrectVoteStartAndDuration() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        description = "Creating a proposal";
        lawCalldata = abi.encode(true);

        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        assertEq(daoMock.getActionDeadline(actionId), block.number + conditions.votingPeriod);
    }
}

contract CancelTest is TestSetupPowers {
    function testCancellingProposalsEmitsCorrectEvent() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.expectEmit(true, false, false, false);
        emit ProposedActionCancelled(actionId);
        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancellingProposalsSetsStateToCancelled() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Cancelled));
    }

    function testCancelRevertsWhenAccountDidNotCreateProposal() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.expectRevert(Powers__NotProposerAction.selector);
        vm.prank(helen);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelledProposalsCannotBeCancelledAgain() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);

        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelRevertsIfProposalAlreadyExecuted() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        targets = new address[](1);
        targets[0] = address(123);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encode("mockCall");

        lawCalldata = abi.encode(targets, values, calldatas);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + 1);
        vm.prank(bob);
        daoMock.request(lawId, lawCalldata, nonce, description);

        vm.expectRevert(Powers__UnexpectedActionState.selector);
        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }

    function testCancelRevertsIfLawNotActive() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);
    }
}

contract VoteTest is TestSetupPowers {
    function testVotingRevertsIfAccountNotAuthorised() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        address mockAddress = makeAddr("mock");
        assertFalse(daoMock.canCallLaw(mockAddress, lawId));

        vm.expectRevert(Powers__CannotCallLaw.selector);
        vm.prank(mockAddress);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalDefeatedIfQuorumNotReachedInTime() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        vm.roll(block.number + conditions.votingPeriod + 1);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));
    }

    function testVotingIsNotPossibleForDefeatedProposals() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        vm.roll(block.number + conditions.votingPeriod + 1);

        vm.expectRevert(Powers__ProposedActionNotActive.selector);
        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalSucceededIfQuorumReachedInTime() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + 1);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Succeeded));
    }

    function testVotesWithReasonsWorks() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVoteWithReason(actionId, FOR, "This is a test");
            }
        }
        vm.roll(block.number + conditions.votingPeriod + 1);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Succeeded));
    }

    function testProposalOutcomeVoteCounts() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        uint256 numberAgainstVotes;
        uint256 numberForVotes;
        uint256 numberAbstainVotes;
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                uint256 r = uint256(uint160(users[i])) % 3;
                if (r == 0) {
                    vm.prank(users[i]);
                    daoMock.castVote(actionId, AGAINST);
                    numberAgainstVotes++;
                } else if (r == 1) {
                    vm.prank(users[i]);
                    daoMock.castVote(actionId, FOR);
                    numberForVotes++;
                } else {
                    vm.prank(users[i]);
                    daoMock.castVote(actionId, ABSTAIN);
                    numberAbstainVotes++;
                }
            }
        }

        (,, uint256 voteEnd, uint32 againstVotes, uint32 forVotes, uint32 abstainVotes) = daoMock.getActionVoteData(actionId);
        assertEq(againstVotes, uint32(numberAgainstVotes));
        assertEq(forVotes, uint32(numberForVotes));
        assertEq(abstainVotes, uint32(numberAbstainVotes));
        assertEq(voteEnd, daoMock.getActionDeadline(actionId));
    }

    function testVoteRevertsWithInvalidVote() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(alice);
        vm.expectRevert(Powers__InvalidVoteType.selector);
        daoMock.castVote(actionId, 4);

        (,,, uint32 againstVotes, uint32 forVotes, uint32 abstainVotes) = daoMock.getActionVoteData(actionId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testHasVotedReturnCorrectData() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(alice);
        daoMock.castVote(actionId, ABSTAIN);

        assertTrue(daoMock.hasVoted(actionId, alice));
    }
}

contract ExecuteTest is TestSetupPowers {
    function testExecuteCanChangeState() public {
        lawId = 7; // A Single Action: to assign labels to roles. It self-destructs after execution.
        lawCalldata = abi.encode(true); // PresetSingleAction doesn't use this parameter, but we need to provide something

        // Check initial state - role labels should be empty
        assertEq(daoMock.getRoleLabel(ROLE_ONE), "");
        assertEq(daoMock.getRoleLabel(ROLE_TWO), "");
        assertTrue(daoMock.canCallLaw(alice, lawId)); // Alice is admin and can call law 7

        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // Check that role labels were assigned
        assertEq(daoMock.getRoleLabel(ROLE_ONE), "Member");
        assertEq(daoMock.getRoleLabel(ROLE_TWO), "Delegate");
    }

    function testExecuteSuccessSetsStateToFulfilled() public {
        lawId = 7; // A Single Action: to assign labels to roles. It self-destructs after execution.
        lawCalldata = abi.encode(true); // PresetSingleAction doesn't use this parameter, but we need to provide something

        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Fulfilled));
    }

    function testExecuteEmitsEvent() public {
        lawId = 7; // A Single Action: to assign labels to roles. It self-destructs after execution.
        lawCalldata = abi.encode(true); // PresetSingleAction doesn't use this parameter, but we need to provide something

        // Set up expected event data for law 7 (3 actions: label role 1, label role 2, revoke law 7)
        address[] memory tar = new address[](3);
        uint256[] memory val = new uint256[](3);
        bytes[] memory cal = new bytes[](3);
        
        tar[0] = address(daoMock);
        tar[1] = address(daoMock);
        tar[2] = address(daoMock);
        
        val[0] = 0;
        val[1] = 0;
        val[2] = 0;
        
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "Member");
        cal[1] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_TWO, "Delegate");
        cal[2] = abi.encodeWithSelector(daoMock.revokeLaw.selector, 7);
        
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        vm.expectEmit(true, false, false, false);
        emit ActionExecuted(lawId, actionId, tar, val, cal);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfNotAuthorised() public {
        lawId = 3; // Delegate Election - needs ROLE_ONE
        address[] memory addresses = new address[](1);
        addresses[0] = makeAddr("mock");
        lawCalldata = abi.encode(addresses);

        assertFalse(daoMock.canCallLaw(addresses[0], lawId));

        vm.expectRevert(Powers__CannotCallLaw.selector);
        vm.prank(addresses[0]);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfActionAlreadyExecuted() public {
        lawId = 4; // = ROle ONE
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "Member");

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        lawCalldata = abi.encode(tar, val, cal); 
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        vm.roll(block.number + conditions.votingPeriod + 1); 

        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        vm.expectRevert(Powers__ActionAlreadyInitiated.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfLawNotActive() public {
        lawId = 7; // A Single Action: to assign labels to roles. It self-destructs after execution.
        lawCalldata = abi.encode(true); // PresetSingleAction doesn't use this parameter, but we need to provide something

        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawId);

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalNeeded() public {
        lawId = 6; // Execute action - needs law 4 completed
        lawCalldata = abi.encode(true);

        vm.expectRevert(bytes("Parent law not completed"));
        vm.prank(charlotte);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalDefeated() public {
        lawId = 4; // = ROLE ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);

        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        vm.roll(block.number + conditions.votingPeriod + 1);
        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Defeated));

        vm.expectRevert(bytes("Proposal not succeeded"));
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteRevertsIfProposalCancelled() public {
        lawId = 4; // StatementOfIntent - needs ROLE_ONE
        lawCalldata = abi.encode(true);
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        vm.prank(bob);
        daoMock.cancel(lawId, lawCalldata, nonce);

        ActionState actionState = daoMock.getActionState(actionId);
        assertEq(uint8(actionState), uint8(ActionState.Cancelled));

        vm.expectRevert(Powers__ActionCancelled.selector);
        vm.prank(bob);
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

        LawInitData[] memory lawInitData = new LawInitData[](1);

        lawInitData[0] = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: lawAddresses[2], // = openAction
            config: abi.encode(),
            conditions: conditions
        });

        vm.prank(alice);
        daoMockTest.constitute(lawInitData);

        for (i = 1; i <= lawInitData.length; i++) {
            daoMockTest.getAdoptedLaw(uint16(i));
        }
    }

    function testConstituteRevertsOnSecondCall() public {
        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        LawInitData[] memory lawInitData = new LawInitData[](1);
        lawInitData[0] = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: lawAddresses[2], // = openAction
            config: abi.encode(),
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
            targetLaw: lawAddresses[2],
            config: abi.encode(),
            conditions: conditions
        });

        vm.expectRevert(Powers__NotAdmin.selector);
        vm.prank(bob);
        daoMockTest.constitute(lawInitData);
    }
}

contract SetLawTest is TestSetupPowers {
    function testSetLawSetsNewLaw() public {
        lawCount = daoMock.lawCount();
        newLaw = address(new OpenAction());

        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);

        (address law,,) = daoMock.getAdoptedLaw(lawCount);
        assertEq(law, newLaw, "New law should be active after adoption");
    }

    function testSetLawEmitsEvent() public {
        lawCount = daoMock.lawCount();
        newLaw = address(new OpenAction());

        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        vm.expectEmit(true, false, false, false);
        emit LawAdopted(uint16(lawCount));
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);
    }

    function testSetLawRevertsIfNotCalledFromPowers() public {
        newLaw = address(new OpenAction());

        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        vm.expectRevert(Powers__OnlyPowers.selector);
        vm.prank(alice);
        daoMock.adoptLaw(lawInitData);
    }

    function testSetLawRevertsIfAddressNotALaw() public {
        newLaw = address(3333);

        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        vm.expectRevert(Powers__IncorrectInterface.selector);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);
    }

    function testAdoptingSameLawTwice() public {
        newLaw = address(new OpenAction());

        vm.prank(alice);
        PowersMock daoMockTest = new PowersMock();

        LawInitData memory lawInitData = LawInitData({
            nameDescription: "Test law: Test law description",
            targetLaw: newLaw,
            config: abi.encode(),
            conditions: conditions
        });

        vm.prank(address(daoMockTest));
        daoMockTest.adoptLaw(lawInitData);

        vm.prank(address(daoMockTest));
        daoMockTest.adoptLaw(lawInitData);

        for (i = 1; i <= 2; i++) {
            (address law,,) = daoMockTest.getAdoptedLaw(uint16(i));
            assertEq(law, newLaw, "New law should be active after adoption");
        }
    }

    function testRevokeLawRevertsIfAddressNotActive() public {
        newLaw = address(new OpenAction());

        vm.prank(address(daoMock));
        daoMock.revokeLaw(1);

        vm.expectRevert(Powers__LawNotActive.selector);
        vm.prank(address(daoMock));
        daoMock.revokeLaw(1);
    }
}

contract SetRoleTest is TestSetupPowers {
    function testSetRoleSetsNewRole() public {
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
    }

    function testSetRoleRevertsWhenCalledFromOutsideProtocol() public {
        vm.prank(alice);
        vm.expectRevert(Powers__OnlyPowers.selector);
        daoMock.assignRole(ROLE_THREE, bob);
    }

    function testSetRoleEmitsCorrectEventIfAccountAlreadyHasRole() public {
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        vm.prank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit RoleSet(ROLE_ONE, bob, false);
        daoMock.assignRole(ROLE_ONE, bob);
    }

    function testAddingRoleAddsOneToAmountMembers() public {
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Role should be assigned");
        assertEq(amountMembersAfter, amountMembersBefore + 1, "Member count should increase by 1");
    }

    function testRemovingRoleSubtractsOneFromAmountMembers() public {
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        vm.prank(address(daoMock));
        daoMock.revokeRole(ROLE_ONE, bob);

        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0, "Role should be revoked");
        assertEq(amountMembersAfter, amountMembersBefore - 1, "Member count should decrease by 1");
    }

    function testSetRoleSetsEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit RoleSet(ROLE_THREE, helen, true);
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);
    }

    function testLabelRoleEmitsCorrectEvent() public {
        vm.expectEmit(true, false, false, false);
        emit RoleLabel(ROLE_THREE, "This is role three");
        vm.prank(address(daoMock));
        daoMock.labelRole(ROLE_THREE, "This is role three");
    }

    function testLabelRoleRevertsForLockedRoles() public {
        vm.expectRevert(Powers__LockedRole.selector);
        vm.prank(address(daoMock));
        daoMock.labelRole(ADMIN_ROLE, "Admin role");
    }
}

contract ComplianceTest is TestSetupPowers {
    function testErc721Compliance() public {
        uint256 nftToMint = 42;
        assertEq(SoulboundErc721(mockAddresses[2]).balanceOf(address(daoMock)), 0, "Initial balance should be 0");

        vm.prank(address(daoMock));
        SoulboundErc721(mockAddresses[2]).mintNFT(nftToMint, address(daoMock));

        assertEq(SoulboundErc721(mockAddresses[2]).balanceOf(address(daoMock)), 1, "Balance should be 1 after minting");
        assertEq(SoulboundErc721(mockAddresses[2]).ownerOf(nftToMint), address(daoMock), "NFT should be owned by DAO");
    }

    function testOnERC721Received() public {
        address sender = alice;
        address recipient = address(daoMock);
        uint256 tokenId = 42;
        bytes memory data = bytes(abi.encode(0));

        vm.prank(address(daoMock));
        (bytes4 response) = daoMock.onERC721Received(sender, recipient, tokenId, data);

        assertEq(response, daoMock.onERC721Received.selector, "Should return correct selector");
    }

    function testErc1155Compliance() public {
        uint256 numberOfCoinsToMint = 100;
        assertEq(SimpleErc1155(mockAddresses[3]).balanceOf(address(daoMock), 0), 0, "Initial balance should be 0");

        vm.prank(address(daoMock));
        SimpleErc1155(mockAddresses[3]).mintCoins(numberOfCoinsToMint);

        assertEq(
            SimpleErc1155(mockAddresses[3]).balanceOf(address(daoMock), 0), 100, "Balance should be 100 after minting"
        );
    }

    function testOnERC1155BatchReceived() public {
        address sender = alice;
        address recipient = address(daoMock);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        values = new uint256[](1);
        values[0] = 22;
        bytes memory data = bytes(abi.encode(0));

        vm.prank(address(daoMock));
        (bytes4 response) = daoMock.onERC1155BatchReceived(sender, recipient, tokenIds, values, data);

        assertEq(response, daoMock.onERC1155BatchReceived.selector, "Should return correct selector");
    }
}

