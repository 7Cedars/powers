// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { PowersUtilities } from "../../src/PowersUtilities.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { TestSetupUtilities } from "../TestSetup.t.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Law } from "../../src/Law.sol";

contract PowersUtilitiesTest is TestSetupUtilities {
    //////////////////////////////////////////////////////////////
    //                  PROPOSAL CHECKS                         //
    //////////////////////////////////////////////////////////////
    function testChecksAtProposeWithNoParentRequirements() public {
        // Setup: Create conditions with no parent requirements
        lawCalldata = abi.encode(true);

        // Should not revert when no parent requirements
        PowersUtilities.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    function testChecksAtProposeRevertsWhenParentNotCompleted() public {
        // Setup: Create conditions requiring parent completion
        lawId = 2; // = PresetSingleAction with condition that law 1 needs to be completed
        lawCalldata = abi.encode();

        // Should revert when parent is not completed
        vm.expectRevert("Parent law not completed");
        PowersUtilities.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    function testChecksAtProposeWithParentBlocking() public {
        // Setup: Test law 6 (Execute action) which requires law 5 (Veto action) to NOT be completed
        lawId = 3; // Execute action - needs law 1 NOT completed
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "TestMember");
        lawCalldata = abi.encode(tar, val, cal);

        // Step 1: Create and vote on a proposal using law 4 (StatementOfIntent)
        vm.prank(bob);
        uint256 proposalActionId = daoMock.propose(1, lawCalldata, nonce, "Test proposal");

        // Vote for the proposal
        (lawAddress, lawHash, active) = daoMock.getAdoptedLaw(1);
        conditions = daoMock.getConditions(1);
        for (i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], conditions.allowedRole) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(proposalActionId, FOR);
            }
        }

        // Advance time past voting period and execute law. 
        vm.roll(block.number + conditions.votingPeriod + 1);
        vm.prank(alice);
        daoMock.request(1, lawCalldata, nonce, "Test proposal");

        // Step 2: Now test that law 6 is blocked because law 5 was completed
        vm.expectRevert("Parent law blocks completion");
        PowersUtilities.checksAtPropose(lawId, lawCalldata, address(daoMock), nonce);
    }

    //////////////////////////////////////////////////////////////
    //                  REQUEST CHECKS                          //
    //////////////////////////////////////////////////////////////
    function testChecksAtRequestWithNoRequirements() public {
        // Setup: Create conditions with no requirements
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);

        // Should not revert when no requirements
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, executions);
    }

    function testChecksAtRequestRevertsWithThrottle() public {
        // Setup: Use lawId 5 from utilities test constitution which has throttleExecution = 5000
        lawId = 5;
        
        vm.roll(block.number + 1250);
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 1000); // Last execution was only 1000 blocks ago (less than 5000 throttle)

        // Should revert when throttle period hasn't passed
        vm.expectRevert("Execution gap too small");
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, executions);
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////////
    function testHashActionId() public {
        lawId = 1;
        lawCalldata = abi.encode(true);
        nonce = 123;

        actionId = PowersUtilities.hashActionId(lawId, lawCalldata, nonce);
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, lawCalldata, nonce))));
    }

    function testGetConditions() public view {
        // Test getting conditions for an existing law
        PowersTypes.Conditions memory conditionsResult = PowersUtilities.getConditions(address(daoMock), 1);
        
        // Verify we get valid conditions back
        assertTrue(conditionsResult.allowedRole != 0 || conditionsResult.allowedRole == type(uint256).max);
    }

    function testChecksAtRequestWithThrottle() public {
        // Setup: Use lawId 5 from utilities test constitution which has throttleExecution = 5000
        lawId = 5;
        vm.roll(block.number + 6250);
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 6000); // Last execution was 6000 blocks ago (more than 5000 throttle)

        // Should not revert when throttle period has passed
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, executions);
    }

    function testChecksAtRequestWithEmptyExecutions() public {
        // Setup: Use lawId 5 from utilities test constitution which has throttleExecution = 5000
        lawId = 5;
        lawCalldata = abi.encode(true);
        uint48[] memory executions = new uint48[](0);

        // Should not revert when no previous executions
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, executions);
    }

    function testChecksAtRequestWithZeroThrottle() public {
        // Setup: Use lawId 6 from utilities test constitution which has no throttle (throttleExecution = 0)
        lawId = 6;
        lawCalldata = abi.encode();
        uint48[] memory executions = new uint48[](1);
        executions[0] = uint48(block.number - 1); // Very recent execution

        // Should not revert when throttle is zero
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(daoMock), nonce, executions);
    }

    function testGetConditionsForNonExistentLaw() public view {
        // Test getting conditions for a non-existent law
        PowersTypes.Conditions memory conditionsResult = PowersUtilities.getConditions(address(daoMock), 999);
        
        // Should return default/empty conditions
        assertEq(conditionsResult.allowedRole, 0);
        assertEq(conditionsResult.quorum, 0);
        assertEq(conditionsResult.succeedAt, 0);
        assertEq(conditionsResult.votingPeriod, 0);
        assertEq(conditionsResult.needCompleted, 0);
        assertEq(conditionsResult.needNotCompleted, 0);
        assertEq(conditionsResult.delayExecution, 0);
        assertEq(conditionsResult.throttleExecution, 0);
    }
}