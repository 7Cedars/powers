// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and contracts have not been extensively audited.   ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title ChecksTest - Unit tests for Checks library
/// @notice Tests the Checks library functions
/// @dev Provides comprehensive coverage of all Checks functions
/// @author 7Cedars

pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { Powers } from "../../src/Powers.sol";
import { Checks } from "../../src/libraries/Checks.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { TestSetupPowers } from "../TestSetup.t.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Law } from "../../src/Law.sol";

contract ChecksTest is TestSetupPowers {
    //////////////////////////////////////////////////////////////
    //                  PROPOSAL CHECKS                         //
    //////////////////////////////////////////////////////////////
    function testChecksAtProposeWithNoParentRequirements() public {
        // Setup: Create conditions with no parent requirements
        lawCalldata = abi.encode(true);

        // Should not revert when no parent requirements
        Checks.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    function testChecksAtProposeRevertsWhenParentNotCompleted() public {
        // Setup: Create conditions requiring parent completion
        lawId = 5; // = Veto action with condition that law 4 needs to be completed
        lawCalldata = abi.encode();

        // Should revert when parent is not completed
        vm.expectRevert("Parent law not completed");
        Checks.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    function testChecksAtProposeWithParentBlocking() public {
        // Setup: Test law 6 (Execute action) which requires law 5 (Veto action) to NOT be completed
        lawId = 6; // Execute action - needs law 4 completed and law 5 NOT completed
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // Step 1: Create and vote on a proposal using law 4 (StatementOfIntent)
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");

        // Vote for the proposal
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(4);
        conditions = daoMock.getConditions(4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }

        // Advance time past voting period and execute law.
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);
        vm.prank(alice);
        daoMock.request(4, lawCalldata, nonce, "Test proposal");

        // now we execute law 5
        vm.prank(alice);
        daoMock.request(5, lawCalldata, nonce, "Test proposal");

        // Step 2: Now test that law 6 is blocked because law 5 was completed
        vm.expectRevert("Parent law blocks completion");
        Checks.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    //////////////////////////////////////////////////////////////
    //                  REQUEST CHECKS                          //
    //////////////////////////////////////////////////////////////
    function testChecksAtRequestWithNoRequirements() public {
        // Setup: Create conditions with no requirements
        lawCalldata = abi.encode(true);
        uint48 latestExecution;

        // Should not revert when no requirements
        Checks.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, latestExecution);
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////////
    function testHashActionId() public {
        lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        actionId = Checks.hashActionId(lawId, lawCalldata, nonce);
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, lawCalldata, nonce))));
    }

    function testGetConditions() public {
        // Test getting conditions for an existing law
        PowersTypes.Conditions memory conditionsResult = Checks.getConditions(address(daoMock), 1);

        // Verify we get valid conditions back
        assertTrue(conditionsResult.allowedRole != 0 || conditionsResult.allowedRole == type(uint256).max);
    }

    function testChecksAtRequestWithZeroThrottle() public {
        // Setup: Use lawId 6 from powersTestConstitution which has no throttle (throttleExecution = 0)
        // it does have a parentLaw needFulfilled, so we need to complete it.
        lawId = 6;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);
        uint48 latestExecution = uint48(block.number - 1); // Very recent execution

        // First, we need to vote on law 4
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(4);
        conditions = daoMock.getConditions(4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);
        vm.prank(alice);
        daoMock.request(4, lawCalldata, nonce, "Test proposal");

        // now we execute law 6
        // Should not revert when throttle is zero
        Checks.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, latestExecution);
    }

    function testGetConditionsForNonExistentLaw() public {
        // Test getting conditions for a non-existent law
        PowersTypes.Conditions memory conditionsResult = Checks.getConditions(address(daoMock), 999);

        // Should return default/empty conditions
        assertEq(conditionsResult.allowedRole, 0);
        assertEq(conditionsResult.quorum, 0);
        assertEq(conditionsResult.succeedAt, 0);
        assertEq(conditionsResult.votingPeriod, 0);
        assertEq(conditionsResult.needFulfilled, 0);
        assertEq(conditionsResult.needNotFulfilled, 0);
        assertEq(conditionsResult.delayExecution, 0);
        assertEq(conditionsResult.throttleExecution, 0);
    }

    //////////////////////////////////////////////////////////////
    //                  DELAY EXECUTION CHECKS                   //
    //////////////////////////////////////////////////////////////
    function testChecksAtRequestWithDelayExecution() public {
        // Setup: Use lawId 4 from powersTestConstitution which now has delayExecution = 250
        lawId = 4;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // First, we need to vote on law 4
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(4);
        conditions = daoMock.getConditions(4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }

        // Advance time past voting period and execute law 4
        vm.roll(block.number + conditions.votingPeriod + 1);

        // First execution should not succeed (there is also a delay for the first execution)
        vm.prank(alice);
        vm.expectRevert("Deadline not passed");
        daoMock.request(lawId, lawCalldata, nonce, "First execution");
    }

    function testChecksAtRequestWithDelayExecutionPassed() public {
        // Setup: Use lawId 4 from powersTestConstitution which now has delayExecution = 250
        lawId = 4;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // First, we need to vote on law 4
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(4, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(4);
        conditions = daoMock.getConditions(4);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }

        // Advance blocks past the delay period (250 blocks)
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 1);

        // Second execution should succeed now that delay has passed
        vm.prank(alice);
        uint256 secondActionId = daoMock.request(lawId, lawCalldata, nonce, "Second execution after delay");
        assertTrue(daoMock.getActionState(secondActionId) == ActionState.Fulfilled);
    }

    function testChecksAtRequestWithZeroDelayExecution() public {
        // Setup: Use lawId 1 from powersTestConstitution which has no delay (delayExecution = 0)
        lawId = 1;
        bytes[] memory encodedParams = new bytes[](1);
        encodedParams[0] = abi.encode(alice);
        lawCalldata = abi.encode(encodedParams); // Law 1 expects a bytes[] with an address parameter

        // First execution should succeed
        vm.prank(alice);
        uint256 firstActionId = daoMock.request(lawId, lawCalldata, nonce, "First execution");
        assertTrue(daoMock.getActionState(firstActionId) == ActionState.Fulfilled);

        // Second execution should also succeed immediately (no delay)
        vm.prank(alice);
        uint256 secondActionId = daoMock.request(lawId, lawCalldata, nonce + 1, "Second execution immediately");
        assertTrue(daoMock.getActionState(secondActionId) == ActionState.Fulfilled);
    }

    //////////////////////////////////////////////////////////////
    //                  THROTTLE EXECUTION CHECKS                //
    //////////////////////////////////////////////////////////////
    function testChecksAtRequestWithThrottleExecutionGapTooSmall() public {
        // Setup: Use lawId 5 from lawTestConstitution which has throttleExecution = 5000
        lawId = 4;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // we first propose, vote and execute law 4.
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(lawId, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 10_000);

        // Create latestExecution array with recent execution (gap too small)
        uint48 latestExecution = uint48(block.number - 1000); 

        // Should revert when execution gap is too small
        vm.expectRevert("Execution gap too small");
        Checks.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, latestExecution);
    }

    function testChecksAtRequestWithThrottleExecutionGapSufficient() public {
        // Setup: Use lawId 5 from lawTestConstitution which has throttleExecution = 5000
        lawId = 4;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // we first propose, vote and execute law 4.
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(lawId, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 10_000);

        // Create latestExecution array with sufficient gap
        uint48 latestExecution = uint48(block.number - 6000);

        // Should not revert when execution gap is sufficient
        Checks.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, latestExecution);
    }

    function testChecksAtRequestWithThrottleExecutionExactlyAtThreshold() public {
        // Setup: Use lawId 5 from lawTestConstitution which has throttleExecution = 5000
        lawId = 4;
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // we first propose, vote and execute law 4.
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(lawId, lawCalldata, nonce, "Test proposal");
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(lawId);
        conditions = daoMock.getConditions(lawId);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }
        vm.roll(block.number + conditions.votingPeriod + conditions.delayExecution + 10_000);

        // Create latestExecution array with exactly the throttle threshold
        uint48 latestExecution = uint48(block.number - 5000);

        // Should not revert when execution gap equals throttle threshold
        Checks.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, latestExecution);
    }
}
