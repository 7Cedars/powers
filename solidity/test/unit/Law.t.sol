// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Powers } from "../../src/Powers.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "../mocks/Erc1155Mock.sol";

//////////////////////////////////////////////////
//                  DEPLOY                      //
//////////////////////////////////////////////////
contract DeployTest is TestSetupLaw {
    function testDeployWithValidName() public {
        // prep: create a new law with valid name
        string memory lawName = "Test Law";
        Law lawMock = new OpenAction(lawName);

        // assert: verify name is set correctly
        assertEq(lawMock.name(), lawName);
    }

    function testDeployRevertsWithEmptyName() public {
        // act & assert: verify deployment reverts with empty name
        vm.expectRevert(Law__EmptyNameNotAllowed.selector);
        new OpenAction("");
    }

    function testDeployRevertsWithTooLongName() public {
        // prep: create a name that's too long (32 characters)
        string memory longName = "ThisNameIsWaaaaaayTooLongForALawName";

        // act & assert: verify deployment reverts with too long name
        vm.expectRevert(Law__StringTooLong.selector);
        new OpenAction(longName);
    }

    function testInitializeLawSetsCorrectState() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(lawMock);
        values[0] = 0;
        conditions.allowedRole = ROLE_ONE;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("initializeLaw(uint16,ILaw.Conditions,bytes,bytes,string)")), 2, conditions, abi.encode(ROLE_ONE), abi.encode("test"), "Test law initialization");

        // prep: create initialization data
        uint16 lawId = 2;
        bytes memory configLocal = abi.encode(
            targets,
            values,
            calldatas
        );
        description = "Test law initialization";

        // act: initialize the law
        lawMock.initializeLaw(lawId, conditions, configLocal, "", description);

        // assert: verify conditions are set correctly
        (conditions) = lawMock.getConditions(lawId);
        assertEq(conditions.allowedRole, ROLE_ONE);
        assertEq(conditions.quorum, 0);
        assertEq(conditions.succeedAt, 0);
        assertEq(conditions.votingPeriod, 0);
    }

    function testInitializeLawEmitsEvent() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(lawMock);
        values[0] = 0;
        conditions.allowedRole = ROLE_ONE;
        bytes memory configLocal = abi.encode(
            targets,
            values,
            calldatas
        );
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("initializeLaw(uint16,ILaw.Conditions,bytes,bytes,string)")), 2, conditions, configLocal, "", "Test law initialization");

        // prep: create initialization data
        uint16 lawId = 2;

        description = "Test law initialization";

        // assert: verify event is emitted
        vm.expectEmit(true, false, false, false);
        emit ILaw.Law__Initialized(address(daoMock), lawId, conditions, "", description);
        vm.prank(address(daoMock));
        lawMock.initializeLaw(lawId, conditions, configLocal, "", description);
    }

    function testExecuteLawRevertsIfNotCalledFromPowers() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");

        // prep: initialize the law
        uint16 lawId = 1;
        bytes memory configLocal = abi.encode(ROLE_ONE);
        bytes memory inputParams = abi.encode("test");
        description = "Test law initialization";
        lawMock.initializeLaw(lawId, conditions, configLocal, inputParams, description);

        // act: try to execute from non-powers address
        vm.expectRevert(Law__OnlyPowers.selector);
        vm.prank(alice);
        lawMock.executeLaw(alice, lawId, abi.encode(true), nonce);
    }

    function testHashActionIdReturnsConsistentHash() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");

        // prep: create test data
        uint16 lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        // act: hash the action ID
        actionId = lawMock.hashActionId(lawId, lawCalldata, nonce);

        // assert: verify hash is consistent
        assertEq(
            actionId,
            uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)))
        );
    }

    function testHashLawReturnsConsistentHash() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");

        // prep: create test data
        uint16 lawId = 1;

        // act: hash the law
        lawHash = lawMock.hashLaw(address(daoMock), lawId);

        // assert: verify hash is consistent
        assertEq(
            lawHash,
            keccak256(abi.encode(address(daoMock), lawId))
        );
    }

    function testCreateEmptyArraysReturnsCorrectArrays() public {
        // prep: create a new law
        Law lawMock = new OpenAction("Test Law");

        // act: create empty arrays
        uint256 length = 3;
        (targets, values, calldatas) = lawMock.createEmptyArrays(length);

        // assert: verify arrays are created with correct length
        assertEq(targets.length, length);
        assertEq(values.length, length);
        assertEq(calldatas.length, length);
    }
}

//////////////////////////////////////////////////
//                   CONFIG                     //
//////////////////////////////////////////////////
contract NeedsProposalVoteTest is TestSetupLaw {
    function testExecuteLawSucceedsWithSuccessfulVote() public {
        uint16 lawId = 4; 

        // prep: create a new law
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);
        
        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (,, conditions) = daoMock.getActiveLaw(lawId);

        // prep: vote for the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // act: execute the proposal
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify execution
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testLawRevertsWithUnsuccessfulVote() public {
        // prep: create a new law
        uint16 lawId = 4;
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (,, conditions) = daoMock.getActiveLaw(lawId);

        // prep: vote against the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // act & assert: verify execution reverts
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testLawRevertsIfVoteStillActive() public {
        // prep: create a new law
        uint16 lawId = 4;
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (,, conditions) = daoMock.getActiveLaw(lawId);

        // prep: vote against the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod - 1);
 
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }
}

contract NeedsParentCompletedTest is TestSetupLaw {
    function testLawSucceedsIfParentCompleted() public {
        // prep: create a parent proposal, vote & execute.
        uint16 lawId = 2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);

        // First execute parent law
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (,, conditions) = daoMock.getActiveLaw(parentLawNumber);

        // Loop through users, they vote for the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time

        // Execute parent law
        vm.prank(alice);
        daoMock.request(parentLawNumber, lawCalldata, nonce, description);

        // Verify parent law state
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Fulfilled));

        // Record balance before executing dependent law
        uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

        // Now execute the dependent law
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // Verify the execution succeeded by checking balance change
        uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balanceBefore + 123, balanceAfter);
    }

    function testLawRevertsIfParentNotCompleted() public {
        // prep: create a parent proposal and have it be defeated
        uint16 lawId =2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);

        // Create and vote against parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (,, conditions) = daoMock.getActiveLaw(parentLawNumber);

        // Loop through users, they vote against the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, AGAINST);
            }
        }
        vm.roll(block.number + 4000); // forward in time

        // Verify parent proposal was defeated
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Defeated));

        // Attempt to execute dependent law - should revert
        vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testLawRevertsIfParentNotFulfilled() public {
        // prep: create a parent proposal that succeeds vote but isn't executed
        uint16 lawId = 2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("mintCoins(uint256)")), 123);
        lawCalldata = abi.encode(targets, values, calldatas);

        // Create and vote for parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (,, conditions) = daoMock.getActiveLaw(parentLawNumber);

        // Loop through users, they vote for the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time

        // Verify parent proposal succeeded but not executed
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Succeeded));

        // Attempt to execute dependent law - should revert
        vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }
}

// contract ParentCanBlockTest is TestSetupLaw {
//     function testLawRevertsIfParentHasCompleted() public {
//         // prep: create a parent proposal and execute it
//         uint16 lawId = 2;
//         uint16 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);

//         // Create and vote for parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(lawId).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time

//         // Execute parent law
//         vm.prank(alice);
//         daoMock.request(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Verify parent law is fulfilled
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Fulfilled));

//         // Attempt to execute blocked law - should revert
//         vm.expectRevert(LawUtilities.LawUtilities__ParentBlocksCompletion.selector);
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, description);
//     }

//     function testLawSucceedsIfParentHasNotCompleted() public {
//         // prep: create a parent proposal and have it be defeated
//         uint16 lawId = 2;
//         uint16 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);

//         // Create and vote against parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote against the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(lawId).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, AGAINST);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time

//         // Verify parent proposal was defeated
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Defeated));

//         // Record balance before executing blocked law
//         uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

//         // Execute blocked law - should succeed since parent is not fulfilled
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, description);

//         // Verify the execution succeeded by checking balance change
//         uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balanceBefore + 123, balanceAfter);
//     }

//     function testLawSucceedsIfParentNotExecuted() public {
//         // prep: create a parent proposal that succeeds vote but isn't executed
//         uint16 lawId = 2;
//         uint16 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);

//         // Create and vote for parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(lawId).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time

//         // Verify parent proposal succeeded but wasn't executed
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Succeeded));

//         // Record balance before executing blocked law
//         uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

//         // Execute blocked law - should succeed since parent is not fulfilled
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, description);

//         // Verify the execution succeeded by checking balance change
//         uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balanceBefore + 123, balanceAfter);
//     }
// }

// contract DelayProposalExecutionTest is TestSetupLaw {
//     function testExecuteLawSucceedsAfterDelay() public {
//         // prep: create a proposal
//         uint16 lawId = 3;
//         description = "Executing a delayed proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(lawId).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         vm.roll(block.number + 10_000); // forward in time, past the delay.
//         // act
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, description);

//         // assert
//         uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balance, 123);
//     }

//     function testExecuteLawRevertsBeforeDelay() public {
//         // prep: create a proposal
//         uint16 lawId = 3;
//         description = "Executing a delayed proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(lawId).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time, but NOT past the delay.
//         // act & assert
//         vm.expectRevert(LawUtilities.LawUtilities__DeadlineNotPassed.selector);
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, description);
//     }
// }

// contract LimitExecutionsTest is TestSetupLaw {
//     function testExecuteSucceedsWithinLimits() public {
//         // prep: create a proposal
//         uint16 lawId = 4;
//         uint256 numberOfExecutions = 5;
//         uint256 numberOfBlockBetweenExecutions = 15;
//         lawCalldata = abi.encode(true);

//         // act
//         for (i = 0; i < numberOfExecutions; i++) {
//             vm.roll(block.number + block.number + numberOfBlockBetweenExecutions);
//             vm.prank(alice);
//             daoMock.request(lawId, lawCalldata, nonce, string(abi.encode(i)));
//             nonce++;
//         }

//         // assert
//         uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balance, 123 * numberOfExecutions);
//     }

//     function testExecuteRevertsIfGapTooSmall() public {
//         // prep: execute 10 times
//         uint16 lawId = 4;
//         lawCalldata = abi.encode(true);
//         // prep: execute once...
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, "first execute");

//         // act & assert: execute twice, very soon after.
//         vm.roll(block.number + 5);
//         nonce++;
//         vm.expectRevert(LawUtilities.LawUtilities__ExecutionGapTooSmall.selector);
//         vm.prank(alice);
//         daoMock.request(lawId, lawCalldata, nonce, "second execute");
//     }
// }
