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
    function testInitializeLawSetsCorrectState() public {
        // prep: create a new law
        Law lawMock = new OpenAction();
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(lawMock);
        values[0] = 0;
        conditions.allowedRole = ROLE_ONE;
        calldatas[0] = abi.encodeWithSelector(bytes4(keccak256("initializeLaw(uint16,ILaw.Conditions,bytes,bytes,string)")), 2, conditions, abi.encode(ROLE_ONE), abi.encode("test"), "Test law initialization");

        // prep: create initialization data
        lawId = 2;
        bytes memory configLocal = abi.encode(
            targets,
            values,
            calldatas
        );
        nameDescription = "Test law";
        inputParams = abi.encode("test");

        // act: initialize the law
        vm.prank(address(daoMock));
        lawMock.initializeLaw(lawId, nameDescription, inputParams, conditions, configLocal); 

        // assert: verify conditions are set correctly
        (conditions) = lawMock.getConditions(address(daoMock), lawId);
        assertEq(conditions.allowedRole, ROLE_ONE);
        assertEq(conditions.quorum, 0);
        assertEq(conditions.succeedAt, 0);
        assertEq(conditions.votingPeriod, 0);
    }

    function testInitializeLawEmitsEvent() public {
        // prep: create a new law
        Law lawMock = new OpenAction();
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
        lawId = 2;
        
        nameDescription = "Test law";
        inputParams = abi.encode("test");

        // assert: verify event is emitted
        vm.expectEmit(true, false, false, false);
        emit ILaw.Law__Initialized(address(daoMock), lawId, nameDescription, inputParams, conditions, configLocal);
        vm.prank(address(daoMock));
        lawMock.initializeLaw(lawId, nameDescription, inputParams, conditions, configLocal); 
    }

    function testExecuteLawRevertsIfNotCalledFromPowers() public {
        // prep: create a new law
        Law lawMock = new OpenAction();

        // prep: initialize the law
        lawId = 1;
        bytes memory configLocal = abi.encode(ROLE_ONE);
        inputParams = abi.encode("test");
        nameDescription = "Test law";
        lawMock.initializeLaw(lawId, nameDescription, inputParams, conditions, configLocal);

        // act: try to execute from non-powers address
        vm.expectRevert(Law__OnlyPowers.selector);
        vm.prank(alice);
        lawMock.executeLaw(alice, lawId, abi.encode(true), nonce);
    }

    function testHashActionIdReturnsConsistentHash() public {
        // prep: create a new law
        Law lawMock = new OpenAction();

        // prep: create test data
        lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        // act: hash the action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // assert: verify hash is consistent
        assertEq(
            actionId,
            uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)))
        );
    }

    function testHashLawReturnsConsistentHash() public {
        // prep: create a new law
        Law lawMock = new OpenAction();

        // prep: create test data
        lawId = 1;

        // act: hash the law
        lawHash = LawUtilities.hashLaw(address(daoMock), lawId);

        // assert: verify hash is consistent
        assertEq(
            lawHash,
            keccak256(abi.encode(address(daoMock), lawId))
        );
    }

    function testCreateEmptyArraysReturnsCorrectArrays() public {
        // prep: create a new law
        Law lawMock = new OpenAction();

        // act: create empty arrays
        uint256 length = 3;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);

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
        lawId = 4; 

        // prep: create a new law
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);
        
        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        // prep: get conditions for voting
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

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
        uint256 balance = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testLawRevertsWithUnsuccessfulVote() public {
        // prep: create a new law
        lawId = 4;
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

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
        lawId = 4;
        description = "Executing a proposal vote"; 
        lawCalldata = abi.encode(true);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

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
        lawId = 2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);
        lawCalldata = abi.encode(targets, values, calldatas);

        // First execute parent law
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

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
        uint256 balanceBefore = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);

        // Now execute the dependent law
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // Verify the execution succeeded by checking balance change
        uint256 balanceAfter = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balanceBefore + 123, balanceAfter);
    }

    function testLawRevertsIfParentNotCompleted() public {
        // prep: create a parent proposal and have it be defeated
        lawId =2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // Create and vote against parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

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
        lawId = 2;
        uint16 parentLawNumber = 1;
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // Create and vote for parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting  
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

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

contract ParentCanBlockTest is TestSetupLaw {
    function testLawRevertsIfParentHasCompleted() public {
        // prep: create a parent proposal and execute it
        lawId = 3; // Using lawId 3 as it's the one with needNotCompleted = 1
        uint16 parentLawNumber = 1; // Using lawId 1 as parent
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create and vote for parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

        // prep: vote for the parent proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, FOR);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // act: execute parent law
        vm.prank(alice);
        daoMock.request(parentLawNumber, lawCalldata, nonce, description);

        // assert: verify parent law state
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Fulfilled));

        // act & assert: verify execution of blocked law reverts
        vm.expectRevert(LawUtilities.LawUtilities__ParentBlocksCompletion.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testLawSucceedsIfParentHasNotCompleted() public {
        // prep: create a parent proposal and have it be defeated
        lawId = 3; // Using lawId 3 as it's the one with needNotCompleted = 1
        uint16 parentLawNumber = 1; // Using lawId 1 as parent
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create and vote against parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

        // prep: vote against the parent proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, AGAINST);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert: verify parent proposal was defeated
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Defeated));

        // prep: record balance before executing blocked law
        uint256 balanceBefore = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);

        // act: execute blocked law
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify the execution succeeded by checking balance change
        uint256 balanceAfter = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balanceBefore + 123, balanceAfter);
    }

    function testLawSucceedsIfParentNotExecuted() public {
        // prep: create a parent proposal that succeeds vote but isn't executed
        lawId = 3; // Using lawId 3 as it's the one with needNotCompleted = 1
        uint16 parentLawNumber = 1; // Using lawId 1 as parent
        description = "Executing a proposal vote";
        lawCalldata = abi.encode(true);

        // prep: assign role to alice
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // prep: create and vote for parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(parentLawNumber, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(parentLawNumber);
        conditions = Law(lawAddress).getConditions(address(daoMock), parentLawNumber);

        // prep: vote for the parent proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, FOR);
            }
        }

        // prep: advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // assert: verify parent proposal succeeded but wasn't executed
        ActionState parentState = daoMock.state(parentActionId);
        assertEq(uint8(parentState), uint8(ActionState.Succeeded));

        // prep: record balance before executing blocked law
        uint256 balanceBefore = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);

        // act: execute blocked law
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify the execution succeeded by checking balance change
        uint256 balanceAfter = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balanceBefore + 123, balanceAfter);
    }
}

contract DelayProposalExecutionTest is TestSetupLaw {
   function testExecuteLawSucceedsAfterDelay() public {
        // prep: create a new law
        lawId = 4; // Using lawId 4 as it's the one with delayExecution = 5000
        description = "Executing a delayed proposal vote";
        lawCalldata = abi.encode(true);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: vote for the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // prep: advance time past voting period and delay
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // act: execute the proposal
        vm.prank(bob);
        daoMock.request(lawId, lawCalldata, nonce, description);

        // assert: verify execution
        uint256 balance = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testExecuteLawRevertsBeforeDelay() public {
        // prep: create a new law
        lawId = 4; // Using lawId 4 as it's the one with delayExecution = 5000
        description = "Executing a delayed proposal vote";
        lawCalldata = abi.encode(true);

        // prep: create proposal
        vm.prank(bob);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: vote for the proposal  
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // prep: advance time past voting period but not past delay
        vm.roll(block.number + conditions.votingPeriod + 1);

        // act & assert: verify execution reverts before delay
        vm.expectRevert(LawUtilities.LawUtilities__DeadlineNotPassed.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteLawRevertsIfVoteNotSucceeded() public {
        // prep: create a new law
        lawId = 4; // Using lawId 4 as it's the one with delayExecution = 5000
        description = "Executing a delayed proposal vote";
        lawCalldata = abi.encode(true);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: vote against the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // prep: advance time past voting period and delay
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // act & assert: verify execution reverts if vote didn't succeed
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }

    function testExecuteLawRevertsIfVoteStillActive() public {
        // prep: create a new law
        lawId = 4; // Using lawId 4 as it's the one with delayExecution = 5000
        description = "Executing a delayed proposal vote";
        lawCalldata = abi.encode(true);

        // prep: create proposal
        vm.prank(alice);
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        // prep: get conditions for voting
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // prep: vote for the proposal
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // prep: advance time but not past voting period
        vm.roll(block.number + conditions.votingPeriod - 1);

        // act & assert: verify execution reverts if vote still active
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, description);
    }
}

contract LimitExecutionsTest is TestSetupLaw {
    function testExecuteSucceedsWithinLimits() public {
        // prep: create a new law
        lawId = 5; // Using lawId 5 as it's the one with throttle execution
        description = "Executing a throttled proposal";
        lawCalldata = abi.encode(true);
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: execute multiple times with sufficient delay
        uint256 numberOfExecutions = 5;
        uint256 balanceBefore = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);

        for (i = 0; i < numberOfExecutions; i++) {     
            // Advance time past voting period and delay
            vm.roll(block.number + conditions.throttleExecution + 1);

            // Execute the proposal
            vm.prank(alice);
            daoMock.request(lawId, lawCalldata, nonce, description);
            nonce++;
        }

        // assert: verify total balance change
        uint256 balanceAfter = Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0);
        assertEq(balanceAfter - balanceBefore, 123 * numberOfExecutions);
    }

    function testExecuteRevertsIfGapTooSmall() public {
        // prep: create a new law
        lawId = 5; // Using lawId 5 as it's the one with throttle execution
        description = "Executing a throttled proposal";
        lawCalldata = abi.encode(true);

        (lawAddress, lawHash, active) = daoMock.getActiveLaw(lawId);
        conditions = Law(lawAddress).getConditions(address(daoMock), lawId);

        // act: execute first proposal
        vm.roll(block.number + conditions.throttleExecution + 1);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, "first execute");
        nonce++;

        // prep: advance time past voting period but not enough delay
        vm.roll(block.number + 5);

        // act & assert: verify execution reverts if gap too small
        vm.expectRevert(LawUtilities.LawUtilities__ExecutionGapTooSmall.selector);
        vm.prank(alice);
        daoMock.request(lawId, lawCalldata, nonce, "second execute");
    }
} 