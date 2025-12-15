// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupExecutive, TestSetupMulti } from "../../TestSetup.t.sol";
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { OpenAction } from "../../../src/mandates/executive/OpenAction.sol";
import { PresetSingleAction } from "../../../src/mandates/executive/PresetSingleAction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { StatementOfIntent } from "../../../src/mandates/executive/StatementOfIntent.sol";
import { BespokeActionSimple } from "../../../src/mandates/executive/BespokeActionSimple.sol";
import { PresetMultipleActions } from "../../../src/mandates/executive/PresetMultipleActions.sol";
import { BespokeActionAdvanced } from "../../../src/mandates/executive/BespokeActionAdvanced.sol";
import { CheckExternalActionState } from "../../../src/mandates/executive/CheckExternalActionState.sol";

/// @notice Comprehensive unit tests for all executive mandates
/// @dev Tests all functionality of executive mandates including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              OPEN ACTION TESTS              //
//////////////////////////////////////////////////
contract OpenActionTest is TestSetupMulti {
    OpenAction openAction;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(mandateAddresses[3]); // OpenAction from multi constitution
        mandateId = 1; // OpenAction mandate ID in multi constitution
    }

    function testOpenActionInitialization() public {
        // Verify mandate is properly initialized
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        // OpenAction doesn't store data, just verifies it's accessible
        assertTrue(address(openAction) != address(0));
    }

    function testOpenActionWithValidCall() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Execute open action
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test open action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testOpenActionWithMultipleCalls() public {
        // Setup multiple calls
        targets = new address[](3);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);
        targets[2] = address(daoMock);

        values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        calldatas = new bytes[](3);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(daoMock.assignRole.selector, 3, alice);

        // Execute open action
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test multiple calls");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testOpenActionWithEmptyInput() public {
        // Execute with empty input
        vm.prank(alice);

        // Should fail: no targets, values, calldata provided
        vm.expectRevert();
        daoMock.request(mandateId, abi.encode(), nonce, "Test empty input");
    }

    function testOpenActionHandleRequestDirectly() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = openAction.handleRequest(alice, address(daoMock), mandateId, abi.encode(targets, values, calldatas), nonce);

        // Verify the returned values match what we sent
        assertEq(actionId, uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
        assertEq(returnedCalldatas[0], calldatas[0]);
    }
}

//////////////////////////////////////////////////
//          STATEMENT OF INTENT TESTS         //
//////////////////////////////////////////////////
contract StatementOfIntentTest is TestSetupMulti {
    StatementOfIntent statementOfIntent;

    function setUp() public override {
        super.setUp();
        statementOfIntent = StatementOfIntent(mandateAddresses[4]); // StatementOfIntent from multi constitution
        mandateId = 2; // StatementOfIntent mandate ID in multi constitution
    }

    function testStatementOfIntentInitialization() public {
        // Verify mandate is properly initialized
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        // StatementOfIntent doesn't store data, just verifies it's accessible
        assertTrue(address(statementOfIntent) != address(0));
    }

    function testStatementOfIntentWithValidCall() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Execute statement of intent
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test statement of intent");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testStatementOfIntentWithMultipleCalls() public {
        // Setup multiple calls
        targets = new address[](2);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);

        values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");

        // Execute statement of intent
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test multiple statements");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testStatementOfIntentHandleRequestDirectly() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = statementOfIntent.handleRequest(
            alice, address(daoMock), mandateId, abi.encode(targets, values, calldatas), nonce
        );

        // Verify the returned values is empty
        assertEq(actionId, uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(0));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
    }
}

//////////////////////////////////////////////////
//         BESPOKE ACTION SIMPLE TESTS        //
//////////////////////////////////////////////////
contract BespokeActionSimpleTest is TestSetupMulti {
    BespokeActionSimple bespokeActionSimple;
    SimpleErc1155 erc1155Mock;

    function setUp() public override {
        super.setUp();
        bespokeActionSimple = BespokeActionSimple(mandateAddresses[6]); // BespokeActionSimple from multi constitution
        erc1155Mock = SimpleErc1155(mockAddresses[3]); // SimpleErc1155 mock
        mandateId = 3; // BespokeActionSimple mandate ID in multi constitution
    }

    function testBespokeActionSimpleInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertEq(bespokeActionSimple.targetContract(mandateHash), address(erc1155Mock));
        assertEq(bespokeActionSimple.targetFunction(mandateHash), SimpleErc1155.mintCoins.selector);
    }

    function testBespokeActionSimpleWithValidCall() public {
        // Execute with valid parameters
        uint256 quantity = 100;
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(quantity), nonce, "Test bespoke simple");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(quantity), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionSimpleWithZeroQuantity() public {
        // Execute with zero quantity
        uint256 quantity = 0;
        vm.prank(alice);
        vm.expectRevert(SimpleErc1155.SimpleErc1155__NoZeroAmount.selector);
        daoMock.request(mandateId, abi.encode(quantity), nonce, "Test zero quantity");
    }

    function testBespokeActionSimpleWithLargeQuantity() public {
        // Execute with large quantity
        uint256 quantity = 1_000_000;
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(quantity), nonce, "Test large quantity");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(quantity), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//         PRESET SINGLE ACTION TESTS        //
//////////////////////////////////////////////////
contract PresetSingleActionTest is TestSetupMulti {
    PresetSingleAction presetSingleAction;

    function setUp() public override {
        super.setUp();
        presetSingleAction = PresetSingleAction(mandateAddresses[1]); // PresetSingleAction from multi constitution
        mandateId = 5; // PresetSingleAction mandate ID in multi constitution
    }

    function testPresetSingleActionInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PresetSingleAction.Data memory data = presetSingleAction.getData(mandateHash);
        assertEq(data.targets.length, 2);
        assertEq(data.targets[0], address(daoMock));
        assertEq(data.targets[1], address(daoMock));
        assertEq(data.values.length, 2);
        assertEq(data.calldatas.length, 2);
    }

    function testPresetSingleActionExecution() public {
        // Execute preset action (no input needed, just trigger)
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test preset single action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetSingleActionWithInput() public {
        // Execute with input (should be ignored for preset actions)
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode("some input"), nonce, "Test preset with input");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode("some input"), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//        PRESET MULTIPLE ACTIONS TESTS       //
//////////////////////////////////////////////////
contract PresetMultipleActionsTest is TestSetupMulti {
    PresetMultipleActions presetMultipleActions;

    function setUp() public override {
        super.setUp();
        presetMultipleActions = PresetMultipleActions(mandateAddresses[2]); // PresetMultipleActions from multi constitution
        mandateId = 6; // PresetMultipleActions mandate ID in multi constitution
    }

    function testPresetMultipleActionsInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PresetMultipleActions.Data memory data = presetMultipleActions.getData(mandateHash);
        assertEq(data.descriptions.length, 2);
        assertEq(data.targets.length, 2);
        assertEq(data.values.length, 2);
        assertEq(data.calldatas.length, 2);
    }

    function testPresetMultipleActionsWithFirstAction() public {
        // Execute first action only
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = false; // Don't select second action

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selections), nonce, "Test first action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithSecondAction() public {
        // Execute second action only
        bool[] memory selections = new bool[](2);
        selections[0] = false; // Don't select first action
        selections[1] = true; // Select second action

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selections), nonce, "Test second action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithBothActions() public {
        // Execute both actions
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = true; // Select second action

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selections), nonce, "Test both actions");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithNoActions() public {
        // Execute no actions
        bool[] memory selections = new bool[](2);
        selections[0] = false; // Don't select first action
        selections[1] = false; // Don't select second action

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selections), nonce, "Test no actions");

        // Should succeed (no operations)
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsHandleRequestDirectly() public {
        // Execute first action only
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = false; // Don't select second action

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = presetMultipleActions.handleRequest(alice, address(daoMock), mandateId, abi.encode(selections), nonce);

        // Verify the returned values
        assertEq(actionId, uint256(keccak256(abi.encode(mandateId, abi.encode(selections), nonce))));
        assertEq(returnedTargets.length, 1); // Only first action selected
        assertEq(returnedValues.length, 1);
        assertEq(returnedCalldatas.length, 1);
        // Should be the first action's call to labelRole
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues[0], 0);
    }
}

//////////////////////////////////////////////////
//        BESPOKE ACTION ADVANCED TESTS       //
//////////////////////////////////////////////////
contract BespokeActionAdvancedTest is TestSetupMulti {
    BespokeActionAdvanced bespokeActionAdvanced;

    function setUp() public override {
        super.setUp();
        bespokeActionAdvanced = BespokeActionAdvanced(mandateAddresses[5]); // BespokeActionAdvanced from multi constitution
        mandateId = 4; // BespokeActionAdvanced mandate ID in multi constitution
    }

    function testBespokeActionAdvancedInitialization() public {
        // Verify mandate is properly initialized
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        // BespokeActionAdvanced stores data internally, just verify it's accessible
        assertTrue(address(bespokeActionAdvanced) != address(0));
    }

    function testBespokeActionAdvancedWithValidCall() public {
        // Execute with valid account parameter
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(alice); // account to assign role to

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(dynamicParts), nonce, "Test bespoke advanced");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(dynamicParts), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionAdvancedWithDifferentAccount() public {
        // Execute with different account
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(bob); // different account

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(dynamicParts), nonce, "Test different account");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(dynamicParts), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionAdvancedHandleRequestDirectly() public {
        // Setup dynamic parts for the function call
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(alice); // account to assign role to

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = bespokeActionAdvanced.handleRequest(alice, address(daoMock), mandateId, abi.encode(dynamicParts), nonce);

        // Verify the returned values
        assertEq(actionId, uint256(keccak256(abi.encode(mandateId, abi.encode(dynamicParts), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
        // The calldata should be the encoded function call to assignRole
        assertEq(returnedCalldatas[0], abi.encodeWithSelector(daoMock.assignRole.selector, 1, alice));
    }
}

//////////////////////////////////////////////////
//       CHECK EXTERNAL ACTION STATE TESTS    //
//////////////////////////////////////////////////
contract CheckExternalActionStateTest is TestSetupMulti {
    CheckExternalActionState checkExternalActionState;

    function setUp() public override {
        super.setUp();
        checkExternalActionState = CheckExternalActionState(mandateAddresses[31]); // CheckExternalActionState from multi constitution
        mandateId = 8; // CheckExternalActionState mandate ID in multi constitution
    }

    function testCheckExternalActionStateInitialization() public {
        // Verify mandate is properly initialized
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        // CheckExternalActionState stores data
        (address parentPowers, uint16 parentMandateId) = checkExternalActionState.mandateConfig(mandateHash);
        assertEq(parentPowers, address(daoMock));
        assertEq(parentMandateId, 1);
    }

    function testCheckExternalActionStateWithValidFulfilledAction() public {
        // 1. Create an action on the parent contract (which is daoMock itself in this test)
        // We use mandateId 1 (OpenAction) as defined in the config
        uint16 parentMandateId = 1;

        // Setup call data for the parent action
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Execute parent action
        vm.prank(alice);
        daoMock.request(parentMandateId, abi.encode(targets, values, calldatas), nonce, "Parent action");

        // Calculate parent actionId
        uint256 parentActionId =
            uint256(keccak256(abi.encode(parentMandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(parentActionId) == ActionState.Fulfilled);

        // 2. Now call CheckExternalActionState with the same calldata and nonce
        // It should verify that the parent action is fulfilled
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Check external action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testCheckExternalActionStateWithUnfulfilledAction() public {
        // 1. We don't execute the parent action, so it doesn't exist (or isn't fulfilled)

        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Unfulfilled Role");

        // 2. Call CheckExternalActionState
        vm.prank(alice);
        vm.expectRevert("Action not fulfilled");
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Check unfulfilled action");
    }

    function testCheckExternalActionStateHandleRequestDirectly() public {
        // 1. Create parent action
        uint16 parentMandateId = 1;

        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        vm.prank(alice);
        daoMock.request(parentMandateId, abi.encode(targets, values, calldatas), nonce, "Parent action");

        // 2. Call handleRequest directly
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = checkExternalActionState.handleRequest(
            alice, address(daoMock), mandateId, abi.encode(targets, values, calldatas), nonce
        );

        // Verify return values
        assertEq(actionId, uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce))));
        // Should return empty arrays
        assertEq(returnedTargets.length, 1);
        assertEq(returnedValues.length, 1);
        assertEq(returnedCalldatas.length, 1);
    }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS               //
//////////////////////////////////////////////////
contract MultiEdgeCaseTest is TestSetupMulti {
    OpenAction openAction;
    StatementOfIntent statementOfIntent;
    BespokeActionSimple bespokeActionSimple;
    PresetSingleAction presetSingleAction;
    PresetMultipleActions presetMultipleActions;
    BespokeActionAdvanced bespokeActionAdvanced;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(mandateAddresses[3]);
        statementOfIntent = StatementOfIntent(mandateAddresses[4]);
        bespokeActionSimple = BespokeActionSimple(mandateAddresses[6]);
        presetSingleAction = PresetSingleAction(mandateAddresses[1]);
        presetMultipleActions = PresetMultipleActions(mandateAddresses[2]);
        bespokeActionAdvanced = BespokeActionAdvanced(mandateAddresses[5]);
    }

    function testAllMultiMandatesInitialization() public {
        // Test that all multi mandates are properly initialized from constitution
        // OpenAction (mandateId = 1)
        mandateId = 1;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertTrue(address(openAction) != address(0));

        // StatementOfIntent (mandateId = 2)
        mandateId = 2;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertTrue(address(statementOfIntent) != address(0));

        // BespokeActionSimple (mandateId = 3)
        mandateId = 3;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertEq(bespokeActionSimple.targetContract(mandateHash), mockAddresses[3]);

        // BespokeActionAdvanced (mandateId = 4)
        mandateId = 4;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertTrue(address(bespokeActionAdvanced) != address(0));

        // PresetSingleAction (mandateId = 5)
        mandateId = 5;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PresetSingleAction.Data memory data = presetSingleAction.getData(mandateHash);
        assertEq(data.targets.length, 2);

        // PresetMultipleActions (mandateId = 6)
        mandateId = 6;
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PresetMultipleActions.Data memory multiData = presetMultipleActions.getData(mandateHash);
        assertEq(multiData.descriptions.length, 2);
    }

    function testMultiMandatesWithComplexProposals() public {
        // Test with complex multi-action proposals
        mandateId = 1; // OpenAction mandate ID

        // Setup complex proposal parameters
        targets = new address[](3);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);
        targets[2] = address(daoMock);

        values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        calldatas = new bytes[](3);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(daoMock.assignRole.selector, 3, alice);

        // Execute complex proposal
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test complex proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testMultiMandatesWithLargeArrays() public {
        // Test with large arrays
        mandateId = 1; // OpenAction mandate ID

        // Setup large arrays
        targets = new address[](10);
        values = new uint256[](10);
        calldatas = new bytes[](10);

        for (uint256 i = 0; i < 10; i++) {
            targets[i] = address(daoMock);
            values[i] = 0;
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, uint256(i + 1), "Role");
        }

        // Execute with large arrays
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test large arrays");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testMultiMandatesWithZeroAddressTargets() public {
        // Test with zero address targets
        mandateId = 1; // OpenAction mandate ID

        targets = new address[](1);
        targets[0] = address(0); // zero address
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");

        // Execute with zero address target
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test zero address target");

        // Should succeed (but will fail when executed)
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    // function testMultiMandatesWithEtherValues() public {
    //     // Test with ether values
    //     mandateId = 1; // OpenAction mandate ID

    //     targets = new address[](1);
    //     targets[0] = address(daoMock);
    //     values = new uint256[](1);
    //     values[0] = 1 ether; // Send ether
    //     calldatas = new bytes[](1);
    //     calldatas[0] = abi.encodeWithSelector(daoMock.receive.selector);

    //     // Execute with ether value
    //     vm.prank(alice);
    //     daoMock.request(mandateId, abi.encode(targets, values, calldatas), nonce, "Test ether value");

    //     // Should succeed
    //     actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas), nonce)));
    //     assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    // }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS                //
//////////////////////////////////////////////////
contract ExecutiveEdgeCaseTest is TestSetupExecutive {
    OpenAction openAction;
    PresetSingleAction presetSingleAction;
    SimpleGovernor simpleGovernor;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(mandateAddresses[3]);
        presetSingleAction = PresetSingleAction(mandateAddresses[1]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
    }

    function testExecutiveMandatesWithComplexProposals() public {
        // Test with complex multi-action proposals
        mandateId = 2; // GovernorCreateProposal mandate ID

        // Setup complex proposal parameters
        targets = new address[](3);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);
        targets[2] = address(daoMock);

        values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        calldatas = new bytes[](3);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(daoMock.assignRole.selector, 3, alice);

        description = "Complex multi-action proposal for role management";

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas, description), nonce, "Test complex proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testExecutiveMandatesWithInvalidConfigs() public {
        // Test that mandates revert with invalid configurations
        mandateId = 2; // GovernorCreateProposal mandate ID

        // Test with invalid proposal parameters (no targets)
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Invalid proposal";

        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        daoMock.request(mandateId, abi.encode(targets, values, calldatas, description), nonce, "Test invalid config");
    }

    function testExecutiveMandatesWithLongDescriptions() public {
        // Test with very long descriptions
        mandateId = 2; // GovernorCreateProposal mandate ID

        // Setup proposal parameters with long description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Create a very long description
        description = string(abi.encodePacked(new bytes(1000)));

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(targets, values, calldatas, description), nonce, "Test long description");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}
