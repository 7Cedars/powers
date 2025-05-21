// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Law } from "../../src/Law.sol";

contract LawUtilitiesTest is TestSetupLaw {
    using LawUtilities for LawUtilities.TransactionsByAccount;

    LawUtilities.TransactionsByAccount transactions;

    //////////////////////////////////////////////////////////////
    //                  STRING VALIDATION                       //
    //////////////////////////////////////////////////////////////
    function testCheckStringLengthAcceptsValidName() public {
        // Should not revert with valid name
        LawUtilities.checkStringLength("Valid Law Name", 1, 31);
    }

    function testCheckStringLengthRevertsWithEmptyName() public {
        // Should revert with empty name
        vm.expectRevert(LawUtilities.LawUtilities__StringTooShort.selector);
        LawUtilities.checkStringLength("", 1, 31);
    }

    function testCheckStringLengthRevertsWithTooLongName() public {
        // Should revert with name longer than 31 characters
        vm.expectRevert(LawUtilities.LawUtilities__StringTooLong.selector);
        LawUtilities.checkStringLength("ThisNameIsWaaaaaayTooLongForALawName", 1, 31);
    }

    //////////////////////////////////////////////////////////////
    //                  PROPOSAL CHECKS                         //
    //////////////////////////////////////////////////////////////
    function testBaseChecksAtProposeWithNoParentRequirements() public {
        // Setup: Create conditions with no parent requirements
        lawCalldata = abi.encode(true);
        
        // Should not revert when no parent requirements
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, address(daoMock), nonce);
    }

    function testBaseChecksAtProposeWithParentCompletionRequired() public {
        // Setup: Create conditions requiring parent completion
        conditions.needCompleted = 1;
        lawCalldata = abi.encode(true);

        // Setup: Create and execute parent proposal
        vm.prank(alice);
        uint256 parentActionId = daoMock.propose(1, lawCalldata, nonce, "Parent proposal");
        
        // Vote for parent proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(1);
        conditions = Law(lawAddress).getConditions(address(daoMock), 1);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(parentActionId, FOR);
            }
        }

        // Execute parent proposal
        vm.roll(block.number + conditions.votingPeriod + 1);
        vm.prank(alice);
        daoMock.request(1, lawCalldata, nonce, "Execute parent");

        // Should not revert when parent is completed
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, address(daoMock), nonce);
    }

    function testBaseChecksAtProposeRevertsWhenParentNotCompleted() public {
        // Setup: Create conditions requiring parent completion
        conditions.needCompleted = 1;
        lawCalldata = abi.encode(true);

        // Should revert when parent is not completed
        vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, address(daoMock), nonce);
    }

    function testBaseChecksAtProposeWithParentBlocking() public {
        // Setup: Create conditions requiring parent not to be completed
        conditions.needNotCompleted = 1;
        lawCalldata = abi.encode(true);

        // Should not revert when parent is not completed
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, address(daoMock), nonce);
    }

    function testBaseChecksAtProposeRevertsWhenParentBlocks() public {
        // Setup: Create conditions requiring parent not to be completed        
        conditions.needNotCompleted = 5;
        lawCalldata = abi.encode(true);

        // Execute parent proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(5);
        ILaw.Conditions memory conditionsFive = Law(lawAddress).getConditions(address(daoMock), 5);

        vm.roll(block.number + conditionsFive.throttleExecution + 1);
        vm.prank(alice);
        daoMock.request(5, lawCalldata, nonce, "Execute parent");

        // Should revert when parent is completed
        vm.expectRevert(LawUtilities.LawUtilities__ParentBlocksCompletion.selector);
        LawUtilities.baseChecksAtPropose(conditions, lawCalldata, address(daoMock), nonce);
    }

    //////////////////////////////////////////////////////////////
    //                  EXECUTION CHECKS                        //
    //////////////////////////////////////////////////////////////
    function testBaseChecksAtExecuteWithNoRequirements() public {
        // Setup: Create conditions with no requirements
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        
        // Should not revert when no requirements
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteWithThrottle() public {
        // Setup: Create conditions with throttle
        conditions.throttleExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 200); // Last execution was 200 blocks ago
        
        // Should not revert when throttle period has passed
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteRevertsWithThrottle() public {
        // Setup: Create conditions with throttle        
        conditions.throttleExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 50); // Last execution was only 50 blocks ago
        
        // Should revert when throttle period hasn't passed
        vm.expectRevert(LawUtilities.LawUtilities__ExecutionGapTooSmall.selector);
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteWithProposalVote() public {
        // Setup: Create conditions requiring proposal vote
        conditions.quorum = 1;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);

        // Setup: Create and vote for proposal
        vm.prank(alice);
        actionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        
        // Vote for proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(4);
        conditions = Law(lawAddress).getConditions(address(daoMock), 4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // Advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // Should not revert when proposal has succeeded
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 4);
    }

    function testBaseChecksAtExecuteRevertsWithFailedProposal() public {
        // Setup: Create conditions requiring proposal vote
        conditions.quorum = 1;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);

        // Setup: Create and vote against proposal
        vm.prank(alice);
        actionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        
        // Vote against proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(4);
        conditions = Law(lawAddress).getConditions(address(daoMock), 4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }

        // Advance time past voting period
        vm.roll(block.number + conditions.votingPeriod + 1);

        // Should revert when proposal has failed
        vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 4);
    }

    function testBaseChecksAtExecuteWithDelay() public {
        // Setup: Create conditions with execution delay
        conditions.delayExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);

        // Setup: Create proposal
        vm.prank(alice);
        actionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        
        // Vote for proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(4);
        conditions = Law(lawAddress).getConditions(address(daoMock), 4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // Advance time past voting period and delay
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // Should not revert when delay has passed
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 4);
    }

    function testBaseChecksAtExecuteRevertsWithDelay() public {
        // Setup: Create conditions with execution delay        
        conditions.delayExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);

        // Setup: Create proposal
        vm.prank(alice);
        actionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        
        // Vote for proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(4);
        conditions = Law(lawAddress).getConditions(address(daoMock), 4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // Advance time past voting period but not past delay
        vm.roll(block.number + conditions.votingPeriod + 50);

        // Should revert when delay hasn't passed
        vm.expectRevert(LawUtilities.LawUtilities__DeadlineNotPassed.selector);
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 4);
    }

    function testBaseChecksAtExecuteWithMultipleThrottledExecutions() public {
        // Setup: Create conditions with throttle
        conditions.throttleExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](3);
        
        // Set up execution history
        executions[0] = uint48(block.number - 300); // First execution
        executions[1] = uint48(block.number - 200); // Second execution
        executions[2] = uint48(block.number - 50);  // Third execution (too recent)
        
        // Should revert when last execution is too recent
        vm.expectRevert(LawUtilities.LawUtilities__ExecutionGapTooSmall.selector);
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
        
        // Advance time past throttle period
        vm.roll(block.number + 100);
        
        // Should not revert when throttle period has passed
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteWithZeroThrottle() public {
        // Setup: Create conditions with zero throttle
        conditions.throttleExecution = 0;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 1); // Very recent execution
        
        // Should not revert when throttle is zero
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteWithEmptyExecutions() public {
        // Setup: Create conditions with throttle
        conditions.throttleExecution = 100;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](0);
        
        // Should not revert when no previous executions
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 1);
    }

    function testBaseChecksAtExecuteWithThrottleAndProposal() public {
        // Setup: Create conditions with both throttle and proposal requirements
        conditions.throttleExecution = 100;
        conditions.quorum = 1;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 200); // Last execution was 200 blocks ago

        // Setup: Create and vote for proposal
        vm.prank(alice);
        actionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        
        // Vote for proposal
        (lawAddress, lawHash, active) = daoMock.getActiveLaw(4);
        conditions = Law(lawAddress).getConditions(address(daoMock), 4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }

        // Advance time past voting period and delay
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // Should not revert when both throttle and proposal requirements are met
        LawUtilities.baseChecksAtExecute(conditions, lawCalldata, address(daoMock), nonce, executions, 4);
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////////
    function testHashActionId() public {
        uint16 lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, lawCalldata, nonce))));
    }

    function testHashLaw() public {
        uint16 lawId = 1;
        lawHash = LawUtilities.hashLaw(address(daoMock), lawId);
        assertEq(lawHash, keccak256(abi.encode(address(daoMock), lawId)));
    }

    function testCreateEmptyArrays() public {
        uint256 length = 3;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);

        assertEq(targets.length, length);
        assertEq(values.length, length);
        assertEq(calldatas.length, length);
    }

    //////////////////////////////////////////////////////////////
    //                  TRANSACTION TRACKING                    //
    //////////////////////////////////////////////////////////////
    function testLogTransaction() public {
        address account = alice;
        uint48 blockNumber = uint48(block.number);

        bool success = transactions.logTransaction(account, blockNumber);
        assertTrue(success);
        assertEq(transactions.transactions[account][0], blockNumber);
    }

    function testCheckThrottle() public {
        address account = alice;
        uint48 delay = 100;

        // Should pass when no previous transactions
        assertTrue(transactions.checkThrottle(account, delay));

        // Log a transaction
        transactions.logTransaction(account, uint48(block.number));

        // Should fail when delay hasn't passed
        vm.expectRevert("Delay not passed");
        transactions.checkThrottle(account, delay);

        // Should pass when delay has passed
        vm.roll(block.number + delay + 1);
        assertTrue(transactions.checkThrottle(account, delay));
    }

    function testCheckNumberOfTransactions() public {
        address account = alice;
        uint48 start = uint48(block.number);
        
        // Log some transactions
        transactions.logTransaction(account, start);
        transactions.logTransaction(account, start + 1);
        transactions.logTransaction(account, start + 2);

        uint48 end = start + 2;
        uint256 count = transactions.checkNumberOfTransactions(account, start, end);
        assertEq(count, 3);
    }
} 